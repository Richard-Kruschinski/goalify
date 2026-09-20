"""Daily task schemas."""

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


class ChecklistItemRead(ORMModel):
    id: str
    text: str
    done: bool
    position: int


class DailyTaskBase(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str | None = None
    category: str | None = None
    points: int = 1
    keep: bool = False
    repeat_pattern: str = "daily"
    custom_days: int = 1
    weekly_days: list[int] = Field(default_factory=list)
    target_count: int | None = None
    limited_cycle_interval_days: int | None = None


class DailyTaskCreate(DailyTaskBase):
    pass


class DailyTaskUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    category: str | None = None
    points: int | None = None
    done: bool | None = None


class DailyTaskRead(ORMModel):
    id: str
    title: str
    description: str | None
    category: str | None
    points: int
    keep: bool
    done: bool
    streak: int
    best_streak: int
    checklist: list[ChecklistItemRead] = Field(default_factory=list)
