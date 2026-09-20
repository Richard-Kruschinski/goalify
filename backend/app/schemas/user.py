"""User read/update models."""

from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


class UserRead(ORMModel):
    id: str
    email: str
    display_name: str
    avatar_url: str | None = None
    locale: str
    created_at: datetime


class UserUpdate(BaseModel):
    display_name: str | None = Field(default=None, min_length=1, max_length=64)
    avatar_url: str | None = None
    locale: str | None = Field(default=None, max_length=8)
