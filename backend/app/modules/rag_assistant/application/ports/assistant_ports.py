"""Application ports for the RAG Assistant bounded context."""

from typing import Protocol
from uuid import UUID

from app.modules.education_content.domain.entities import ClinicalEvidenceChunk
from app.modules.rag_assistant.domain.entities import (
    AssembledClinicalMemory,
    AssistantConversation,
    AssistantMessage,
    GroundedAssistantResult,
)


class ClinicalAssistantGeneratorPort(Protocol):
    """Port for generating grounded clinical answers with citations."""

    def generate_grounded_answer(
        self,
        *,
        user_query: str,
        clinical_memory: AssembledClinicalMemory,
        evidence_chunks: list[ClinicalEvidenceChunk],
    ) -> GroundedAssistantResult:
        """Generate grounded clinical answer from memory and retrieved chunks."""
        ...


class AssistantRepositoryPort(Protocol):
    """Port for persisting and retrieving RAG conversations and messages."""

    async def create_conversation(
        self, conversation: AssistantConversation
    ) -> AssistantConversation:
        """Persist a new AssistantConversation."""
        ...

    async def get_conversation(
        self, conversation_id: UUID, user_id: UUID
    ) -> AssistantConversation | None:
        """Retrieve a conversation owned by user_id."""
        ...

    async def list_conversations(self, user_id: UUID) -> list[AssistantConversation]:
        """List all conversations for user_id ordered by updated_at desc."""
        ...

    async def append_message(self, message: AssistantMessage) -> AssistantMessage:
        """Persist a new message turn in a conversation."""
        ...

    async def list_messages(
        self, conversation_id: UUID, user_id: UUID
    ) -> list[AssistantMessage]:
        """List all messages in a conversation ordered chronologically."""
        ...
