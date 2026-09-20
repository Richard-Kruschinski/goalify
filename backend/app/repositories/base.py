"""Generic async CRUD repository.

Domain repositories subclass this and add their own queries; routes and services
never build SQL themselves.
"""

from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import Base


class BaseRepository[ModelT: Base]:
    model: type[ModelT]

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get(self, obj_id: str) -> ModelT | None:
        return await self.session.get(self.model, obj_id)

    async def list(
        self, *, limit: int = 100, offset: int = 0, **filters: Any
    ) -> list[ModelT]:
        stmt = select(self.model).filter_by(**filters).limit(limit).offset(offset)
        result = await self.session.execute(stmt)
        return list(result.scalars())

    async def count(self, **filters: Any) -> int:
        stmt = select(func.count()).select_from(self.model).filter_by(**filters)
        return int((await self.session.execute(stmt)).scalar_one())

    async def add(self, obj: ModelT) -> ModelT:
        self.session.add(obj)
        await self.session.flush()
        return obj

    async def delete(self, obj: ModelT) -> None:
        await self.session.delete(obj)
        await self.session.flush()
