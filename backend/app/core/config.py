"""Application settings, loaded from environment variables / .env."""

from functools import lru_cache
from typing import Literal

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # --- General ---
    PROJECT_NAME: str = "Goalify API"
    ENVIRONMENT: Literal["local", "staging", "production"] = "local"
    API_V1_PREFIX: str = "/api/v1"
    DEBUG: bool = True
    LOG_LEVEL: str = "INFO"

    # --- Security ---
    # openssl rand -hex 32 — the dev default is rejected when ENVIRONMENT=production
    SECRET_KEY: str = "dev-only-secret-change-me-before-any-real-deployment"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 60
    JWT_ALGORITHM: str = "HS256"

    # --- Database ---
    # Local default: SQLite (no extra service needed).
    # Production: postgresql+asyncpg://user:pass@host:5432/goalify
    DATABASE_URL: str = "sqlite+aiosqlite:///./goalify.db"
    DB_ECHO: bool = False

    # --- CORS (Flutter web / local tooling) ---
    CORS_ORIGINS: list[str] = Field(default_factory=lambda: ["http://localhost:3000"])

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def _split_origins(cls, value: object) -> object:
        if isinstance(value, str):
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value

    @model_validator(mode="after")
    def _guard_production_secrets(self) -> "Settings":
        if self.ENVIRONMENT == "production" and self.SECRET_KEY.startswith("dev-only"):
            raise ValueError("SECRET_KEY must be set to a real secret in production")
        return self

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT == "production"


@lru_cache
def get_settings() -> Settings:
    """Cached accessor so settings are parsed once per process."""
    return Settings()


settings = get_settings()
