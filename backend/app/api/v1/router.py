"""Collects every v1 route module into one router."""

from fastapi import APIRouter

from app.api.v1.routes import auth, groups, gym, health, progress, tasks, users

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(tasks.router)
api_router.include_router(gym.router)
api_router.include_router(progress.router)
api_router.include_router(groups.router)
