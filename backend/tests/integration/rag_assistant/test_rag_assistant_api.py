"""Integration tests for the 4-stage Clinical RAG Assistant REST API."""

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
    client: AsyncClient,
    uid: str,
    life_stage: str = "regular_adult",
) -> dict[str, str]:
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    onboarding_payload = {
        "first_name": "Lucia",
        "last_name": "Mendez",
        "current_life_stage": life_stage,
        "birth_year": 1994,
        "primary_intents": ["preventive_health"],
        "hormonal_method": "none",
        "diagnosed_conditions": ["none"],
        "clinical_context_completed": True,
    }
    resp = await client.put(
        "/api/v1/identity/onboarding",
        json=onboarding_payload,
        headers=headers,
    )
    assert resp.status_code == 200, resp.text
    return headers


@pytest.mark.asyncio
async def test_rag_assistant_grounded_conversation_and_emergency_interception(
    async_client: AsyncClient,
) -> None:
    """Verify normal grounded answer with citations + emergency interception."""
    headers = await _create_test_user(
        async_client,
        uid="rag-user-1",
        life_stage="regular_adult",
    )

    # 1. Create conversation
    conv_resp = await async_client.post(
        "/api/v1/assistant/conversations",
        json={"title": "Dudas sobre mi fase lútea"},
        headers=headers,
    )
    assert conv_resp.status_code == 201, conv_resp.text
    conv_data = conv_resp.json()
    conv_id = conv_data["id"]
    assert conv_data["life_stage_at_creation"] == "regular_adult"

    # 2. List conversations
    list_resp = await async_client.get(
        "/api/v1/assistant/conversations",
        headers=headers,
    )
    assert list_resp.status_code == 200
    assert list_resp.json()["total"] == 1

    # 3. Send normal educational question -> grounded response with citations
    normal_msg_resp = await async_client.post(
        f"/api/v1/assistant/conversations/{conv_id}/messages",
        json={
            "query": (
                "¿Qué parámetros usa FIGO para definir un ciclo menstrual "
                "normal y por qué baja la progesterona en la fase lútea?"
            )
        },
        headers=headers,
    )
    assert normal_msg_resp.status_code == 201, normal_msg_resp.text
    normal_msg = normal_msg_resp.json()
    assert normal_msg["role"] == "assistant"
    assert normal_msg["is_emergency_intercepted"] is False
    assert normal_msg["safety_triage_category"] == "NONE"
    assert len(normal_msg["citations"]) >= 1
    assert normal_msg["citations"][0]["scientific_source"] != ""

    # 4. Send emergency red-flag question -> intercepted in Stage 1
    emerg_msg_resp = await async_client.post(
        f"/api/v1/assistant/conversations/{conv_id}/messages",
        json={
            "query": (
                "Estoy empapando dos toallas por hora desde hace 3 horas "
                "y me siento muy mareada"
            )
        },
        headers=headers,
    )
    assert emerg_msg_resp.status_code == 201, emerg_msg_resp.text
    emerg_msg = emerg_msg_resp.json()
    assert emerg_msg["is_emergency_intercepted"] is True
    assert emerg_msg["safety_triage_category"] == "HEMORRHAGE_EMERGENCY"
    assert emerg_msg["disclaimer_level"] == "EMERGENCY_URGENT"
    assert emerg_msg["citations"] == []

    # 5. List messages in conversation (2 user + 2 assistant = 4 messages)
    history_resp = await async_client.get(
        f"/api/v1/assistant/conversations/{conv_id}/messages",
        headers=headers,
    )
    assert history_resp.status_code == 200
    history = history_resp.json()
    assert history["total"] == 4
