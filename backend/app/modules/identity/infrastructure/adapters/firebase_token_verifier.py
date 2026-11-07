import logging
from pathlib import Path
from typing import Any

from fastapi import HTTPException, status

from app.core.security import AuthenticatedUser
from app.modules.identity.application.ports.token_verifier_port import ITokenVerifier

logger = logging.getLogger(__name__)


class MockTokenVerifier(ITokenVerifier):
    """In-memory verifier for local testing without external Google/Firebase calls."""

    async def verify_token(self, token: str) -> AuthenticatedUser:
        if token.startswith("test-token:") or token.startswith("mock-token:"):
            parts = token.split(":")
            uid = parts[1] if len(parts) > 1 else "default-test-uid"
            email = parts[2] if len(parts) > 2 else f"{uid}@cora.test"
            return AuthenticatedUser(firebase_uid=uid, email=email)

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de autenticación de prueba inválido.",
            headers={"WWW-Authenticate": "Bearer"},
        )


class FirebaseTokenVerifier(ITokenVerifier):
    """Production token verification adapter using official Firebase Admin SDK."""

    def __init__(self, credentials_path: str, project_id: str) -> None:
        self._credentials_path = credentials_path
        self._project_id = project_id
        self._app: Any = None

    def _ensure_app_initialized(self) -> None:
        if self._app is not None:
            return

        try:
            import firebase_admin  # type: ignore[import-untyped]
            from firebase_admin import credentials

            creds_file = Path(self._credentials_path)
            if creds_file.exists():
                cred = credentials.Certificate(str(creds_file))
                self._app = firebase_admin.initialize_app(
                    cred, {"projectId": self._project_id}
                )
            else:
                # Fallback to default application credentials if running in GCP
                self._app = firebase_admin.initialize_app()
        except Exception as exc:
            logger.warning(
                "Could not initialize Firebase Admin SDK (%s). Fallback active.",
                exc,
            )

    async def verify_token(self, token: str) -> AuthenticatedUser:
        self._ensure_app_initialized()
        try:
            from firebase_admin import auth

            decoded_claims = auth.verify_id_token(token)
            uid = str(decoded_claims["uid"])
            email = decoded_claims.get("email")
            return AuthenticatedUser(firebase_uid=uid, email=email)
        except Exception as exc:
            logger.debug("Firebase token verification failed: %s", exc)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token de Firebase no válido o expirado.",
                headers={"WWW-Authenticate": "Bearer"},
            ) from exc
