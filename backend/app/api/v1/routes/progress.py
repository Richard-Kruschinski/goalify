"""Activity series and weekly review.

Endpoint skeletons — bodies wait for a ProgressService.
"""

from datetime import date

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentUser, SessionDep
from app.schemas.progress import DailyActivityRead, ProgressSummary

router = APIRouter(prefix="/progress", tags=["progress"])

_NOT_IMPLEMENTED = HTTPException(
    status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Not implemented yet"
)


@router.get("/summary", response_model=ProgressSummary)
async def read_summary(
    current_user: CurrentUser,
    session: SessionDep,
    from_day: date | None = None,
    to_day: date | None = None,
) -> ProgressSummary:
    raise _NOT_IMPLEMENTED


@router.get("/days", response_model=list[DailyActivityRead])
async def list_days(
    current_user: CurrentUser, session: SessionDep
) -> list[DailyActivityRead]:
    raise _NOT_IMPLEMENTED
