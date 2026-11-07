import uuid
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import JSON, DateTime, Integer, String, Uuid, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class IdempotentMutation(Base):
    """Stores executed mutations identified by client mutation UUID to ensure
    idempotency across retries.
    """

    __tablename__ = "idempotent_mutations"

    user_id: Mapped[uuid.UUID] = mapped_column(Uuid(as_uuid=True), primary_key=True)
    client_mutation_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True
    )
    endpoint: Mapped[str] = mapped_column(String(255), nullable=False)
    request_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    response_status: Mapped[int] = mapped_column(Integer, nullable=False)
    response_body: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )


@dataclass(frozen=True)
class CachedMutationResponse:
    """Cached response for an idempotent mutation previously processed."""

    client_mutation_id: uuid.UUID
    response_status: int
    response_body: dict[str, Any]


class IdempotencyStore:
    """Service to check and store mutation idempotency records."""

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_cached_response(
        self, user_id: uuid.UUID, client_mutation_id: uuid.UUID
    ) -> CachedMutationResponse | None:
        """Retrieve previous response if mutation was already processed."""
        stmt = select(IdempotentMutation).where(
            IdempotentMutation.user_id == user_id,
            IdempotentMutation.client_mutation_id == client_mutation_id,
        )
        result = await self.session.execute(stmt)
        record = result.scalar_one_or_none()

        if record is None:
            return None

        return CachedMutationResponse(
            client_mutation_id=record.client_mutation_id,
            response_status=record.response_status,
            response_body=record.response_body,
        )

    async def record_response(
        self,
        user_id: uuid.UUID,
        client_mutation_id: uuid.UUID,
        endpoint: str,
        request_hash: str,
        response_status: int,
        response_body: dict[str, Any],
    ) -> None:
        """Store executed mutation response."""
        record = IdempotentMutation(
            user_id=user_id,
            client_mutation_id=client_mutation_id,
            endpoint=endpoint,
            request_hash=request_hash,
            response_status=response_status,
            response_body=response_body,
            created_at=datetime.now(UTC),
        )
        self.session.add(record)
        await self.session.commit()
