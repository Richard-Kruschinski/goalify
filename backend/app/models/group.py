"""Social groups: shared deadline, points, live scoreboard."""

from datetime import date

from sqlalchemy import Date, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDMixin


class Group(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "groups"

    name: Mapped[str] = mapped_column(String(80))
    description: Mapped[str | None] = mapped_column(String(500), default=None)
    invite_code: Mapped[str] = mapped_column(String(12), unique=True, index=True)
    owner_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    starts_on: Mapped[date | None] = mapped_column(Date, default=None)
    deadline: Mapped[date | None] = mapped_column(Date, default=None)

    members: Mapped[list["GroupMember"]] = relationship(
        back_populates="group", cascade="all, delete-orphan"
    )


class GroupMember(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "group_members"
    __table_args__ = (UniqueConstraint("group_id", "user_id"),)

    group_id: Mapped[str] = mapped_column(
        ForeignKey("groups.id", ondelete="CASCADE"), index=True
    )
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    role: Mapped[str] = mapped_column(String(16), default="member")  # owner | member
    points: Mapped[int] = mapped_column(Integer, default=0)

    group: Mapped[Group] = relationship(back_populates="members")
