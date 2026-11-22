from typing import cast

from fastapi.middleware.cors import CORSMiddleware
from fastapi.testclient import TestClient

from app.core.config import Settings
from app.main import create_app


def test_health_endpoint_includes_security_headers() -> None:
    app = create_app(Settings())
    client = TestClient(app)

    response = client.get("/api/v1/health")

    assert response.status_code == 200
    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["x-frame-options"] == "DENY"
    assert response.headers["referrer-policy"] == "no-referrer"
    assert (
        response.headers["permissions-policy"]
        == "camera=(), microphone=(), geolocation=()"
    )


def test_settings_parses_comma_separated_cors_origins() -> None:
    settings = Settings(
        cors_allowed_origins="https://app.cora.health, https://admin.cora.health",  # type: ignore[arg-type]
    )

    assert settings.cors_allowed_origins == [
        "https://app.cora.health",
        "https://admin.cora.health",
    ]


def test_create_app_never_combines_wildcard_cors_with_credentials() -> None:
    app = create_app(Settings(cors_allowed_origins=["*"]))
    cors_middleware = next(
        m for m in app.user_middleware if cast(object, m.cls) is CORSMiddleware
    )

    assert cors_middleware.kwargs["allow_origins"] == ["*"]
    assert cors_middleware.kwargs["allow_credentials"] is False
