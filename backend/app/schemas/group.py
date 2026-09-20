"""Group and scoreboard schemas."""

from datetime import date

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


class GroupCreate(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    description: str | None = None
    starts_on: date | None = None
    deadline: date | None = None


class GroupJoin(BaseModel):
    invite_code: str = Field(min_length=4, max_length=12)


class GroupMemberRead(ORMModel):
    user_id: str
    role: str
    points: int


class GroupRead(ORMModel):
    id: str
    name: str
    description: str | None
    invite_code: str
    owner_id: str
    starts_on: date | None
    deadline: date | None


class ScoreboardEntry(BaseModel):
    user_id: str
    display_name: str
    avatar_url: str | None = None
    points: int
    rank: int


class Scoreboard(BaseModel):
    group_id: str
    entries: list[ScoreboardEntry]
