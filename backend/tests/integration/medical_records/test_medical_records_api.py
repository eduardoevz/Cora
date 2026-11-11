"""Integration tests for Medical Records REST APIs.

Includes Digital Folder, R2, Vaccines, and Doctor-Ready PDF.
"""

from collections.abc import AsyncIterator
from datetime import date
from uuid import uuid4

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
    client: AsyncClient,
    uid: str,
    first_name: str = "Valeria",
    birth_year: int = 1998,
    life_stage: str = "regular_adult",
) -> dict[str, str]:
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    onboarding_payload = {
        "first_name": first_name,
        "last_name": "Ríos",
        "current_life_stage": life_stage,
        "birth_year": birth_year,
        "primary_intents": ["preventive_health"],
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
async def test_medical_exam_lifecycle_and_upload_url(
    async_client: AsyncClient,
) -> None:
    headers = await _create_test_user(
        async_client, uid=f"user_records_{uuid4().hex[:8]}"
    )

    # 1. Register Medical Exam
    exam_payload = {
        "exam_type": "pap_smear",
        "title": "Citología Cervicovaginal Anual",
        "performed_at": date.today().isoformat(),
        "clinic_or_lab": "Laboratorio Clínico Central",
        "notes": "Negativo para lesión intraepitelial o malignidad.",
    }
    resp = await async_client.post(
        "/api/v1/medical-records/exams", json=exam_payload, headers=headers
    )
    assert resp.status_code == 201, resp.text
    exam_data = resp.json()
    exam_id = exam_data["id"]
    assert exam_data["exam_type"] == "pap_smear"
    assert exam_data["clinic_or_lab"] == "Laboratorio Clínico Central"

    # 2. Request Presigned Upload URL for attachment
    upload_req = {
        "file_name": "informe_pap.pdf",
        "mime_type": "application/pdf",
        "size_bytes": 1024 * 500,
    }
    upload_resp = await async_client.post(
        f"/api/v1/medical-records/exams/{exam_id}/upload-url",
        json=upload_req,
        headers=headers,
    )
    assert upload_resp.status_code == 200, upload_resp.text
    url_data = upload_resp.json()
    assert "upload_url" in url_data
    assert f"/records/{exam_id}/informe_pap.pdf" in url_data["storage_key"]
    assert url_data["expires_in_seconds"] <= 900

    # 3. Retrieve Presigned Download URL
    download_resp = await async_client.get(
        f"/api/v1/medical-records/exams/{exam_id}/download-url",
        headers=headers,
    )
    assert download_resp.status_code == 200, download_resp.text
    down_data = download_resp.json()
    assert "download_url" in down_data
    assert "records" in down_data["download_url"]

    # 4. List Exams
    list_resp = await async_client.get("/api/v1/medical-records/exams", headers=headers)
    assert list_resp.status_code == 200
    items = list_resp.json()
    assert len(items) >= 1
    assert items[0]["id"] == exam_id


@pytest.mark.asyncio
async def test_anti_idor_protection_on_download_url(
    async_client: AsyncClient,
) -> None:
    headers_1 = await _create_test_user(async_client, uid=f"user1_{uuid4().hex[:8]}")
    headers_2 = await _create_test_user(async_client, uid=f"user2_{uuid4().hex[:8]}")

    # User 1 registers an exam
    exam_resp = await async_client.post(
        "/api/v1/medical-records/exams",
        json={
            "exam_type": "mammogram",
            "title": "Mamografía Privada",
            "performed_at": date.today().isoformat(),
        },
        headers=headers_1,
    )
    exam_id = exam_resp.json()["id"]

    # Attach file
    await async_client.post(
        f"/api/v1/medical-records/exams/{exam_id}/upload-url",
        json={
            "file_name": "mamografia.jpg",
            "mime_type": "image/jpeg",
            "size_bytes": 2048,
        },
        headers=headers_1,
    )

    # User 2 tries to request download URL for User 1's exam -> MUST return 404
    attack_resp = await async_client.get(
        f"/api/v1/medical-records/exams/{exam_id}/download-url",
        headers=headers_2,
    )
    assert attack_resp.status_code == 404, (
        f"Expected 404 for IDOR attempt, got {attack_resp.status_code}"
    )


@pytest.mark.asyncio
async def test_preventive_calendar_endpoint(
    async_client: AsyncClient,
) -> None:
    headers = await _create_test_user(
        async_client,
        uid=f"user_prev_{uuid4().hex[:8]}",
        birth_year=1998,
        life_stage="regular_adult",
    )
    resp = await async_client.get(
        "/api/v1/medical-records/preventive-calendar", headers=headers
    )
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert "screenings" in data
    codes = [s["screening_code"] for s in data["screenings"]]
    assert "PAP_SMEAR" in codes


@pytest.mark.asyncio
async def test_vaccination_and_specialist_endpoints(
    async_client: AsyncClient,
) -> None:
    headers = await _create_test_user(async_client, uid=f"user_vax_{uuid4().hex[:8]}")

    # 1. Vaccination
    vax_resp = await async_client.post(
        "/api/v1/medical-records/vaccinations",
        json={
            "vaccine_type": "influenza",
            "dose_number": 1,
            "administered_at": date.today().isoformat(),
            "lot_number": "INF-2026",
            "administrator_clinic": "IMSS Clínica 4",
        },
        headers=headers,
    )
    assert vax_resp.status_code == 201, vax_resp.text

    list_vax = await async_client.get(
        "/api/v1/medical-records/vaccinations", headers=headers
    )
    assert list_vax.status_code == 200
    vax_items = list_vax.json()
    assert len(vax_items) >= 1
    assert vax_items[0]["vaccine_type"] == "influenza"

    # 2. Specialist
    spec_resp = await async_client.post(
        "/api/v1/medical-records/specialists",
        json={
            "full_name": "Dr. Fernando Mora",
            "specialty": "endocrinology",
            "clinic_name": "Centro Médico Nacional",
            "phone_number": "+525544332211",
            "email": "dr.mora@corahealth.mx",
            "is_favorite": True,
        },
        headers=headers,
    )
    assert spec_resp.status_code == 201, spec_resp.text
    spec_id = spec_resp.json()["id"]

    list_spec = await async_client.get(
        "/api/v1/medical-records/specialists", headers=headers
    )
    assert list_spec.status_code == 200
    spec_items = list_spec.json()
    assert len(spec_items) >= 1
    assert spec_items[0]["full_name"] == "Dr. Fernando Mora"

    # Delete specialist
    del_resp = await async_client.delete(
        f"/api/v1/medical-records/specialists/{spec_id}", headers=headers
    )
    assert del_resp.status_code == 204


@pytest.mark.asyncio
async def test_generate_doctor_ready_pdf_endpoint(
    async_client: AsyncClient,
) -> None:
    headers = await _create_test_user(async_client, uid=f"user_pdf_{uuid4().hex[:8]}")

    pdf_req = {
        "reporting_window_months": 6,
        "specialist_notes": "Consulta de rutina de control preventivo.",
    }
    resp = await async_client.post(
        "/api/v1/medical-records/doctor-report/pdf",
        json=pdf_req,
        headers=headers,
    )
    assert resp.status_code == 200, resp.text
    assert resp.headers["content-type"] == "application/pdf"
    assert resp.content.startswith(b"%PDF-")
    assert b"%%EOF" in resp.content[-1024:]
