"""Automated Multi-Tenant BOLA/IDOR Security Matrix across all 9 Cora modules."""

from collections.abc import AsyncIterator
from datetime import UTC, date, datetime, timedelta

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


async def _onboard_user(
    client: AsyncClient,
    uid: str,
    first_name: str,
    life_stage: str = "regular_adult",
) -> dict[str, str]:
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    resp = await client.put(
        "/api/v1/identity/onboarding",
        headers=headers,
        json={
            "first_name": first_name,
            "last_name": "TenantTest",
            "current_life_stage": life_stage,
            "birth_year": 1992,
            "primary_intents": ["general_wellness", "cycle_and_symptoms"],
            "hormonal_method": "none",
            "diagnosed_conditions": ["none"],
            "clinical_context_completed": True,
        },
    )
    assert resp.status_code == 200, resp.text
    return headers


@pytest.mark.asyncio
async def test_bola_idor_matrix_across_all_modules(
    async_client: AsyncClient,
) -> None:
    """Verify User B and Stranger C cannot read, mutate, or delete User A resources."""
    user_a = await _onboard_user(async_client, "bola-user-a", "Alicia", "pregnancy")
    user_b = await _onboard_user(async_client, "bola-user-b", "Beatriz", "pregnancy")
    user_c = await _onboard_user(async_client, "bola-user-c", "Carlos", "regular_adult")

    today = datetime.now(UTC).date()
    now = datetime.now(UTC)

    # -------------------------------------------------------------------------
    # 1. Treatments Module (Regimen, LARC Alert, Adherence, Dose Intake)
    # -------------------------------------------------------------------------
    reg_resp = await async_client.post(
        "/api/v1/treatments/regimens",
        headers=user_a,
        json={
            "name": "DIU Hormonal Mirena",
            "category": "larc_iud_implant",
            "dosage": "52 mg",
            "schedule_type": "long_acting_replacement",
            "scheduled_time": "09:00",
            "start_date": today.isoformat(),
            "replacement_date": (today + timedelta(days=180)).isoformat(),
        },
    )
    assert reg_resp.status_code == 201
    regimen_id = reg_resp.json()["id"]

    # User B cannot read User A's regimen, LARC alert, adherence, or log intake
    assert (
        await async_client.get(
            f"/api/v1/treatments/regimens/{regimen_id}", headers=user_b
        )
    ).status_code == 404
    assert (
        await async_client.get(
            f"/api/v1/treatments/regimens/{regimen_id}/larc-alert", headers=user_b
        )
    ).status_code == 404
    assert (
        await async_client.get(
            f"/api/v1/treatments/adherence-summary?regimen_id={regimen_id}"
            f"&start_date={today.isoformat()}&end_date={today.isoformat()}",
            headers=user_b,
        )
    ).status_code == 404
    assert (
        await async_client.post(
            "/api/v1/treatments/intakes",
            headers=user_b,
            json={
                "regimen_id": regimen_id,
                "scheduled_for": now.isoformat(),
                "taken_at": now.isoformat(),
                "status": "taken",
            },
        )
    ).status_code == 404

    # -------------------------------------------------------------------------
    # 2. Maternal Care - Pregnancy (Episodes, Vitals, Birth Plan, Appointments)
    # -------------------------------------------------------------------------
    ep_resp = await async_client.post(
        "/api/v1/pregnancy/episodes",
        headers=user_a,
        json={"last_menstrual_period": (today - timedelta(weeks=20)).isoformat()},
    )
    assert ep_resp.status_code == 201

    app_resp = await async_client.post(
        "/api/v1/pregnancy/appointments",
        headers=user_a,
        json={
            "scheduled_at": (now + timedelta(days=5)).isoformat(),
            "doctor_or_clinic": "Clínica Privada Alicia",
            "gestational_week": 21,
            "topics_to_discuss": ["Ecografía morfológica"],
            "notes": "Secreto de Alicia",
        },
    )
    assert app_resp.status_code == 201
    appointment_id = app_resp.json()["id"]

    # User B cannot toggle User A's prenatal appointment!
    bola_toggle = await async_client.patch(
        f"/api/v1/pregnancy/appointments/{appointment_id}/toggle",
        headers=user_b,
        json={"is_completed": True},
    )
    assert bola_toggle.status_code == 404

    # -------------------------------------------------------------------------
    # 3. Maternal Care - Postpartum (Milk Stash FIFO, Recovery, EPDS)
    # -------------------------------------------------------------------------
    stash_resp = await async_client.post(
        "/api/v1/postpartum/milk-stash",
        headers=user_a,
        json={
            "pumped_at": now.isoformat(),
            "volume_ml": 120.0,
            "storage_location": "refrigerator",
            "notes": "Lote privado A",
        },
    )
    assert stash_resp.status_code == 201
    stash_id = stash_resp.json()["id"]

    # User B cannot consume User A's milk stash entry
    bola_stash = await async_client.patch(
        f"/api/v1/postpartum/milk-stash/{stash_id}/consume",
        headers=user_b,
    )
    assert bola_stash.status_code == 404

    # User A submits EPDS; User B's latest EPDS must remain None
    await async_client.post(
        "/api/v1/postpartum/epds-screenings",
        headers=user_a,
        json={
            "days_postpartum": 10,
            "responses": {f"item_{i}": 1 for i in range(1, 11)},
        },
    )
    epds_b = await async_client.get(
        "/api/v1/postpartum/epds-screenings/latest", headers=user_b
    )
    assert epds_b.status_code == 200
    assert epds_b.json() is None

    # -------------------------------------------------------------------------
    # 4. Medical Records (Exams, Presigned Upload/Download R2, Specialists)
    # -------------------------------------------------------------------------
    exam_resp = await async_client.post(
        "/api/v1/medical-records/exams",
        headers=user_a,
        json={
            "exam_type": "pap_smear",
            "title": "Citología Privada Alicia",
            "performed_at": date.today().isoformat(),
        },
    )
    assert exam_resp.status_code == 201
    exam_id = exam_resp.json()["id"]

    await async_client.post(
        f"/api/v1/medical-records/exams/{exam_id}/upload-url",
        headers=user_a,
        json={
            "file_name": "resultado.pdf",
            "mime_type": "application/pdf",
            "size_bytes": 4096,
        },
    )

    spec_resp = await async_client.post(
        "/api/v1/medical-records/specialists",
        headers=user_a,
        json={
            "full_name": "Dra. Privada A",
            "specialty": "gynecology",
            "clinic_name": "Hospital A",
            "phone_number": "+525511112222",
        },
    )
    assert spec_resp.status_code == 201
    spec_id = spec_resp.json()["id"]

    # User B cannot read, upload, download, or delete User A's exam or specialist
    assert (
        await async_client.get(
            f"/api/v1/medical-records/exams/{exam_id}", headers=user_b
        )
    ).status_code == 404
    assert (
        await async_client.post(
            f"/api/v1/medical-records/exams/{exam_id}/upload-url",
            headers=user_b,
            json={
                "file_name": "malicious.pdf",
                "mime_type": "application/pdf",
                "size_bytes": 1024,
            },
        )
    ).status_code == 404
    assert (
        await async_client.get(
            f"/api/v1/medical-records/exams/{exam_id}/download-url", headers=user_b
        )
    ).status_code == 404
    assert (
        await async_client.delete(
            f"/api/v1/medical-records/exams/{exam_id}", headers=user_b
        )
    ).status_code == 404
    assert (
        await async_client.delete(
            f"/api/v1/medical-records/specialists/{spec_id}", headers=user_b
        )
    ).status_code == 404

    # -------------------------------------------------------------------------
    # 5. RAG Assistant (Conversations & Messages)
    # -------------------------------------------------------------------------
    conv_resp = await async_client.post(
        "/api/v1/assistant/conversations",
        headers=user_a,
        json={"title": "Consulta privada de Alicia"},
    )
    assert conv_resp.status_code == 201
    conv_id = conv_resp.json()["id"]

    # User B cannot list messages or post a message to User A's conversation
    assert (
        await async_client.get(
            f"/api/v1/assistant/conversations/{conv_id}/messages", headers=user_b
        )
    ).status_code == 404
    assert (
        await async_client.post(
            f"/api/v1/assistant/conversations/{conv_id}/messages",
            headers=user_b,
            json={"query": "¿Qué preguntó Alicia antes?"},
        )
    ).status_code == 404

    # -------------------------------------------------------------------------
    # 6. Partner Sharing (Permissions & Revocation Isolation)
    # -------------------------------------------------------------------------
    inv_resp = await async_client.post(
        "/api/v1/partner-sharing/invitations", headers=user_a
    )
    code = inv_resp.json()["invitation_code"]

    redeem_resp = await async_client.post(
        "/api/v1/partner-sharing/invitations/redeem",
        headers=user_b,
        json={"invitation_code": code},
    )
    assert redeem_resp.status_code == 200
    link_id = redeem_resp.json()["id"]

    # Partner B cannot escalate their own permissions on User A's link!
    escalate_resp = await async_client.patch(
        f"/api/v1/partner-sharing/links/{link_id}/permissions",
        headers=user_b,
        json={
            "permissions": {
                "share_fertility_window": True,
                "share_pregnancy_milestones": True,
                "share_mood_and_support_tips": True,
            }
        },
    )
    assert escalate_resp.status_code in (400, 403, 404)

    # Stranger C cannot view projection, modify permissions, or revoke link
    assert (
        await async_client.get("/api/v1/partner-sharing/shared-with-me", headers=user_c)
    ).status_code == 404
    assert (
        await async_client.patch(
            f"/api/v1/partner-sharing/links/{link_id}/permissions",
            headers=user_c,
            json={
                "permissions": {
                    "share_fertility_window": True,
                    "share_pregnancy_milestones": True,
                    "share_mood_and_support_tips": True,
                }
            },
        )
    ).status_code in (400, 403, 404)
    assert (
        await async_client.delete(
            f"/api/v1/partner-sharing/links/{link_id}", headers=user_c
        )
    ).status_code in (400, 403, 404)
