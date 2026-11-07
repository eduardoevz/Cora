from collections.abc import AsyncIterator

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.database import Base, get_async_session
from app.main import create_app


@pytest.fixture
async def async_client() -> AsyncIterator[AsyncClient]:
    test_engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        echo=False,
    )
    async_session_factory = async_sessionmaker(
        test_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )

    # Note: SQLite JSON support for tests
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    app = create_app()

    async def override_get_session() -> AsyncIterator[AsyncSession]:
        async with async_session_factory() as session:
            yield session

    app.dependency_overrides[get_async_session] = override_get_session

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client

    await test_engine.dispose()


async def test_get_me_unauthenticated_returns_401(async_client: AsyncClient) -> None:
    response = await async_client.get("/api/v1/identity/me")
    assert response.status_code == 401
    assert response.headers["content-type"] == "application/problem+json"


async def test_get_me_not_found_returns_404(async_client: AsyncClient) -> None:
    headers = {
        "Authorization": "Bearer test-token:uid-nonexistent:nonexistent@cora.test"
    }
    response = await async_client.get("/api/v1/identity/me", headers=headers)
    assert response.status_code == 404
    assert response.headers["content-type"] == "application/problem+json"
    problem = response.json()
    assert problem["code"] == "entity_not_found"


async def test_complete_onboarding_lifecycle(async_client: AsyncClient) -> None:
    headers = {"Authorization": "Bearer test-token:uid-mariana-1:mariana@cora.test"}

    payload = {
        "first_name": "Mariana",
        "last_name": "Gómez",
        "current_life_stage": "regular_adult",
        "birth_year": 1996,
        "primary_intents": ["cycle_and_symptoms", "general_wellness"],
        "hormonal_method": "none",
        "diagnosed_conditions": ["none"],
        "clinical_context_completed": True,
    }

    create_res = await async_client.put(
        "/api/v1/identity/onboarding",
        headers=headers,
        json=payload,
    )
    assert create_res.status_code == 200
    data = create_res.json()
    assert data["first_name"] == "Mariana"
    assert data["current_life_stage"] == "regular_adult"
    assert "cycle_tracking" in data["enabled_modules"]
    assert data["onboarding_completed"] is True
    assert data["onboarding_context"]["clinical_context_completed"] is True

    # Check GET /me returns the created profile
    me_res = await async_client.get("/api/v1/identity/me", headers=headers)
    assert me_res.status_code == 200
    assert me_res.json()["firebase_uid"] == "uid-mariana-1"


async def test_onboarding_with_invalid_intents_returns_400_rfc7807(
    async_client: AsyncClient,
) -> None:
    headers = {"Authorization": "Bearer test-token:uid-invalid-intents"}
    payload = {
        "first_name": "Valeria",
        "last_name": "Ruiz",
        "current_life_stage": "adolescence",
        "birth_year": 2008,
        "primary_intents": [
            "cycle_and_symptoms",
            "family_planning",
            "pregnancy_tracking",
            "general_wellness",  # 4 intents exceeds max of 3
        ],
    }

    res = await async_client.put(
        "/api/v1/identity/onboarding",
        headers=headers,
        json=payload,
    )
    assert res.status_code == 400
    assert res.headers["content-type"] == "application/problem+json"
    problem = res.json()
    assert problem["code"] == "invalid_onboarding_goals"


async def test_switch_life_stage_lifecycle(async_client: AsyncClient) -> None:
    headers = {"Authorization": "Bearer test-token:uid-paola:paola@cora.test"}

    # Onboarding in conception search
    await async_client.put(
        "/api/v1/identity/onboarding",
        headers=headers,
        json={
            "first_name": "Paola",
            "last_name": "Méndez",
            "current_life_stage": "conception_search",
            "birth_year": 1992,
            "primary_intents": ["family_planning"],
        },
    )

    # Transition to pregnancy
    transition_res = await async_client.post(
        "/api/v1/identity/life-stage/transitions",
        headers=headers,
        json={
            "target_stage": "pregnancy",
            "reason": "conception_confirmed",
            "notes": "Ecografía temprana positiva a las 6 semanas.",
        },
    )
    assert transition_res.status_code == 200
    data = transition_res.json()
    assert data["current_life_stage"] == "pregnancy"
    assert len(data["transition_history"]) == 1
    assert data["transition_history"][0]["from_stage"] == "conception_search"
    assert data["transition_history"][0]["to_stage"] == "pregnancy"
    assert "fetal_development" in data["enabled_modules"]


async def test_update_module_preferences(async_client: AsyncClient) -> None:
    headers = {"Authorization": "Bearer test-token:uid-lucia:lucia@cora.test"}

    await async_client.put(
        "/api/v1/identity/onboarding",
        headers=headers,
        json={
            "first_name": "Lucía",
            "last_name": "Santos",
            "current_life_stage": "regular_adult",
            "birth_year": 1994,
            "primary_intents": ["cycle_and_symptoms"],
        },
    )

    patch_res = await async_client.patch(
        "/api/v1/identity/module-preferences",
        headers=headers,
        json={"enabled_modules": ["cycle_tracking", "symptom_logger"]},
    )
    assert patch_res.status_code == 200
    assert patch_res.json()["enabled_modules"] == ["cycle_tracking", "symptom_logger"]


async def test_tenant_isolation_between_different_users(
    async_client: AsyncClient,
) -> None:
    user_a = {"Authorization": "Bearer test-token:uid-user-a:a@cora.test"}
    user_b = {"Authorization": "Bearer test-token:uid-user-b:b@cora.test"}

    # User A onboards
    await async_client.put(
        "/api/v1/identity/onboarding",
        headers=user_a,
        json={
            "first_name": "UserA",
            "last_name": "Test",
            "current_life_stage": "regular_adult",
            "birth_year": 1995,
            "primary_intents": ["general_wellness"],
        },
    )

    # User B should get 404 for their own profile
    res_b = await async_client.get("/api/v1/identity/me", headers=user_b)
    assert res_b.status_code == 404
