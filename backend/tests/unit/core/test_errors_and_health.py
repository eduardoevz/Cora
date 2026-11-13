import pytest
from httpx import ASGITransport, AsyncClient

from app.core.config import Settings, get_settings
from app.core.errors import DomainError
from app.main import create_app


@pytest.mark.asyncio
async def test_health_check_returns_healthy_status() -> None:
    app = create_app()
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.get("/api/v1/health")

    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "healthy"
    assert payload["service"] == "cora-backend"
    assert "version" in payload


def test_settings_load_defaults_in_test_environment() -> None:
    settings = get_settings()
    assert isinstance(settings, Settings)
    assert settings.app_name == "Cora Backend"
    assert settings.environment in {"development", "test", "production"}


def test_database_url_normalization() -> None:
    s1 = Settings(database_url="postgres://user:pass@localhost:5432/db")
    assert s1.database_url.startswith("postgresql+asyncpg://")

    s2 = Settings(database_url="postgresql://user:pass@localhost:5432/db")
    assert s2.database_url.startswith("postgresql+asyncpg://")

    s3 = Settings(database_url="postgresql+asyncpg://user:pass@localhost:5432/db")
    assert s3.database_url == "postgresql+asyncpg://user:pass@localhost:5432/db"


@pytest.mark.asyncio
async def test_domain_error_is_serialized_as_rfc7807_problem_details() -> None:
    app = create_app()

    @app.get("/test-domain-error")
    async def trigger_domain_error() -> None:
        raise DomainError(
            code="invalid_vital_range",
            title="Invalid Vital Range",
            detail="Blood pressure systolic must be strictly greater than diastolic.",
            status_code=422,
        )

    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.get("/test-domain-error")

    assert response.status_code == 422
    assert response.headers["content-type"] == "application/problem+json"
    problem = response.json()
    assert problem["type"] == "urn:cora:error:invalid_vital_range"
    assert problem["title"] == "Invalid Vital Range"
    assert (
        problem["detail"]
        == "Blood pressure systolic must be strictly greater than diastolic."
    )
    assert problem["status"] == 422
    assert problem["code"] == "invalid_vital_range"
