"""Zero-PHI / Zero-PII Observability & Logging Audit across normal and error flows."""

import logging
from collections.abc import AsyncIterator
from datetime import UTC, datetime

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
async def test_zero_phi_and_token_leakage_in_application_logs(
    async_client: AsyncClient,
    caplog: pytest.LogCaptureFixture,
) -> None:
    """Ensure clinical notes, EPDS scores, and Bearer tokens never leak into logs."""
    caplog.set_level(logging.INFO)
    caplog.set_level(logging.DEBUG, logger="app")

    canary_bearer_val = "test-token:phi-audit-uid-999:paciente.prueba@cora.test"
    canary_clinical_note = "Texto clinico sintetico de dispareunia para auditoria"
    canary_rag_text = "Consulta clinica sintetica de ideacion autolesiva"
    headers = {"Authorization": f"Bearer {canary_bearer_val}"}

    # 1. Onboarding with full name & email in token
    onb_resp = await async_client.put(
        "/api/v1/identity/onboarding",
        headers=headers,
        json={
            "first_name": "ValeriaCanary",
            "last_name": "ApellidoCanary",
            "current_life_stage": "postpartum",
            "birth_year": 1991,
            "primary_intents": ["general_wellness"],
            "hormonal_method": "none",
            "diagnosed_conditions": ["endometriosis"],
            "clinical_context_completed": True,
        },
    )
    assert onb_resp.status_code == 200

    # 2. Wellness log with intimate notes
    today_str = datetime.now(UTC).date().isoformat()
    well_resp = await async_client.put(
        f"/api/v1/wellness/logs/{today_str}",
        headers=headers,
        json={
            "sleep_hours": 6.5,
            "sleep_quality": 4,
            "hydration_ml": 1800,
            "exercise_minutes": 20,
            "energy_level": 3,
            "mood_tags": ["anxious"],
            "notes": canary_clinical_note,
        },
    )
    assert well_resp.status_code in (200, 201)

    # 3. EPDS Screening with item_10 > 0 (self-harm crisis)
    epds_resp = await async_client.post(
        "/api/v1/postpartum/epds-screenings",
        headers=headers,
        json={
            "days_postpartum": 14,
            "responses": {
                "item_1": 2,
                "item_2": 2,
                "item_3": 2,
                "item_4": 2,
                "item_5": 2,
                "item_6": 2,
                "item_7": 2,
                "item_8": 2,
                "item_9": 2,
                "item_10": 3,
            },
        },
    )
    assert epds_resp.status_code == 201

    # 4. RAG Assistant query with sensitive clinical text
    conv_resp = await async_client.post(
        "/api/v1/assistant/conversations",
        headers=headers,
        json={"title": "Consulta Privada"},
    )
    conv_id = conv_resp.json()["id"]
    await async_client.post(
        f"/api/v1/assistant/conversations/{conv_id}/messages",
        headers=headers,
        json={"query": f"Me siento sin salida {canary_rag_text}"},
    )

    # 5. Trigger 422 Validation Error & 400 Domain Error containing sensitive strings
    err_422 = await async_client.put(
        f"/api/v1/wellness/logs/{today_str}",
        headers=headers,
        json={
            "sleep_hours": 99.0,  # Invalid > 24h
            "notes": canary_clinical_note,
        },
    )
    assert err_422.status_code == 422

    err_400 = await async_client.put(
        f"/api/v1/fertility/logs/{today_str}",
        headers=headers,
        json={
            "basal_body_temperature_celsius": 49.5,  # Domain invariant error
            "notes": canary_clinical_note,
        },
    )
    assert err_400.status_code in (400, 422)

    # Inspect all captured logs
    logged_output = caplog.text
    assert canary_bearer_val not in logged_output
    assert "paciente.prueba@cora.test" not in logged_output
    assert canary_clinical_note not in logged_output
    assert canary_rag_text not in logged_output
    assert "ValeriaCanary" not in logged_output
