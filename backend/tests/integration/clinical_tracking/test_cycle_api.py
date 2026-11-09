from collections.abc import AsyncIterator

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

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


async def _create_test_user(
    client: AsyncClient, uid: str, life_stage: str = "regular_adult"
) -> None:
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    onboarding_payload = {
        "first_name": "Sofía",
        "last_name": "Mendoza",
        "current_life_stage": life_stage,
        "birth_year": 2000,
        "primary_intents": ["cycle_and_symptoms"],
        "hormonal_method": "none",
        "diagnosed_conditions": ["none"],
        "clinical_context_completed": True,
    }
    resp = await client.put(
        "/api/v1/identity/onboarding",
        headers=headers,
        json=onboarding_payload,
    )
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_log_bleeding_creates_cycle_and_returns_overview(
    async_client: AsyncClient,
) -> None:
    uid = "cycle-user-1"
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    await _create_test_user(async_client, uid)

    # 1. Log Day 1 of bleeding: Starts active cycle
    log_day_1 = {
        "log_date": "2026-11-01",
        "bleeding_flow": "medium",
        "pelvic_pain": 3,
        "dysmenorrhea": 4,
    }
    resp1 = await async_client.post(
        "/api/v1/cycles/symptoms",
        headers=headers,
        json=log_day_1,
    )
    assert resp1.status_code == 201
    symptom_data = resp1.json()
    assert symptom_data["bleeding_flow"] == "medium"
    assert symptom_data["cycle_id"] is not None

    # 2. Get cycle overview on Day 3 (Menstrual phase)
    overview_resp = await async_client.get(
        "/api/v1/cycles/overview?reference_date=2026-11-03",
        headers=headers,
    )
    assert overview_resp.status_code == 200
    overview = overview_resp.json()
    assert overview["current_cycle"] is not None
    assert overview["current_cycle"]["start_date"] == "2026-11-01"
    assert overview["status"]["current_phase"] == "menstrual"
    assert overview["status"]["day_in_cycle"] == 3
    assert overview["status"]["predicted_next_period"] == "2026-11-29"

    # 3. Log symptom on Day 14 without bleeding (Ovulatory phase)
    log_day_14 = {
        "log_date": "2026-11-14",
        "bleeding_flow": "none",
        "fatigue_level": 1,
    }
    resp2 = await async_client.post(
        "/api/v1/cycles/symptoms",
        headers=headers,
        json=log_day_14,
    )
    assert resp2.status_code == 201

    # Overview on Day 14
    overview_resp2 = await async_client.get(
        "/api/v1/cycles/overview?reference_date=2026-11-14",
        headers=headers,
    )
    assert overview_resp2.status_code == 200
    overview2 = overview_resp2.json()
    assert overview2["status"]["current_phase"] == "ovulatory"
    assert overview2["status"]["day_in_cycle"] == 14


@pytest.mark.asyncio
async def test_cycle_history_endpoint(
    async_client: AsyncClient,
) -> None:
    uid = "cycle-user-history"
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    await _create_test_user(async_client, uid)

    # Log cycle 1 start
    await async_client.post(
        "/api/v1/cycles/symptoms",
        headers=headers,
        json={"log_date": "2026-09-01", "bleeding_flow": "medium"},
    )
    # Log cycle 2 start (28 days later -> closes cycle 1)
    await async_client.post(
        "/api/v1/cycles/symptoms",
        headers=headers,
        json={"log_date": "2026-09-29", "bleeding_flow": "heavy"},
    )

    history_resp = await async_client.get(
        "/api/v1/cycles/history",
        headers=headers,
    )
    assert history_resp.status_code == 200
    history = history_resp.json()
    assert len(history) == 2
    # First cycle should be closed
    closed_cycle = next(c for c in history if c["start_date"] == "2026-09-01")
    assert closed_cycle["is_current"] is False
    assert closed_cycle["cycle_length_days"] == 28


@pytest.mark.asyncio
async def test_overview_includes_figo_alerts_for_severe_pain(
    async_client: AsyncClient,
) -> None:
    uid = "cycle-user-endo"
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    await _create_test_user(async_client, uid)

    # Cycle 1: Day 1 bleeding with pain 8
    await async_client.post(
        "/api/v1/cycles/symptoms",
        headers=headers,
        json={
            "log_date": "2026-08-01",
            "bleeding_flow": "heavy",
            "pelvic_pain": 8,
            "dysmenorrhea": 8,
        },
    )
    # Cycle 2: Day 1 bleeding 28 days later with pain 9
    await async_client.post(
        "/api/v1/cycles/symptoms",
        headers=headers,
        json={
            "log_date": "2026-08-29",
            "bleeding_flow": "medium",
            "pelvic_pain": 9,
            "dysmenorrhea": 9,
        },
    )

    overview_resp = await async_client.get(
        "/api/v1/cycles/overview?reference_date=2026-08-30",
        headers=headers,
    )
    assert overview_resp.status_code == 200
    overview = overview_resp.json()
    assert len(overview["alerts"]) > 0
    endo_alert = next(
        (
            a
            for a in overview["alerts"]
            if a["alert_type"] == "severe_pelvic_pain_endometriosis_risk"
        ),
        None,
    )
    assert endo_alert is not None
    assert endo_alert["severity"] == "clinical_recommendation"
