"""SQLAlchemy 2.0 ORM models for RAG Assistant conversations and messages."""

from datetime import UTC, datetime
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import JSON, Boolean, DateTime, ForeignKey, Index, String, Text, Uuid
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.modules.rag_assistant.domain.entities import (
    AssistantConversation,
    AssistantMessage,
    ClinicalCitation,
)

JSONVariant = JSON().with_variant(JSONB(), "postgresql")


class AssistantConversationORM(Base):
    """ORM model for assistant_conversations table."""

    __tablename__ = "assistant_conversations"

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid4
    )
    user_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("user_profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    life_stage_at_creation: Mapped[str] = mapped_column(String(60), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )

    messages: Mapped[list["AssistantMessageORM"]] = relationship(
        "AssistantMessageORM",
        back_populates="conversation",
        cascade="all, delete-orphan",
    )

    def to_domain(self) -> AssistantConversation:
        created = self.created_at
        if created.tzinfo is None:
            created = created.replace(tzinfo=UTC)
        updated = self.updated_at
        if updated.tzinfo is None:
            updated = updated.replace(tzinfo=UTC)
        return AssistantConversation(
            id=self.id,
            user_id=self.user_id,
            title=self.title,
            life_stage_at_creation=self.life_stage_at_creation,
            created_at=created,
            updated_at=updated,
        )


class AssistantMessageORM(Base):
    """ORM model for assistant_messages table."""

    __tablename__ = "assistant_messages"

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid4
    )
    conversation_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("assistant_conversations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    role: Mapped[str] = mapped_column(String(20), nullable=False)
    content_markdown: Mapped[str] = mapped_column(Text, nullable=False)
    citations: Mapped[list[dict[str, Any]]] = mapped_column(
        JSONVariant, nullable=False, default=list
    )
    safety_triage_category: Mapped[str] = mapped_column(
        String(60), nullable=False, default="NONE"
    )
    is_emergency_intercepted: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    disclaimer_level: Mapped[str] = mapped_column(
        String(40), nullable=False, default="STANDARD"
    )
    suggested_follow_ups: Mapped[list[str]] = mapped_column(
        JSONVariant, nullable=False, default=list
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )

    conversation: Mapped[AssistantConversationORM] = relationship(
        "AssistantConversationORM",
        back_populates="messages",
    )

    __table_args__ = (
        Index(
            "ix_assistant_messages_conversation_created",
            "conversation_id",
            "created_at",
        ),
    )

    def to_domain(self) -> AssistantMessage:
        created = self.created_at
        if created.tzinfo is None:
            created = created.replace(tzinfo=UTC)
        domain_citations = [
            ClinicalCitation(
                article_id=UUID(str(c["article_id"])),
                article_slug=str(c["article_slug"]),
                article_title=str(c["article_title"]),
                section_heading=str(c["section_heading"]),
                scientific_source=str(c["scientific_source"]),
                source_url=str(c["source_url"]),
            )
            for c in (self.citations or [])
        ]
        return AssistantMessage(
            id=self.id,
            conversation_id=self.conversation_id,
            role=self.role,
            content_markdown=self.content_markdown,
            citations=domain_citations,
            safety_triage_category=self.safety_triage_category,
            is_emergency_intercepted=self.is_emergency_intercepted,
            disclaimer_level=self.disclaimer_level,
            suggested_follow_ups=list(self.suggested_follow_ups or []),
            created_at=created,
        )
