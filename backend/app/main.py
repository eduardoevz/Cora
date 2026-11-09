from fastapi import APIRouter, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from app.core.config import Settings, get_settings
from app.core.errors import register_error_handlers


class HealthResponse(BaseModel):
    """Schema for basic application health check."""

    status: str = Field(..., examples=["healthy"])
    service: str = Field(..., examples=["cora-backend"])
    version: str = Field(..., examples=["0.1.0"])
    environment: str = Field(..., examples=["test"])


def create_app(settings: Settings | None = None) -> FastAPI:
    """FastAPI application factory for Cora Monolith."""
    current_settings = settings or get_settings()

    app = FastAPI(
        title=current_settings.app_name,
        version=current_settings.app_version,
        description=(
            "API REST para la plataforma Cora — Cuidado integral de la "
            "salud femenina en 7 etapas biológicas con arquitectura "
            "hexagonal y Spec-Driven Development."
        ),
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
    )

    # Middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Error Handlers
    register_error_handlers(app)

    # Core Routes
    api_router = APIRouter(prefix=current_settings.api_v1_prefix)

    # Bounded Context Routers
    from app.modules.clinical_tracking.infrastructure.entrypoints.cycle_router import (  # noqa: E501
        router as cycle_router,
    )
    from app.modules.clinical_tracking.infrastructure.entrypoints.fertility_router import (  # noqa: E501
        router as fertility_router,
    )
    from app.modules.clinical_tracking.infrastructure.entrypoints.wellness_router import (  # noqa: E501
        router as wellness_router,
    )
    from app.modules.identity.infrastructure.entrypoints.router import (
        router as identity_router,
    )
    from app.modules.treatments.infrastructure.entrypoints.treatment_router import (
        router as treatment_router,
    )

    api_router.include_router(identity_router)
    api_router.include_router(wellness_router)
    api_router.include_router(cycle_router)
    api_router.include_router(fertility_router)
    api_router.include_router(treatment_router)

    @api_router.get(
        "/health",
        response_model=HealthResponse,
        summary="Service Health Check",
        description="Verifica disponibilidad básica del servicio y versión desplegada.",
        tags=["System"],
    )
    async def health_check() -> HealthResponse:
        return HealthResponse(
            status="healthy",
            service="cora-backend",
            version=current_settings.app_version,
            environment=current_settings.environment,
        )

    app.include_router(api_router)

    return app


app = create_app()
