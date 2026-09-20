"""Schema bootstrap for local development.

Alembic owns the schema in staging/production (`alembic upgrade head`).
create_all() is only a convenience for a fresh local SQLite file.
"""

from app.core.logging import get_logger
from app.db.base import Base
from app.db.session import engine
from app.models import *  # noqa: F401,F403  (import models so metadata is populated)

logger = get_logger(__name__)


async def create_all() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database schema ensured (create_all)")
