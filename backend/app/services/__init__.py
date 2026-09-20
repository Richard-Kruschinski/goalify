"""Services — business rules. Routes stay thin, services do the work.

Add one module per feature (task_service.py, gym_service.py, group_service.py,
progress_service.py) following the shape of auth_service.py.
"""

from app.services.auth_service import AuthService

__all__ = ["AuthService"]
