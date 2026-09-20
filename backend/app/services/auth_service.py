"""Registration, login and token rotation."""

import hashlib
import secrets
from datetime import UTC, datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import AuthError, ConflictError
from app.core.security import create_token, hash_password, verify_password
from app.models.user import RefreshToken, User
from app.repositories.user_repository import RefreshTokenRepository, UserRepository
from app.schemas.auth import LoginRequest, RegisterRequest, TokenPair


def _hash_refresh_token(token: str) -> str:
    """Refresh tokens are stored hashed, so a DB leak cannot replay sessions."""
    return hashlib.sha256(token.encode()).hexdigest()


class AuthService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session
        self.users = UserRepository(session)
        self.tokens = RefreshTokenRepository(session)

    async def register(self, payload: RegisterRequest) -> User:
        if await self.users.get_by_email(payload.email):
            raise ConflictError("Email is already registered")
        user = User(
            email=payload.email.lower(),
            password_hash=hash_password(payload.password),
            display_name=payload.display_name,
            locale=payload.locale,
        )
        await self.users.add(user)
        await self.session.commit()
        return user

    async def login(self, payload: LoginRequest) -> TokenPair:
        user = await self.users.get_by_email(payload.email)
        if not user or not verify_password(payload.password, user.password_hash):
            raise AuthError("Wrong email or password")
        if not user.is_active:
            raise AuthError("Account is disabled")
        return await self._issue_tokens(user, payload.device_label)

    async def refresh(self, refresh_token: str) -> TokenPair:
        stored = await self.tokens.get_active(_hash_refresh_token(refresh_token))
        if stored is None:
            raise AuthError("Refresh token is invalid or expired")
        user = await self.users.get(stored.user_id)
        if user is None or not user.is_active:
            raise AuthError("Account is disabled")
        await self.tokens.revoke(stored)  # single-use: rotate on every refresh
        return await self._issue_tokens(user, stored.device_label)

    async def logout(self, refresh_token: str) -> None:
        stored = await self.tokens.get_active(_hash_refresh_token(refresh_token))
        if stored is not None:
            await self.tokens.revoke(stored)
            await self.session.commit()

    async def _issue_tokens(self, user: User, device_label: str | None) -> TokenPair:
        access_token = create_token(user.id, "access")
        raw_refresh = secrets.token_urlsafe(48)
        await self.tokens.add(
            RefreshToken(
                user_id=user.id,
                token_hash=_hash_refresh_token(raw_refresh),
                device_label=device_label,
                expires_at=datetime.now(UTC)
                + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
            )
        )
        await self.session.commit()
        return TokenPair(
            access_token=access_token,
            refresh_token=raw_refresh,
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )
