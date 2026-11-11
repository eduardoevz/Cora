"""Integration tests for GDPR full data export and cascading account purge."""

import io
import zipfile
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


async def _create_full_user(client: AsyncClient, uid: str, name: str) -> dict[str, str]:
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    onboarding_payload = {
        "first_name": name,
        "last_name": "Sovereign",
        "current_life_stage": "regular_adult",
        "birth_year": 1993,
        "primary_intents": ["general_wellness"],
        "hormonal_method": "none",
        "diagnosed_conditions": ["none"],
        "clinical_context_completed": True,
    }
    resp = await client.put(
        "/api/v1/identity/onboarding", json=onboarding_payload, headers=headers
    )
    assert resp.status_code == 200, resp.text
    return headers


@pytest.mark.asyncio
async def test_full_data_export_and_irreversible_purge(
    async_client: AsyncClient,
) -> None:
    """Verify data-export ZIP contents and account purge with confirmation."""
    user1_headers = await _create_user(
        async_client, uid="sovereign-user-1", name="Valeria"
    )
    user2_headers = await _create_user(
        async_client, uid="neighbor-user-2", name="Carmen"
    )

    # 1. Export Data as ZIP
    export_resp = await async_client.post(
        "/api/v1/identity/me/data-export", headers=user1_headers
    )
    assert export_resp.status_code == 200
    assert export_resp.headers["content-type"] == "application/zip"
    assert "cora_data_export" in export_resp.headers["content-disposition"]

    # Verify ZIP integrity and files
    zip_bytes = export_resp.content
    with zipfile.ZipFile(io.BytesIO(zip_bytes), "r") as zf:
        file_list = zf.namelist()
        assert "manifest.json" in file_list
        assert "profile.json" in file_list
        profile_content = zf.read("profile.json").decode("utf-8")
        assert "Valeria" in profile_content

    # 2. Purge account with invalid confirmation phrase -> 400
    bad_purge = await async_client.request(
        "DELETE",
        "/api/v1/identity/me",
        json={"confirm_phrase": "borrar"},
        headers=user1_headers,
    )
    assert bad_purge.status_code == 400
    assert "ELIMINAR MI CUENTA CORA" in bad_purge.text

    # 3. Purge account with exact confirmation phrase -> 204
    purge_resp = await async_client.request(
        "DELETE",
        "/api/v1/identity/me",
        json={"confirm_phrase": "ELIMINAR MI CUENTA CORA"},
        headers=user1_headers,
    )
    assert purge_resp.status_code == 204

    # 4. User 1 profile is completely purged (GET /identity/me -> 404)
    profile_check = await async_client.get("/api/v1/identity/me", headers=user1_headers)
    assert profile_check.status_code == 404

    # 5. Neighbor User 2 profile remains intact and untouched
    neighbor_check = await async_client.get(
        "/api/v1/identity/me", headers=user2_headers
    )
    assert neighbor_check.status_code == 200
    assert neighbor_check.json()["first_name"] == "Carmen"


async def _create_user(client: AsyncClient, uid: str, name: str) -> dict[str, str]:
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    onboarding_payload = {
        "first_name": name,
        "last_name": "GDPR",
        "current_life_stage": "regular_adult",
        "birth_year": 1993,
        "primary_intents": ["general_wellness"],
        "hormonal_method": "none",
        "diagnosed_conditions": ["none"],
        "clinical_context_completed": True,
    }
    resp = await client.put(
        "/api/v1/identity/onboarding", json=onboarding_payload, headers=headers
    )
    assert resp.status_code == 200, resp.text
    return headers
