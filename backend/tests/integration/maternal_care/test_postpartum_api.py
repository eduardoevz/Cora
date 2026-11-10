from collections.abc import AsyncIterator
from datetime import UTC, datetime, timedelta

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


async def _create_test_user(client: AsyncClient, uid: str) -> dict[str, str]:
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    onboarding_payload = {
        "first_name": "Lucía",
        "last_name": "Martínez",
        "current_life_stage": "postpartum",
        "birth_year": 1994,
        "primary_intents": ["general_wellness"],
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
    return headers


@pytest.mark.asyncio
async def test_postpartum_recovery_logs_and_alerts(
    async_client: AsyncClient,
) -> None:
    headers = await _create_test_user(async_client, "usr_postpartum_01")

    # 1. Register log with foul odor and fever (suspected endometritis)
    log_payload = {
        "days_postpartum": 5,
        "lochia_stage": "serosa",
        "lochia_flow": "light",
        "foul_odor": True,
        "maternal_temperature_c": 38.3,
        "perineal_wound_status": "mild_pain",
        "cesarean_wound_status": None,
        "pelvic_floor_symptoms": ["normal"],
        "notes": "Dolor pélvico y sensación febril.",
    }

    create_resp = await async_client.post(
        "/api/v1/postpartum/recovery-logs",
        headers=headers,
        json=log_payload,
    )
    assert create_resp.status_code == 201
    log_data = create_resp.json()
    assert log_data["days_postpartum"] == 5
    assert log_data["foul_odor"] is True
    assert len(log_data["alerts"]) >= 1
    assert any(
        a["severity"] == "urgent_emergency" and "endometritis" in a["title"].lower()
        for a in log_data["alerts"]
    )

    # 2. Query recent recovery logs
    recent_resp = await async_client.get(
        "/api/v1/postpartum/recovery-logs/recent",
        headers=headers,
    )
    assert recent_resp.status_code == 200
    assert len(recent_resp.json()) == 1


@pytest.mark.asyncio
async def test_lactation_sessions_and_milk_stash_fifo(
    async_client: AsyncClient,
) -> None:
    headers = await _create_test_user(async_client, "usr_postpartum_02")

    # 1. Log lactation session
    now = datetime.now(UTC)
    lactation_payload = {
        "started_at": (now - timedelta(minutes=25)).isoformat(),
        "ended_at": now.isoformat(),
        "left_duration_seconds": 600,
        "right_duration_seconds": 900,
        "last_offered_breast": "right",
        "bottle_volume_ml": None,
        "feeding_type": "breast_only",
        "notes": "Toma nocturna tranquila",
    }

    lact_resp = await async_client.post(
        "/api/v1/postpartum/lactation-sessions",
        headers=headers,
        json=lactation_payload,
    )
    assert lact_resp.status_code == 201
    lact_data = lact_resp.json()
    assert lact_data["total_duration_seconds"] == 1500
    assert lact_data["suggested_next_breast"] == "left"

    # 2. Add milk stash entries (two batches)
    stash1_payload = {
        "pumped_at": (now - timedelta(hours=2)).isoformat(),
        "volume_ml": 100.0,
        "storage_location": "refrigerator",
        "notes": "Lote mañana",
    }
    stash1_resp = await async_client.post(
        "/api/v1/postpartum/milk-stash",
        headers=headers,
        json=stash1_payload,
    )
    assert stash1_resp.status_code == 201
    stash1_id = stash1_resp.json()["id"]

    stash2_payload = {
        "pumped_at": now.isoformat(),
        "volume_ml": 150.0,
        "storage_location": "freezer",
        "notes": "Lote mediodía",
    }
    stash2_resp = await async_client.post(
        "/api/v1/postpartum/milk-stash",
        headers=headers,
        json=stash2_payload,
    )
    assert stash2_resp.status_code == 201

    # 3. Query active milk stash (FIFO by expiration)
    stash_list_resp = await async_client.get(
        "/api/v1/postpartum/milk-stash",
        headers=headers,
    )
    assert stash_list_resp.status_code == 200
    stash_list = stash_list_resp.json()
    assert len(stash_list) == 2
    # Fridge expires in 4 days, freezer in 6 months; fridge must come first
    assert stash_list[0]["storage_location"] == "refrigerator"
    assert stash_list[1]["storage_location"] == "freezer"

    # 4. Consume stash1
    consume_resp = await async_client.patch(
        f"/api/v1/postpartum/milk-stash/{stash1_id}/consume",
        headers=headers,
    )
    assert consume_resp.status_code == 200
    assert consume_resp.json()["is_consumed"] is True

    # Check active stash now only has stash2
    active_resp = await async_client.get(
        "/api/v1/postpartum/milk-stash",
        headers=headers,
    )
    assert len(active_resp.json()) == 1
    assert active_resp.json()[0]["id"] == stash2_resp.json()["id"]


@pytest.mark.asyncio
async def test_epds_screening_api(
    async_client: AsyncClient,
) -> None:
    headers = await _create_test_user(async_client, "usr_postpartum_03")

    # 1. Submit EPDS with positive item 10 -> immediate crisis support
    crisis_payload = {
        "days_postpartum": 14,
        "responses": {
            "item_1": 1,
            "item_2": 0,
            "item_3": 3,
            "item_4": 0,
            "item_5": 3,
            "item_6": 3,
            "item_7": 3,
            "item_8": 3,
            "item_9": 3,
            "item_10": 2,  # 1 point (self harm thought)
        },
    }

    screen_resp = await async_client.post(
        "/api/v1/postpartum/epds-screenings",
        headers=headers,
        json=crisis_payload,
    )
    assert screen_resp.status_code == 201
    data = screen_resp.json()
    assert data["self_harm_risk"] is True
    assert data["severity"] == "immediate_crisis_support"
    assert data["item_10_score"] == 1

    # 2. Get latest screening
    latest_resp = await async_client.get(
        "/api/v1/postpartum/epds-screenings/latest",
        headers=headers,
    )
    assert latest_resp.status_code == 200
    latest_data = latest_resp.json()
    assert latest_data is not None
    assert latest_data["severity"] == "immediate_crisis_support"
