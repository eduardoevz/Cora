"""Application use cases for the 4-stage Clinical RAG Assistant."""

from uuid import UUID

from app.modules.education_content.application.ports.education_ports import (
    EvidenceRetrievalPort,
)
from app.modules.rag_assistant.application.ports.assistant_ports import (
    AssistantRepositoryPort,
    ClinicalAssistantGeneratorPort,
)
from app.modules.rag_assistant.domain.entities import (
    AssembledClinicalMemory,
    AssistantConversation,
    AssistantMessage,
)
from app.modules.rag_assistant.domain.services.safety_interceptor import (
    DeterministicSafetyInterceptor,
)


class CreateAssistantConversationUseCase:
    """Create a new clinical assistant conversation thread."""

    def __init__(self, repository: AssistantRepositoryPort) -> None:
        self._repository = repository

    async def execute(
        self,
        user_id: UUID,
        title: str,
        life_stage: str,
    ) -> AssistantConversation:
        clean_title = title.strip() or "Consulta con Cora"
        conversation = AssistantConversation(
            user_id=user_id,
            title=clean_title,
            life_stage_at_creation=life_stage,
        )
        return await self._repository.create_conversation(conversation)


class ListAssistantConversationsUseCase:
    """List conversation threads belonging to a user."""

    def __init__(self, repository: AssistantRepositoryPort) -> None:
        self._repository = repository

    async def execute(self, user_id: UUID) -> list[AssistantConversation]:
        return await self._repository.list_conversations(user_id=user_id)


class ListConversationMessagesUseCase:
    """List chronological messages inside a user's conversation."""

    def __init__(self, repository: AssistantRepositoryPort) -> None:
        self._repository = repository

    async def execute(
        self,
        conversation_id: UUID,
        user_id: UUID,
    ) -> list[AssistantMessage]:
        return await self._repository.list_messages(
            conversation_id=conversation_id,
            user_id=user_id,
        )


class AskClinicalAssistantUseCase:
    """Orchestrates the 4-stage clinical RAG pipeline with safety-first triage."""

    def __init__(
        self,
        repository: AssistantRepositoryPort,
        safety_interceptor: DeterministicSafetyInterceptor,
        evidence_retriever: EvidenceRetrievalPort,
        llm_generator: ClinicalAssistantGeneratorPort,
    ) -> None:
        self._repository = repository
        self._safety_interceptor = safety_interceptor
        self._evidence_retriever = evidence_retriever
        self._llm_generator = llm_generator

    async def execute(
        self,
        *,
        user_id: UUID,
        conversation_id: UUID,
        query_text: str,
        clinical_memory: AssembledClinicalMemory,
    ) -> AssistantMessage:
        """Run Stage 1 -> Stage 2 -> Stage 3 -> Stage 4 and persist both turns."""
        # Persist user turn first
        user_turn = AssistantMessage(
            conversation_id=conversation_id,
            role="user",
            content_markdown=query_text.strip(),
        )
        await self._repository.append_message(user_turn)

        # Stage 1: Deterministic Safety Interceptor (< 5ms, 0 LLM calls on match)
        triage = self._safety_interceptor.evaluate(
            query_text=query_text,
            life_stage=clinical_memory.life_stage,
        )
        if triage.is_emergency:
            emergency_turn = AssistantMessage(
                conversation_id=conversation_id,
                role="assistant",
                content_markdown=triage.urgent_response_markdown,
                citations=[],
                safety_triage_category=triage.category.value,
                is_emergency_intercepted=True,
                disclaimer_level=triage.disclaimer_level,
                suggested_follow_ups=[],
            )
            return await self._repository.append_message(emergency_turn)

        # Stage 2: Retrieve Top-5 clinical evidence chunks prioritized by stage
        chunks = await self._evidence_retriever.retrieve_top_k_chunks(
            query_text=query_text,
            life_stage=clinical_memory.life_stage,
            top_k=5,
        )

        # Stage 3 & 4: Grounded Generation with Gemini 3.8 Flash (store=False)
        generated = self._llm_generator.generate_grounded_answer(
            user_query=query_text,
            clinical_memory=clinical_memory,
            evidence_chunks=chunks,
        )

        assistant_turn = AssistantMessage(
            conversation_id=conversation_id,
            role="assistant",
            content_markdown=generated.answer_markdown,
            citations=generated.citations,
            safety_triage_category="NONE",
            is_emergency_intercepted=False,
            disclaimer_level=generated.disclaimer_level,
            suggested_follow_ups=generated.suggested_follow_ups,
        )
        return await self._repository.append_message(assistant_turn)
