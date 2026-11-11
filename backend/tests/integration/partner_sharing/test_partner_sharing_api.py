"""Integration tests for Partner Sharing API."""

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


async def _create_user(
    client: AsyncClient, uid: str, name: str, life_stage: str = "pregnancy"
) -> dict[str, str]:
    headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
    onboarding_payload = {
        "first_name": name,
        "last_name": "Test",
        "current_life_stage": life_stage,
        "birth_year": 1996,
        "primary_intents": ["pregnancy_tracking"],
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
async def test_full_partner_sharing_lifecycle(
    async_client: AsyncClient,
) -> None:
    """Verify invitation generation, redemption, permissions, and revocation."""
    owner_headers = await _create_user(
        async_client, uid="user-owner-1", name="Fernanda"
    )
    partner_headers = await _create_user(
        async_client, uid="user-partner-1", name="Mateo"
    )

    # 1. Owner generates invitation
    inv_resp = await async_client.post(
        "/api/v1/partner-sharing/invitations", headers=owner_headers
    )
    assert inv_resp.status_code == 201
    code = inv_resp.json()["invitation_code"]
    assert code.startswith("CORA-")

    # 2. Owner cannot redeem their own invitation
    self_redeem_resp = await async_client.post(
        "/api/v1/partner-sharing/invitations/redeem",
        json={"invitation_code": code},
        headers=owner_headers,
    )
    assert self_redeem_resp.status_code == 400
    assert "No puedes vincularte contigo misma" in self_redeem_resp.text

    # 3. Partner redeems invitation
    redeem_resp = await async_client.post(
        "/api/v1/partner-sharing/invitations/redeem",
        json={"invitation_code": code},
        headers=partner_headers,
    )
    assert redeem_resp.status_code == 200
    link_data = redeem_resp.json()
    link_id = link_data["id"]
    assert link_data["status"] == "ACTIVE"
    # By default minimum privilege (all False)
    assert link_data["permissions"]["share_pregnancy_milestones"] is False

    # 4. Partner views projection before permissions: pregnancy details should be None
    view_initial = await async_client.get(
        "/api/v1/partner-sharing/shared-with-me", headers=partner_headers
    )
    assert view_initial.status_code == 200
    proj_1 = view_initial.json()
    assert proj_1["owner_first_name"] == "Fernanda"
    assert proj_1["pregnancy_week"] is None

    # 5. Owner updates permissions: enable pregnancy milestones only
    update_perm_resp = await async_client.patch(
        f"/api/v1/partner-sharing/links/{link_id}/permissions",
        json={
            "permissions": {
                "share_fertility_window": False,
                "share_pregnancy_milestones": True,
                "share_mood_and_support_tips": False,
            }
        },
        headers=owner_headers,
    )
    assert update_perm_resp.status_code == 200
    assert update_perm_resp.json()["permissions"]["share_pregnancy_milestones"] is True

    # 6. Partner views projection now: pregnancy milestone is visible
    view_updated = await async_client.get(
        "/api/v1/partner-sharing/shared-with-me", headers=partner_headers
    )
    assert view_updated.status_code == 200
    proj_2 = view_updated.json()
    assert proj_2["pregnancy_week"] == 20
    assert "mango" in proj_2["fetal_milestone"].lower()
    assert proj_2["fertility_window_summary"] is None

    # 7. Owner revokes link immediately
    revoke_resp = await async_client.delete(
        f"/api/v1/partner-sharing/links/{link_id}", headers=owner_headers
    )
    assert revoke_resp.status_code == 204

    # 8. Partner attempts to view projection: immediate 404 (no active links)
    view_after_revoke = await async_client.get(
        "/api/v1/partner-sharing/shared-with-me", headers=partner_headers
    )
    assert view_after_revoke.status_code == 404
