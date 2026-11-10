"""Integration tests for mature health REST APIs (Perimenopause and Senior Vitality)."""

from collections.abc import AsyncIterator
from datetime import UTC, date, datetime

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
        "first_name": "Elena",
        "last_name": "García",
        "current_life_stage": "perimenopause",
        "birth_year": 1974,
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
    assert resp.status_code == 200, resp.text
    return headers


@pytest.mark.asyncio
async def test_record_hot_flash_and_list(async_client: AsyncClient) -> None:
    headers = await _create_test_user(async_client, "user_hot_flash_1")

    payload = {
        "occurred_at": datetime.now(UTC).isoformat(),
        "severity": 3,
        "flash_type": "NIGHT_SWEATS",
        "duration_minutes": 10,
        "triggers": ["caffeine", "warm_room"],
        "sleep_disruption_level": 2,
        "associated_with_hrt": False,
        "notes": "Despertar con sudoración profusa",
    }

    create_resp = await async_client.post(
        "/api/v1/mature-health/hot-flashes",
        headers=headers,
        json=payload,
    )
    assert create_resp.status_code == 201
    created_data = create_resp.json()
    assert created_data["severity"] == 3
    assert created_data["flash_type"] == "NIGHT_SWEATS"
    assert "caffeine" in created_data["triggers"]

    list_resp = await async_client.get(
        "/api/v1/mature-health/hot-flashes",
        headers=headers,
    )
    assert list_resp.status_code == 200
    episodes = list_resp.json()
    assert len(episodes) == 1
    assert episodes[0]["id"] == created_data["id"]


@pytest.mark.asyncio
async def test_record_cardiometabolic_panel(
    async_client: AsyncClient,
) -> None:
    headers = await _create_test_user(async_client, "user_cardio_1")

    payload = {
        "measurement_date": date(2026, 5, 1).isoformat(),
        "systolic_bp": 145,
        "diastolic_bp": 92,
        "total_cholesterol_mg_dl": 230.0,
        "ldl_cholesterol_mg_dl": 165.0,
        "hdl_cholesterol_mg_dl": 40.0,
        "triglycerides_mg_dl": 180.0,
        "fasting_glucose_mg_dl": 105.0,
    }

    resp = await async_client.post(
        "/api/v1/mature-health/cardiometabolic",
        headers=headers,
        json=payload,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["risk_level"] == "ELEVATED_RISK"
    assert "ldl_cholesterol" in data["flagged_parameters"]
    assert "blood_pressure" in data["flagged_parameters"]


@pytest.mark.asyncio
async def test_vaginal_bleeding_inviolable_alert(
    async_client: AsyncClient,
) -> None:
    headers = await _create_test_user(async_client, "user_bleeding_alert")

    payload = {
        "observation_date": date(2026, 5, 2).isoformat(),
        "days_of_prior_amenorrhea": 400,  # >= 365 days
        "flow_intensity": "LIGHT",
        "has_cramping": False,
        "notes": "Manchado escaso",
    }

    resp = await async_client.post(
        "/api/v1/mature-health/vaginal-bleeding",
        headers=headers,
        json=payload,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["is_alert_triggered"] is True
    assert data["alert_code"] == "POSTMENOPAUSAL_BLEEDING_ALERT"
    assert data["alert_severity"] == "URGENT_EMERGENCY"
    assert "endometrial" in data["alert_guidance"].lower()


@pytest.mark.asyncio
async def test_record_dexa_scan_and_classification(
    async_client: AsyncClient,
) -> None:
    headers = await _create_test_user(async_client, "user_dexa_1")

    payload = {
        "scan_date": date(2026, 4, 10).isoformat(),
        "anatomical_site": "FEMORAL_NECK",
        "t_score": -2.6,
        "z_score": -1.8,
        "bmd_g_cm2": 0.72,
        "previous_fragility_fracture": False,
        "notes": "Control anual",
    }

    resp = await async_client.post(
        "/api/v1/mature-health/dexa-scans",
        headers=headers,
        json=payload,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["category"] == "OSTEOPOROSIS"
    assert data["t_score"] == -2.6


@pytest.mark.asyncio
async def test_record_fall_assessment(async_client: AsyncClient) -> None:
    headers = await _create_test_user(async_client, "user_fall_1")

    payload = {
        "assessment_date": date(2026, 5, 1).isoformat(),
        "falls_past_year": 2,
        "has_gait_unsteadiness": True,
        "uses_walking_aid": True,
        "timed_up_and_go_seconds": 16.0,
        "environmental_hazards_identified": ["alfombras_sueltas"],
    }

    resp = await async_client.post(
        "/api/v1/mature-health/fall-assessments",
        headers=headers,
        json=payload,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["risk_level"] == "HIGH"
    assert data["composite_score"] >= 4


@pytest.mark.asyncio
async def test_record_pelvic_log(async_client: AsyncClient) -> None:
    headers = await _create_test_user(async_client, "user_pelvic_1")

    payload = {
        "log_date": date(2026, 5, 1).isoformat(),
        "incontinence_type": "STRESS",
        "daily_pad_count": 1,
        "has_pelvic_heaviness": False,
        "vaginal_dryness_level": 2,
        "has_dyspareunia": True,
    }

    resp = await async_client.post(
        "/api/v1/mature-health/pelvic-logs",
        headers=headers,
        json=payload,
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["requires_urogynecology_consult"] is True
    assert len(data["supportive_tips"]) >= 2


@pytest.mark.asyncio
async def test_support_contact_lifecycle(async_client: AsyncClient) -> None:
    headers = await _create_test_user(async_client, "user_support_1")

    # Initial check: None
    get_init = await async_client.get(
        "/api/v1/mature-health/support-contact",
        headers=headers,
    )
    assert get_init.status_code == 200
    assert get_init.json() is None

    # Save contact
    payload = {
        "contact_name": "Dra. Sofía Rivas",
        "relationship": "Hija",
        "phone_number": "+525598765432",
        "notes": "Disponible 24/7",
        "is_primary": True,
    }
    post_resp = await async_client.post(
        "/api/v1/mature-health/support-contact",
        headers=headers,
        json=payload,
    )
    assert post_resp.status_code == 200
    saved = post_resp.json()
    assert saved["contact_name"] == "Dra. Sofía Rivas"

    # Fetch again
    get_resp = await async_client.get(
        "/api/v1/mature-health/support-contact",
        headers=headers,
    )
    assert get_resp.status_code == 200
    fetched = get_resp.json()
    assert fetched["phone_number"] == "+525598765432"


@pytest.mark.asyncio
async def test_menopause_and_senior_summaries(
    async_client: AsyncClient,
) -> None:
    headers = await _create_test_user(async_client, "user_summaries_1")

    menopause_resp = await async_client.get(
        "/api/v1/mature-health/menopause/summary",
        headers=headers,
    )
    assert menopause_resp.status_code == 200
    m_data = menopause_resp.json()
    assert "straw10_stage" in m_data

    senior_resp = await async_client.get(
        "/api/v1/mature-health/senior-vitality/summary",
        headers=headers,
    )
    assert senior_resp.status_code == 200
    s_data = senior_resp.json()
    assert "has_fracture_alert" in s_data
