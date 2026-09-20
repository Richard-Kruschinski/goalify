"""Minimal logging setup — call configure_logging() once at startup."""

import logging
import sys

from app.core.config import settings

_FORMAT = "%(asctime)s | %(levelname)-8s | %(name)s | %(message)s"


def configure_logging() -> None:
    logging.basicConfig(
        level=settings.LOG_LEVEL.upper(),
        format=_FORMAT,
        stream=sys.stdout,
        force=True,
    )
    # uvicorn brings its own handlers; keep them but align the level.
    for name in ("uvicorn", "uvicorn.error", "uvicorn.access"):
        logging.getLogger(name).setLevel(settings.LOG_LEVEL.upper())


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)
