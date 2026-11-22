from collections.abc import AsyncIterator
from datetime import date, timedelta

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


@pytest.mark.asyncio
async def test_onboarding_seeds_two_initial_periods_and_calibrates_calendar(
    async_client: AsyncClient,
) -> None:
    uid = "cal-onboarding-user"
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}

    today = date.today()
    p2_start = today - timedelta(days=8)
    p2_end = p2_start + timedelta(days=4)
    p1_start = p2_start - timedelta(days=31)
    p1_end = p1_start + timedelta(days=4)

    onboarding_payload = {
        "first_name": "Elena",
        "last_name": "Vargas",
        "current_life_stage": "regular_adult",
        "birth_year": 1995,
        "primary_intents": ["cycle_and_symptoms"],
        "hormonal_method": "none",
        "diagnosed_conditions": ["none"],
        "clinical_context_completed": True,
        "cycle_regularity": "regular",
        "initial_periods": [
            {
                "start_date": p1_start.isoformat(),
                "end_date": p1_end.isoformat(),
            },
            {
                "start_date": p2_start.isoformat(),
                "end_date": p2_end.isoformat(),
            },
        ],
    }
    ob_resp = await async_client.put(
        "/api/v1/identity/onboarding",
        headers=headers,
        json=onboarding_payload,
    )
    assert ob_resp.status_code == 200
    profile_data = ob_resp.json()
    assert profile_data["onboarding_context"]["cycle_regularity"] == "regular"
    assert profile_data["onboarding_context"]["typical_cycle_length_days"] == 31
    assert profile_data["onboarding_context"]["typical_bleeding_duration_days"] == 5

    history_resp = await async_client.get("/api/v1/cycles/history", headers=headers)
    assert history_resp.status_code == 200
    history = history_resp.json()
    assert len(history) == 2

    predicted_next_start = p2_start + timedelta(days=31)
    cal_resp = await async_client.get(
        "/api/v1/cycles/calendar",
        headers=headers,
        params={
            "year": predicted_next_start.year,
            "month": predicted_next_start.month,
            "reference_date": today.isoformat(),
        },
    )
    assert cal_resp.status_code == 200
    cal_data = cal_resp.json()
    assert cal_data["display_mode"] == "standard_cycle"
    assert cal_data["estimated_cycle_length_days"] == 31
    assert cal_data["predicted_next_period"] == predicted_next_start.isoformat()

    day_map = {day["date"]: day for day in cal_data["days"]}
    assert day_map[predicted_next_start.isoformat()]["day_marker"] == "predicted_period"

    p2_cal_resp = await async_client.get(
        "/api/v1/cycles/calendar",
        headers=headers,
        params={
            "year": p2_start.year,
            "month": p2_start.month,
            "reference_date": today.isoformat(),
        },
    )
    assert p2_cal_resp.status_code == 200
    p2_days = {day["date"]: day for day in p2_cal_resp.json()["days"]}
    assert p2_days[p2_start.isoformat()]["day_marker"] == "recorded_period"
    assert p2_days[p2_start.isoformat()]["has_logged_symptoms"] is True

    expected_ovulation = p2_start + timedelta(days=16)
    ovul_cal_resp = await async_client.get(
        "/api/v1/cycles/calendar",
        headers=headers,
        params={
            "year": expected_ovulation.year,
            "month": expected_ovulation.month,
            "reference_date": today.isoformat(),
        },
    )
    assert ovul_cal_resp.status_code == 200
    ovul_days = {day["date"]: day for day in ovul_cal_resp.json()["days"]}
    assert (
        ovul_days[expected_ovulation.isoformat()]["day_marker"] == "predicted_ovulation"
    )


@pytest.mark.asyncio
async def test_seed_initial_periods_endpoint_validation_and_recalibration(
    async_client: AsyncClient,
) -> None:
    uid = "seed-validation-user"
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}

    ob_resp = await async_client.put(
        "/api/v1/identity/onboarding",
        headers=headers,
        json={
            "first_name": "Lucía",
            "last_name": "Ramos",
            "current_life_stage": "regular_adult",
            "birth_year": 1998,
            "primary_intents": ["cycle_and_symptoms"],
            "clinical_context_completed": False,
        },
    )
    assert ob_resp.status_code == 200

    today = date.today()
    overlap_resp = await async_client.post(
        "/api/v1/cycles/initial-periods",
        headers=headers,
        json={
            "periods": [
                {
                    "start_date": (today - timedelta(days=20)).isoformat(),
                    "end_date": (today - timedelta(days=10)).isoformat(),
                },
                {
                    "start_date": (today - timedelta(days=12)).isoformat(),
                    "end_date": (today - timedelta(days=8)).isoformat(),
                },
            ]
        },
    )
    assert overlap_resp.status_code == 400

    future_resp = await async_client.post(
        "/api/v1/cycles/initial-periods",
        headers=headers,
        json={
            "periods": [
                {
                    "start_date": (today + timedelta(days=2)).isoformat(),
                    "end_date": (today + timedelta(days=5)).isoformat(),
                }
            ]
        },
    )
    assert future_resp.status_code == 400

    p2_start = today - timedelta(days=6)
    p1_start = p2_start - timedelta(days=26)
    valid_resp = await async_client.post(
        "/api/v1/cycles/initial-periods",
        headers=headers,
        json={
            "periods": [
                {
                    "start_date": p1_start.isoformat(),
                    "end_date": (p1_start + timedelta(days=3)).isoformat(),
                },
                {
                    "start_date": p2_start.isoformat(),
                    "end_date": (p2_start + timedelta(days=3)).isoformat(),
                },
            ],
            "cycle_regularity": "regular",
        },
    )
    assert valid_resp.status_code == 201
    seeded = valid_resp.json()
    assert len(seeded) == 2
    assert seeded[0]["cycle_length_days"] == 26
    assert seeded[1]["is_current"] is True

    me_resp = await async_client.get("/api/v1/identity/me", headers=headers)
    assert me_resp.status_code == 200
    assert me_resp.json()["onboarding_context"]["typical_cycle_length_days"] == 26


@pytest.mark.asyncio
async def test_non_menstrual_stages_adapt_calendar_and_set_not_applicable(
    async_client: AsyncClient,
) -> None:
    today = date.today()
    for uid, stage, expected_mode in [
        ("preg-cal-user", "pregnancy", "pregnancy_gestational"),
        ("senior-cal-user", "senior_vitality", "senior_preventive"),
    ]:
        headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
        ob_resp = await async_client.put(
            "/api/v1/identity/onboarding",
            headers=headers,
            json={
                "first_name": "Carmen",
                "last_name": "Navarro",
                "current_life_stage": stage,
                "birth_year": 1990 if stage == "pregnancy" else 1962,
                "primary_intents": [
                    "pregnancy_tracking"
                    if stage == "pregnancy"
                    else "hormonal_and_climacteric"
                ],
                "clinical_context_completed": True,
            },
        )
        assert ob_resp.status_code == 200
        assert (
            ob_resp.json()["onboarding_context"]["cycle_regularity"] == "not_applicable"
        )

        cal_resp = await async_client.get(
            "/api/v1/cycles/calendar",
            headers=headers,
            params={
                "year": today.year,
                "month": today.month,
                "reference_date": today.isoformat(),
            },
        )
        assert cal_resp.status_code == 200
        cal_data = cal_resp.json()
        assert cal_data["display_mode"] == expected_mode
        assert cal_data["ovulation_date"] is None
        assert all(
            day["day_marker"] != "predicted_ovulation" for day in cal_data["days"]
        )
