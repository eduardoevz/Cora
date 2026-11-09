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
    client: AsyncClient, uid: str, birth_year: int = 1995
) -> None:
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    onboarding_payload = {
        "first_name": "Valentina",
        "last_name": "Ríos",
        "current_life_stage": "conception_search",
        "birth_year": birth_year,
        "primary_intents": ["family_planning"],
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
async def test_fertility_logging_and_chart_with_three_over_six_shift(
    async_client: AsyncClient,
) -> None:
    uid = "fertility-user-1"
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    await _create_test_user(async_client, uid)

    # 1. Start a cycle on Nov 1, 2026 via cycle bleeding log
    bleeding_resp = await async_client.post(
        "/api/v1/cycles/symptoms",
        headers=headers,
        json={"log_date": "2026-11-01", "bleeding_flow": "medium"},
    )
    assert bleeding_resp.status_code == 201

    # 2. Ingest 6 baseline low temperatures (D7 to D12)
    baseline_temps = [
        ("2026-11-07", 36.25, "dry", "negative"),
        ("2026-11-08", 36.30, "sticky", "negative"),
        ("2026-11-09", 36.20, "creamy", "negative"),
        ("2026-11-10", 36.35, "creamy", "negative"),
        ("2026-11-11", 36.25, "watery", "high"),
        ("2026-11-12", 36.30, "egg_white", "peak"),
    ]
    for log_date, temp, mucus, lh in baseline_temps:
        log_resp = await async_client.put(
            f"/api/v1/fertility/logs/{log_date}",
            headers=headers,
            json={
                "bbt_celsius": temp,
                "measured_at_time": "06:45:00",
                "cervical_mucus": mucus,
                "lh_result": lh,
                "intercourse_had": (mucus == "egg_white"),
                "intercourse_type": ("unprotected" if mucus == "egg_white" else "none"),
            },
        )
        assert log_resp.status_code == 200

    # 3. Ingest 3 elevated temperatures (D13 to D15)
    shift_temps = [
        ("2026-11-13", 36.45, "sticky", "negative"),
        ("2026-11-14", 36.50, "sticky", "negative"),
        ("2026-11-15", 36.60, "dry", "negative"),
    ]
    for log_date, temp, mucus, lh in shift_temps:
        log_resp = await async_client.put(
            f"/api/v1/fertility/logs/{log_date}",
            headers=headers,
            json={
                "bbt_celsius": temp,
                "measured_at_time": "06:45:00",
                "cervical_mucus": mucus,
                "lh_result": lh,
            },
        )
        assert log_resp.status_code == 200

    # 4. Fetch cycle chart
    chart_resp = await async_client.get(
        "/api/v1/fertility/chart?reference_date=2026-11-15",
        headers=headers,
    )
    assert chart_resp.status_code == 200
    chart_data = chart_resp.json()

    assert chart_data["is_biphasic_shift_detected"] is True
    assert chart_data["status"] == "ovulation_confirmed"
    assert str(chart_data["coverline_celsius"]) == "36.35"
    assert chart_data["ovulation_confirmed_date"] == "2026-11-12"
    assert len(chart_data["daily_entries"]) >= 9


@pytest.mark.asyncio
async def test_preconception_checklist_get_and_patch(
    async_client: AsyncClient,
) -> None:
    uid = "fertility-user-checklist"
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    await _create_test_user(async_client, uid)

    # Initial get -> default empty checklist
    get_resp = await async_client.get(
        "/api/v1/fertility/preconception-checklist",
        headers=headers,
    )
    assert get_resp.status_code == 200
    initial_data = get_resp.json()
    assert initial_data["completion_percentage"] == 0
    assert initial_data["taking_folic_acid"] is False

    # Patch checklist
    patch_resp = await async_client.patch(
        "/api/v1/fertility/preconception-checklist",
        headers=headers,
        json={
            "taking_folic_acid": True,
            "folic_acid_dose_mcg": 400,
            "medical_checkup_done": True,
            "toxic_habits_stopped": True,
            "active_seeking_months": 7,
        },
    )
    assert patch_resp.status_code == 200
    updated_data = patch_resp.json()
    assert updated_data["taking_folic_acid"] is True
    assert updated_data["is_folic_acid_adequate"] is True
    assert updated_data["active_seeking_months"] == 7
    # 3 of 6 = 50%
    assert updated_data["completion_percentage"] == 50
