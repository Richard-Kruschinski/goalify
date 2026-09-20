"""Daily tasks.

Endpoint skeletons only — the bodies wait for a TaskService, mirroring
lib/features/tasks/domain/usecases/task_rules.dart (streaks, limited cycles,
day rollover). Implement one endpoint at a time; auth and DB wiring are done.
"""

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentUser, PaginationDep, SessionDep
from app.schemas.task import DailyTaskCreate, DailyTaskRead, DailyTaskUpdate

router = APIRouter(prefix="/tasks", tags=["tasks"])

_NOT_IMPLEMENTED = HTTPException(
    status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Not implemented yet"
)


@router.get("", response_model=list[DailyTaskRead])
async def list_tasks(
    current_user: CurrentUser, session: SessionDep, page: PaginationDep
) -> list[DailyTaskRead]:
    raise _NOT_IMPLEMENTED


@router.post("", response_model=DailyTaskRead, status_code=status.HTTP_201_CREATED)
async def create_task(
    payload: DailyTaskCreate, current_user: CurrentUser, session: SessionDep
) -> DailyTaskRead:
    raise _NOT_IMPLEMENTED


@router.patch("/{task_id}", response_model=DailyTaskRead)
async def update_task(
    task_id: str,
    payload: DailyTaskUpdate,
    current_user: CurrentUser,
    session: SessionDep,
) -> DailyTaskRead:
    raise _NOT_IMPLEMENTED


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(
    task_id: str, current_user: CurrentUser, session: SessionDep
) -> None:
    raise _NOT_IMPLEMENTED
