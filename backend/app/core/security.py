from dataclasses import dataclass
from typing import TYPE_CHECKING, Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

if TYPE_CHECKING:
    from app.modules.identity.application.ports.token_verifier_port import (
        ITokenVerifier,
    )


@dataclass(frozen=True)
class AuthenticatedUser:
    """Identity claims extracted from validated authentication tokens."""

    firebase_uid: str
    email: str | None = None


_bearer_scheme = HTTPBearer(auto_error=False)


def get_token_verifier() -> "ITokenVerifier":
    """Factory dependency returning the active token verification adapter."""
    from app.core.config import get_settings
    from app.modules.identity.infrastructure.adapters.firebase_token_verifier import (
        FirebaseTokenVerifier,
        MockTokenVerifier,
    )

    settings = get_settings()
    if settings.environment in {"test", "testing"}:
        return MockTokenVerifier()

    return FirebaseTokenVerifier(
        credentials_path=settings.firebase_credentials_path,
        project_id=settings.firebase_project_id,
        credentials_json=settings.firebase_credentials_json,
    )


async def get_current_user(
    credentials: Annotated[
        HTTPAuthorizationCredentials | None, Depends(_bearer_scheme)
    ],
    verifier: Annotated["ITokenVerifier", Depends(get_token_verifier)],
) -> AuthenticatedUser:
    """FastAPI dependency resolving the authenticated user from the Bearer token."""
    if credentials is None or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de autenticación faltante o inválido.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return await verifier.verify_token(credentials.credentials)


CurrentUserDep = Annotated[AuthenticatedUser, Depends(get_current_user)]
