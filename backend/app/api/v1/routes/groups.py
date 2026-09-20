"""Groups, invites and the live scoreboard.

Endpoint skeletons — bodies wait for a GroupService.
"""

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentUser, SessionDep
from app.schemas.group import GroupCreate, GroupJoin, GroupRead, Scoreboard

router = APIRouter(prefix="/groups", tags=["groups"])

_NOT_IMPLEMENTED = HTTPException(
    status_code=status.HTTP_501_NOT_IMPLEMENTED, detail="Not implemented yet"
)


@router.get("", response_model=list[GroupRead])
async def list_my_groups(
    current_user: CurrentUser, session: SessionDep
) -> list[GroupRead]:
    raise _NOT_IMPLEMENTED


@router.post("", response_model=GroupRead, status_code=status.HTTP_201_CREATED)
async def create_group(
    payload: GroupCreate, current_user: CurrentUser, session: SessionDep
) -> GroupRead:
    raise _NOT_IMPLEMENTED


@router.post("/join", response_model=GroupRead)
async def join_group(
    payload: GroupJoin, current_user: CurrentUser, session: SessionDep
) -> GroupRead:
    raise _NOT_IMPLEMENTED


@router.get("/{group_id}/scoreboard", response_model=Scoreboard)
async def read_scoreboard(
    group_id: str, current_user: CurrentUser, session: SessionDep
) -> Scoreboard:
    raise _NOT_IMPLEMENTED
