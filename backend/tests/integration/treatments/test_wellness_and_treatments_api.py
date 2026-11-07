import uuid
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


async def _create_test_user(client: AsyncClient, uid: str) -> None:
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    onboarding_payload = {
        "first_name": "Valentina",
        "last_name": "Ríos",
        "current_life_stage": "regular_adult",
        "birth_year": 1996,
        "primary_intents": ["cycle_and_symptoms", "general_wellness"],
        "hormonal_method": "combined_oral_pill",
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
async def test_wellness_merge_patch_lifecycle(async_client: AsyncClient) -> None:
    uid = "wellness-user-1"
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    await _create_test_user(async_client, uid)

    log_date = "2026-11-07"

    # 1. Morning check-in: Sleep + Mood
    morning_payload = {
        "sleep_hours": 7.5,
        "sleep_quality": 4,
        "energy_level": 4,
        "mood_tags": ["energetic", "calm"],
    }
    res1 = await async_client.put(
        f"/api/v1/wellness/logs/{log_date}",
        headers=headers,
        json=morning_payload,
    )
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["sleep_hours"] == 7.5
    assert data1["sleep_quality"] == 4
    assert data1["hydration_ml"] is None
    assert "energetic" in data1["mood_tags"]

    # 2. Evening update: Hydration + Exercise (merge-patch without erasing morning data)
    evening_payload = {
        "hydration_ml": 2200,
        "exercise_minutes": 45,
        "notes": "Caminata de 45 minutos y buena hidratación",
    }
    res2 = await async_client.put(
        f"/api/v1/wellness/logs/{log_date}",
        headers=headers,
        json=evening_payload,
    )
    assert res2.status_code == 200
    data2 = res2.json()
    # Verified merge: morning sleep retained, evening hydration added
    assert data2["sleep_hours"] == 7.5
    assert data2["sleep_quality"] == 4
    assert data2["hydration_ml"] == 2200
    assert data2["exercise_minutes"] == 45
    assert "energetic" in data2["mood_tags"]
    assert data2["notes"] == "Caminata de 45 minutos y buena hidratación"

    # 3. GET /logs/{log_date}
    res3 = await async_client.get(
        f"/api/v1/wellness/logs/{log_date}",
        headers=headers,
    )
    assert res3.status_code == 200
    assert res3.json()["hydration_ml"] == 2200

    # 4. GET /logs history in range
    res4 = await async_client.get(
        "/api/v1/wellness/logs?start_date=2026-11-01&end_date=2026-11-08",
        headers=headers,
    )
    assert res4.status_code == 200
    logs = res4.json()
    assert len(logs) == 1
    assert logs[0]["log_date"] == log_date


@pytest.mark.asyncio
async def test_treatment_regimen_and_idempotent_intake_lifecycle(
    async_client: AsyncClient,
) -> None:
    uid = "treatment-user-1"
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    await _create_test_user(async_client, uid)

    # 1. Create a 21/7 cyclic oral contraceptive regimen
    regimen_payload = {
        "name": "Microgynon 21",
        "category": "contraceptive_oral_combined",
        "dosage": "1 comprimido",
        "schedule_type": "cyclic_active_break",
        "scheduled_time": "21:00",
        "active_days": 21,
        "break_days": 7,
        "start_date": "2026-11-01",
        "instructions": "1 comprimido diario por 21 días y 7 días de descanso",
    }
    res_regimen = await async_client.post(
        "/api/v1/treatments/regimens",
        headers=headers,
        json=regimen_payload,
    )
    assert res_regimen.status_code == 201
    regimen_data = res_regimen.json()
    regimen_id = regimen_data["id"]
    assert regimen_data["name"] == "Microgynon 21"
    assert regimen_data["schedule_type"] == "cyclic_active_break"

    # 2. Log intake with client_mutation_id (idempotent)
    mutation_id = str(uuid.uuid4())
    intake_payload = {
        "regimen_id": regimen_id,
        "scheduled_for": "2026-11-01T21:00:00Z",
        "taken_at": "2026-11-01T21:10:00Z",
        "status": "taken",
        "client_mutation_id": mutation_id,
    }
    intake_headers = {
        **headers,
        "X-Client-Mutation-Id": mutation_id,
    }

    res_intake1 = await async_client.post(
        "/api/v1/treatments/intakes",
        headers=intake_headers,
        json=intake_payload,
    )
    assert res_intake1.status_code == 201
    intake1 = res_intake1.json()
    assert intake1["status"] == "taken"
    assert intake1["assessment"]["status"] == "taken"
    assert intake1["assessment"]["requires_backup_contraception"] is False

    # 3. Repeat request with same mutation id -> returns cached response
    res_intake_retry = await async_client.post(
        "/api/v1/treatments/intakes",
        headers=intake_headers,
        json=intake_payload,
    )
    assert res_intake_retry.status_code == 201
    assert res_intake_retry.json()["id"] == intake1["id"]

    # 4. Check Adherence Summary
    res_adh = await async_client.get(
        f"/api/v1/treatments/adherence-summary?regimen_id={regimen_id}&start_date=2026-11-01&end_date=2026-11-02",
        headers=headers,
    )
    assert res_adh.status_code == 200
    adh_data = res_adh.json()
    assert adh_data["scheduled_doses"] == 1
    assert adh_data["taken_doses"] == 1
    assert adh_data["adherence_percentage"] == 100.0
