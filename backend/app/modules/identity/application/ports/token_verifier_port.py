from typing import Protocol

from app.core.security import AuthenticatedUser


class ITokenVerifier(Protocol):
    """Port for verifying client authentication tokens."""

    async def verify_token(self, token: str) -> AuthenticatedUser:
        """Verify raw Bearer token and extract authenticated user identity."""
        ...
