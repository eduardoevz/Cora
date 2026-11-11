"""Pydantic v2 request and response schemas for the Clinical RAG Assistant."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.modules.rag_assistant.domain.entities import (
    AssistantConversation,
    AssistantMessage,
    ClinicalCitation,
)


class CreateConversationRequest(BaseModel):
    """Payload to start a new clinical assistant conversation."""

    client_mutation_id: UUID | None = None
    title: str = Field(
        default="Consulta con Cora",
        min_length=1,
        max_length=200,
    )


class ConversationResponse(BaseModel):
    """Representation of a clinical assistant conversation thread."""

    id: UUID
    title: str
    life_stage_at_creation: str
    created_at: datetime
    updated_at: datetime

    @classmethod
    def from_domain(cls, conv: AssistantConversation) -> "ConversationResponse":
        return cls(
            id=conv.id,
            title=conv.title,
            life_stage_at_creation=conv.life_stage_at_creation,
            created_at=conv.created_at,
            updated_at=conv.updated_at,
        )


class ConversationListResponse(BaseModel):
    """Envelope for assistant conversations."""

    items: list[ConversationResponse]
    total: int


class ClinicalCitationResponse(BaseModel):
    """Verifiable scientific citation returned with an assistant message."""

    article_id: UUID
    article_slug: str
    article_title: str
    section_heading: str
    scientific_source: str
    source_url: str

    @classmethod
    def from_domain(cls, cit: ClinicalCitation) -> "ClinicalCitationResponse":
        return cls(
            article_id=cit.article_id,
            article_slug=cit.article_slug,
            article_title=cit.article_title,
            section_heading=cit.section_heading,
            scientific_source=cit.scientific_source,
            source_url=cit.source_url,
        )


class SendAssistantMessageRequest(BaseModel):
    """Payload to send a question to Cora's grounded clinical RAG assistant."""

    client_mutation_id: UUID | None = None
    query: str = Field(
        ...,
        min_length=2,
        max_length=2000,
        description="Pregunta clínica o educativa de la usuaria",
    )


class AssistantMessageResponse(BaseModel):
    """Representation of a user or assistant turn with citations and safety flags."""

    id: UUID
    conversation_id: UUID
    role: str
    content_markdown: str
    citations: list[ClinicalCitationResponse]
    safety_triage_category: str
    is_emergency_intercepted: bool
    disclaimer_level: str
    suggested_follow_ups: list[str]
    created_at: datetime

    @classmethod
    def from_domain(cls, msg: AssistantMessage) -> "AssistantMessageResponse":
        return cls(
            id=msg.id,
            conversation_id=msg.conversation_id,
            role=msg.role,
            content_markdown=msg.content_markdown,
            citations=[ClinicalCitationResponse.from_domain(c) for c in msg.citations],
            safety_triage_category=msg.safety_triage_category,
            is_emergency_intercepted=msg.is_emergency_intercepted,
            disclaimer_level=msg.disclaimer_level,
            suggested_follow_ups=msg.suggested_follow_ups,
            created_at=msg.created_at,
        )


class AssistantMessageListResponse(BaseModel):
    """Chronological list of messages in a conversation."""

    items: list[AssistantMessageResponse]
    total: int
