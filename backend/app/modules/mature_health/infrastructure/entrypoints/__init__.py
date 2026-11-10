"""Entrypoints package for mature health."""

from app.modules.mature_health.infrastructure.entrypoints.mature_health_router import (
    router,
)

__all__ = ["router"]
