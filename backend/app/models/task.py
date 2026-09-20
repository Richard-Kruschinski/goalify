"""Daily tasks — server mirror of lib/features/tasks/data/models/daily_task.dart."""

from sqlalchemy import Boolean, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDMixin


class DailyTask(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "daily_tasks"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str | None] = mapped_column(String(1000), default=None)
    category: Mapped[str | None] = mapped_column(String(64), default=None)
    points: Mapped[int] = mapped_column(Integer, default=1)
    keep: Mapped[bool] = mapped_column(Boolean, default=False)

    # Repeat pattern (keep tasks only)
    repeat_pattern: Mapped[str] = mapped_column(String(16), default="daily")
    custom_days: Mapped[int] = mapped_column(Integer, default=1)
    repeat_start_key: Mapped[str | None] = mapped_column(String(10), default=None)
    weekly_days: Mapped[str | None] = mapped_column(String(20), default=None)  # "1,3,5"

    # Streaks
    streak: Mapped[int] = mapped_column(Integer, default=0)
    best_streak: Mapped[int] = mapped_column(Integer, default=0)
    last_done_key: Mapped[str | None] = mapped_column(String(10), default=None)
    done: Mapped[bool] = mapped_column(Boolean, default=False)

    # Limited tasks ("X times per cycle")
    target_count: Mapped[int | None] = mapped_column(Integer, default=None)
    completed_count: Mapped[int] = mapped_column(Integer, default=0)
    limited_cycle_interval_days: Mapped[int | None] = mapped_column(
        Integer, default=None
    )
    limited_cycle_start_key: Mapped[str | None] = mapped_column(
        String(10), default=None
    )

    checklist: Mapped[list["TaskChecklistItem"]] = relationship(
        back_populates="task", cascade="all, delete-orphan", order_by="TaskChecklistItem.position"
    )


class TaskChecklistItem(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "task_checklist_items"

    task_id: Mapped[str] = mapped_column(
        ForeignKey("daily_tasks.id", ondelete="CASCADE"), index=True
    )
    text: Mapped[str] = mapped_column(String(500))
    done: Mapped[bool] = mapped_column(Boolean, default=False)
    position: Mapped[int] = mapped_column(Integer, default=0)

    task: Mapped[DailyTask] = relationship(back_populates="checklist")
