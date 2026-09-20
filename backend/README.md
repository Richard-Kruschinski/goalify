# Goalify Backend

FastAPI backend for the Goalify app (the Flutter client lives in the repository root).

## Quick start

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate          # Windows;  source .venv/bin/activate on macOS/Linux
pip install -r requirements-dev.txt
copy .env.example .env          # cp on macOS/Linux
uvicorn app.main:app --reload
```

- API: http://127.0.0.1:8000/api/v1
- Swagger UI: http://127.0.0.1:8000/docs
- Health check: http://127.0.0.1:8000/api/v1/health

Outside production the app calls `create_all()` on startup, so a local SQLite file
(`goalify.db`) is created automatically — no migration step needed to get going.

## Tests

```bash
pytest
```

## Migrations (Alembic)

```bash
alembic revision --autogenerate -m "add tasks"
alembic upgrade head
```

`alembic/env.py` reads `DATABASE_URL` from the app settings, so there is no URL to
keep in sync in `alembic.ini`.

## Postgres via Docker

```bash
docker compose up --build
```

## Layout

```
backend/
├── app/
│   ├── main.py             # app factory, middleware, lifespan
│   ├── api/
│   │   ├── deps.py         # DB session, current user, pagination
│   │   └── v1/
│   │       ├── router.py   # collects all v1 routers
│   │       └── routes/     # one module per feature
│   ├── core/               # config, logging, security, exceptions
│   ├── db/                 # declarative base, async session, init_db
│   ├── models/             # SQLAlchemy tables
│   ├── schemas/            # Pydantic request/response models
│   ├── repositories/       # database access only
│   └── services/           # business rules
├── alembic/                # migrations
└── tests/
```

The feature split mirrors the Flutter side (`lib/features/`): `auth`, `tasks`, `gym`,
`progress`, plus `groups` for the shared scoreboard.

Request flow: **route** (validate, authenticate) → **service** (rules) →
**repository** (SQL) → **model**. Routes never touch the session directly beyond
handing it to a service, which keeps business rules testable without HTTP.

## Status

Working today: settings, logging, error handling, async DB layer, JWT auth with
rotating refresh tokens (`/auth/register`, `/auth/login`, `/auth/refresh`,
`/auth/logout`), `/users/me`, `/health`.

Skeletons that return **501 Not Implemented**: `/tasks`, `/gym`, `/progress`,
`/groups`. The models, schemas and routes are in place — each one needs its service.

## Conventions

- Ids are client-generated string UUIDs, matching the ids the app already stores
  locally, so a sync does not have to remap anything.
- Datetimes are timezone-aware UTC; day keys stay `yyyy-mm-dd` strings, as in the app.
- Errors come back as `{"error": {"code": ..., "message": ...}}` (see `app/core/exceptions.py`).
