"""Gym schemas."""

from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


class WorkoutSplitCreate(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    days: list[str] = Field(default_factory=list)
    color: str | None = None


class WorkoutSplitRead(ORMModel):
    id: str
    name: str
    days: str
    color: str | None
    position: int


class WorkoutSetIn(BaseModel):
    weight_kg: float = 0.0
    reps: int = 0
    duration_seconds: int | None = None
    bar_weight_kg: float = 0.0
    weight_includes_bar: bool = False
    dropsets: list["WorkoutSetIn"] = Field(default_factory=list)


class WorkoutSetRead(ORMModel):
    id: str
    position: int
    weight_kg: float
    reps: int
    duration_seconds: int | None
    bar_weight_kg: float
    weight_includes_bar: bool


class WorkoutLogCreate(BaseModel):
    workout_id: str
    split_id: str | None = None
    day: str | None = None
    logged_at: datetime
    sets: list[WorkoutSetIn] = Field(default_factory=list)


class WorkoutLogRead(ORMModel):
    id: str
    workout_id: str
    split_id: str | None
    day: str | None
    logged_at: datetime
    sets: list[WorkoutSetRead] = Field(default_factory=list)
