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
        "first_name": "Mariana",
        "last_name": "López",
        "current_life_stage": "pregnancy",
        "birth_year": 1993,
        "primary_intents": ["pregnancy_tracking"],
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
async def test_full_pregnancy_lifecycle_and_acog_alerts(
    async_client: AsyncClient,
) -> None:
    headers = await _create_test_user(async_client, "pregnancy-user-1")

    # 1. Start pregnancy episode
    today = datetime.now(UTC).date()
    lmp = today - timedelta(weeks=12)  # 12 weeks pregnant
    ep_resp = await async_client.post(
        "/api/v1/pregnancy/episodes",
        headers=headers,
        json={"last_menstrual_period": lmp.isoformat()},
    )
    assert ep_resp.status_code == 201
    ep_data = ep_resp.json()
    assert ep_data["is_active"] is True
    assert ep_data["clinical_edd"] == (lmp + timedelta(days=280)).isoformat()

    # 2. Get active summary
    summary_resp = await async_client.get(
        "/api/v1/pregnancy/active",
        headers=headers,
    )
    assert summary_resp.status_code == 200
    summary = summary_resp.json()
    assert summary["gestational_weeks"] == 12
    assert summary["trimester"] == 1
    assert "ciruela" in summary["milestone"]["fruit_comparison"].lower()

    # 3. Get milestone for week 20
    m20_resp = await async_client.get("/api/v1/pregnancy/milestone/20")
    assert m20_resp.status_code == 200
    m20 = m20_resp.json()
    assert m20["week"] == 20
    assert (
        "plátano" in m20["fruit_comparison"].lower()
        or "platano" in m20["fruit_comparison"].lower()
    )

    # 4. Log vitals: Normal reading
    v_norm_resp = await async_client.post(
        "/api/v1/pregnancy/vitals",
        headers=headers,
        json={
            "systolic_mmhg": 118,
            "diastolic_mmhg": 76,
            "weight_kg": 64.5,
            "symptoms": [],
        },
    )
    assert v_norm_resp.status_code == 201
    assert len(v_norm_resp.json()["alerts"]) == 0

    # 5. Log vitals: Severe preeclampsia emergency (165/110)
    v_severe_resp = await async_client.post(
        "/api/v1/pregnancy/vitals",
        headers=headers,
        json={
            "systolic_mmhg": 165,
            "diastolic_mmhg": 110,
            "symptoms": [],
        },
    )
    assert v_severe_resp.status_code == 201
    severe_alerts = v_severe_resp.json()["alerts"]
    assert len(severe_alerts) >= 1
    assert severe_alerts[0]["severity"] == "urgent_emergency"
    assert severe_alerts[0]["category"] == "preeclampsia_risk"

    # 6. Log vitals: Mild hypertension with severe symptom -> Escalates to urgent
    v_symp_resp = await async_client.post(
        "/api/v1/pregnancy/vitals",
        headers=headers,
        json={
            "systolic_mmhg": 144,
            "diastolic_mmhg": 92,
            "symptoms": [
                {
                    "symptom_type": "persistent_severe_headache",
                    "notes": "Dolor frontal intenso",
                }
            ],
        },
    )
    assert v_symp_resp.status_code == 201
    symp_alerts = v_symp_resp.json()["alerts"]
    assert len(symp_alerts) >= 1
    assert symp_alerts[0]["severity"] == "urgent_emergency"
    assert "Preeclampsia con signos de alarma" in symp_alerts[0]["title"]

    # 7. Log vitals: Fasting glucose elevation
    v_glu_resp = await async_client.post(
        "/api/v1/pregnancy/vitals",
        headers=headers,
        json={
            "glucose_mg_dl": 102.0,
            "glucose_timing": "fasting",
            "symptoms": [],
        },
    )
    assert v_glu_resp.status_code == 201
    glu_alerts = v_glu_resp.json()["alerts"]
    assert len(glu_alerts) >= 1
    assert glu_alerts[0]["severity"] == "priority_consult"
    assert glu_alerts[0]["category"] == "gestational_diabetes_risk"

    # 8. Contractions: Rule 5-1-1
    c_start = datetime.now(UTC) - timedelta(hours=1)
    events = [
        {
            "started_at": (c_start + timedelta(minutes=i * 4)).isoformat(),
            "duration_seconds": 65,
            "intensity": "strong",
        }
        for i in range(12)
    ]
    # Update episode to term (39 weeks) for 5-1-1 test
    await async_client.post(
        "/api/v1/pregnancy/episodes",
        headers=headers,
        json={"last_menstrual_period": (today - timedelta(weeks=39)).isoformat()},
    )
    c_resp = await async_client.post(
        "/api/v1/pregnancy/contractions/sessions",
        headers=headers,
        json={"events": events},
    )
    assert c_resp.status_code == 201
    c_data = c_resp.json()
    assert c_data["pattern"] == "active_labor_511"
    assert c_data["alert"] is not None

    # 9. Kick session: Cardiff count to 10
    k_resp = await async_client.post(
        "/api/v1/pregnancy/kick-sessions",
        headers=headers,
        json={
            "kicks_count": 10,
            "duration_minutes": 45,
            "target_reached_at_minutes": 45,
        },
    )
    assert k_resp.status_code == 201
    k_data = k_resp.json()
    assert k_data["target_reached"] is True
    assert k_data["is_reassuring"] is True

    # 10. Birth Plan: update and read
    plan_resp = await async_client.put(
        "/api/v1/pregnancy/birth-plan",
        headers=headers,
        json={
            "companion_preferences": ["Pareja", "Doula"],
            "pain_management": ["Epidural a demanda", "Hidroterapia"],
            "delivery_environment": ["Luz tenue", "Música relajante"],
            "immediate_postpartum": [
                "Contacto piel con piel inmediato",
                "Pinzamiento tardío de cordón",
            ],
            "special_requests": "Evitar episiotomía de rutina",
        },
    )
    assert plan_resp.status_code == 200
    plan_get = await async_client.get(
        "/api/v1/pregnancy/birth-plan",
        headers=headers,
    )
    assert plan_get.status_code == 200
    assert "Doula" in plan_get.json()["companion_preferences"]

    # 11. Appointments: create and toggle
    app_resp = await async_client.post(
        "/api/v1/pregnancy/appointments",
        headers=headers,
        json={
            "scheduled_at": (datetime.now(UTC) + timedelta(days=7)).isoformat(),
            "doctor_or_clinic": "Hospital Materno Infantil - Dra. Almonte",
            "gestational_week": 40,
            "topics_to_discuss": ["Revisión de dinámica uterina", "Monitoreo fetal"],
            "notes": "Llevar analítica y ecografías previas",
        },
    )
    assert app_resp.status_code == 201
    app_id = app_resp.json()["id"]

    toggle_resp = await async_client.patch(
        f"/api/v1/pregnancy/appointments/{app_id}/toggle",
        headers=headers,
        json={"is_completed": True},
    )
    assert toggle_resp.status_code == 200
    assert toggle_resp.json()["is_completed"] is True
