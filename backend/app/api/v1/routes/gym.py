"""Workout splits and logs.

Endpoint skeletons — bodies wait for a GymService. Workout *definitions* stay in
assets/workouts.json on the client; only user data is synced.
"""

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentUser, PaginationDep, SessionDep
from app.schemas.gym import (
    WorkoutLogCreate,
    WorkoutLogRead,
    WorkoutSplitCreate,
    WorkoutSplitRead,
)

router = APIRouter(prefix="/gym", tags=["gym"])

_NOT_IMPLEMENTED = HTTPException(
    status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Not implemented yet"
)


@router.get("/splits", response_model=list[WorkoutSplitRead])
async def list_splits(
    current_user: CurrentUser, session: SessionDep
) -> list[WorkoutSplitRead]:
    raise _NOT_IMPLEMENTED


@router.post(
    "/splits", response_model=WorkoutSplitRead, status_code=status.HTTP_201_CREATED
)
async def create_split(
    payload: WorkoutSplitCreate, current_user: CurrentUser, session: SessionDep
) -> WorkoutSplitRead:
    raise _NOT_IMPLEMENTED


@router.get("/logs", response_model=list[WorkoutLogRead])
async def list_logs(
    current_user: CurrentUser, session: SessionDep, page: PaginationDep
) -> list[WorkoutLogRead]:
    raise _NOT_IMPLEMENTED


@router.post("/logs", response_model=WorkoutLogRead, status_code=status.HTTP_201_CREATED)
async def create_log(
    payload: WorkoutLogCreate, current_user: CurrentUser, session: SessionDep
) -> WorkoutLogRead:
    raise _NOT_IMPLEMENTED
