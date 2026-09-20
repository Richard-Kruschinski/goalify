"""Shared schema building blocks."""

from pydantic import BaseModel, ConfigDict


class ORMModel(BaseModel):
    """Read models: populated straight from SQLAlchemy instances."""

    model_config = ConfigDict(from_attributes=True)


class Page[T](BaseModel):
    items: list[T]
    total: int
    limit: int
    offset: int


class Message(BaseModel):
    message: str


class HealthStatus(BaseModel):
    status: str
    version: str
    environment: str
    database: str
