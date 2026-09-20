"""Liveness / readiness — used by the Flutter client and by deployment checks."""

from fastapi import APIRouter
from sqlalchemy import text

from app import __version__
from app.api.deps import SessionDep
from app.core.config import settings
from app.schemas.common import HealthStatus

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthStatus)
async def health(session: SessionDep) -> HealthStatus:
    try:
        await session.execute(text("SELECT 1"))
        database = "up"
    except Exception:  # noqa: BLE001 - report degraded instead of failing the probe
        database = "down"

    return HealthStatus(
        status="ok" if database == "up" else "degraded",
        version=__version__,
        environment=settings.ENVIRONMENT,
        database=database,
    )
