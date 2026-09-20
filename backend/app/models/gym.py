"""Gym splits and workout logs — mirrors lib/features/gym/data/models/gym_models.dart.

Workout *definitions* stay bundled with the app (assets/workouts.json); only the
user's own splits and logged sets need to live on the server.
"""

from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDMixin


class WorkoutSplit(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "workout_splits"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(80))
    days: Mapped[str] = mapped_column(String(500), default="")  # ordered day names
    color: Mapped[str | None] = mapped_column(String(9), default=None)  # #RRGGBBAA
    position: Mapped[int] = mapped_column(Integer, default=0)


class WorkoutLog(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "workout_logs"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    workout_id: Mapped[str] = mapped_column(String(64), index=True)  # id from assets
    split_id: Mapped[str | None] = mapped_column(
        ForeignKey("workout_splits.id", ondelete="SET NULL"), default=None
    )
    day: Mapped[str | None] = mapped_column(String(40), default=None)
    logged_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)

    sets: Mapped[list["WorkoutSet"]] = relationship(
        back_populates="log", cascade="all, delete-orphan", order_by="WorkoutSet.position"
    )


class WorkoutSet(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "workout_sets"

    log_id: Mapped[str] = mapped_column(
        ForeignKey("workout_logs.id", ondelete="CASCADE"), index=True
    )
    # Dropsets hang off their parent set.
    parent_set_id: Mapped[str | None] = mapped_column(
        ForeignKey("workout_sets.id", ondelete="CASCADE"), default=None
    )
    position: Mapped[int] = mapped_column(Integer, default=0)
    weight_kg: Mapped[float] = mapped_column(Float, default=0.0)
    reps: Mapped[int] = mapped_column(Integer, default=0)
    duration_seconds: Mapped[int | None] = mapped_column(Integer, default=None)
    bar_weight_kg: Mapped[float] = mapped_column(Float, default=0.0)
    weight_includes_bar: Mapped[bool] = mapped_column(Boolean, default=False)

    log: Mapped[WorkoutLog] = relationship(back_populates="sets")


class ExerciseWeightSettings(UUIDMixin, TimestampMixin, Base):
    """Per-user, per-exercise bar handling."""

    __tablename__ = "exercise_weight_settings"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    workout_id: Mapped[str] = mapped_column(String(64), index=True)
    bar_weight_kg: Mapped[float] = mapped_column(Float, default=0.0)
    tracked_includes_bar: Mapped[bool] = mapped_column(Boolean, default=False)
