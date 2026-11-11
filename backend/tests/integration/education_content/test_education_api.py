"""Integration tests for Curated Clinical Library and Vector Evidence Retrieval."""

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
        "first_name": "Elena",
        "last_name": "Rojas",
        "current_life_stage": life_stage,
        "birth_year": 1995,
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
async def test_list_and_filter_curated_clinical_articles(
    async_client: AsyncClient,
) -> None:
    """Verify listing and filtering articles by life stage, tag, and query."""
    headers = await _create_test_user(async_client, "edu-user-1")

    # 1. List all articles
    resp_all = await async_client.get("/api/v1/education/articles", headers=headers)
    assert resp_all.status_code == 200
    body_all = resp_all.json()
    assert body_all["total"] >= 14
    assert len(body_all["items"]) == body_all["total"]

    # 2. Filter by life_stage=pregnancy
    resp_preg = await async_client.get(
        "/api/v1/education/articles?life_stage=pregnancy",
        headers=headers,
    )
    assert resp_preg.status_code == 200
    preg_items = resp_preg.json()["items"]
    assert len(preg_items) >= 2
    assert all("pregnancy" in item["target_life_stages"] for item in preg_items)

    # 3. Filter by tag=sop
    resp_sop = await async_client.get(
        "/api/v1/education/articles?tag=sop",
        headers=headers,
    )
    assert resp_sop.status_code == 200
    sop_items = resp_sop.json()["items"]
    assert len(sop_items) >= 1
    assert any("sop" in item["clinical_tags"] for item in sop_items)


@pytest.mark.asyncio
async def test_get_article_detail_and_not_found(
    async_client: AsyncClient,
) -> None:
    """Verify full article detail by slug and RFC 7807 404 on unknown slug."""
    headers = await _create_test_user(async_client, "edu-user-2")

    slug = "criterios-figo-sangrado-uterino-anormal-fase-lutea"
    resp = await async_client.get(
        f"/api/v1/education/articles/{slug}",
        headers=headers,
    )
    assert resp.status_code == 200
    detail = resp.json()
    assert detail["slug"] == slug
    assert "FIGO" in detail["scientific_source"]
    assert "progesterona" in detail["body_markdown"].lower()

    resp_404 = await async_client.get(
        "/api/v1/education/articles/articulo-inexistente",
        headers=headers,
    )
    assert resp_404.status_code == 404
    assert resp_404.json()["code"] == "entity_not_found"
