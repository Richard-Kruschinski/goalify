"""SQLAlchemy models. Import every model here so Alembic sees the full metadata."""

from app.models.group import Group, GroupMember
from app.models.gym import (
    ExerciseWeightSettings,
    WorkoutLog,
    WorkoutSet,
    WorkoutSplit,
)
from app.models.progress import DailyActivity
from app.models.task import DailyTask, TaskChecklistItem
from app.models.user import RefreshToken, User

__all__ = [
    "DailyActivity",
    "DailyTask",
    "ExerciseWeightSettings",
    "Group",
    "GroupMember",
    "RefreshToken",
    "TaskChecklistItem",
    "User",
    "WorkoutLog",
    "WorkoutSet",
    "WorkoutSplit",
]
