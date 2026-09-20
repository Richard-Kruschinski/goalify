"""Progress / activity schemas."""

from datetime import date

from pydantic import BaseModel

from app.schemas.common import ORMModel


class DailyActivityRead(ORMModel):
    day: date
    points: int
    tasks_done: int
    tasks_total: int
    focus_minutes: int


class ActivityPoint(BaseModel):
    """Chart point — matches ActivityPoint in the Flutter app."""

    t: date
    value: int


class ProgressSummary(BaseModel):
    from_day: date
    to_day: date
    total_points: int
    completion_ratio: float
    series: list[ActivityPoint]
