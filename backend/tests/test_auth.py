import pytest
from httpx import AsyncClient

REGISTRATION = {
    "email": "trainer@example.com",
    "password": "correct horse battery",
    "display_name": "Trainer",
}


@pytest.mark.asyncio
async def test_register_login_and_read_me(client: AsyncClient) -> None:
    register = await client.post("/api/v1/auth/register", json=REGISTRATION)
    assert register.status_code == 201

    login = await client.post(
        "/api/v1/auth/login",
        json={"email": REGISTRATION["email"], "password": REGISTRATION["password"]},
    )
    assert login.status_code == 200
    tokens = login.json()

    me = await client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    assert me.status_code == 200
    assert me.json()["email"] == REGISTRATION["email"]


@pytest.mark.asyncio
async def test_login_with_wrong_password_is_rejected(client: AsyncClient) -> None:
    await client.post("/api/v1/auth/register", json=REGISTRATION)

    login = await client.post(
        "/api/v1/auth/login",
        json={"email": REGISTRATION["email"], "password": "nope"},
    )
    assert login.status_code == 401


@pytest.mark.asyncio
async def test_me_requires_a_token(client: AsyncClient) -> None:
    assert (await client.get("/api/v1/users/me")).status_code == 401
