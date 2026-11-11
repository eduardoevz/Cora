"""Unit tests for GeminiClinicalAssistantAdapter (store=False) and RAG UseCase."""

import json
from uuid import uuid4

import pytest
from app.modules.rag_assistant.application.use_cases.assistant_use_cases import (
    AskClinicalAssistantUseCase,
)
from app.modules.rag_assistant.domain.entities import (
    AssembledClinicalMemory,
    AssistantConversation,
    AssistantMessage,
)
from app.modules.rag_assistant.domain.services.safety_interceptor import (
    DeterministicSafetyInterceptor,
)
from app.modules.rag_assistant.infrastructure.adapters import (
    gemini_assistant_adapter,
)

from app.modules.education_content.domain.entities import ClinicalEvidenceChunk


def test_gemini_assistant_adapter_enforces_gemini_3_8_flash_and_store_false() -> None:
    """Verify interactions.create is called with gemini-3.8-flash and store=False."""
    captured_kwargs: list[dict[str, object]] = []

    class FakeInteractionOutput:
        def __init__(self, text: str) -> None:
            self.text = text

    class FakeInteractionsResource:
        def create(self, **kwargs: object) -> FakeInteractionOutput:
            captured_kwargs.append(kwargs)
            payload = {
                "answer_markdown": (
                    "Durante la **fase lútea tardía** (días 24 a 28), el descenso de "
                    "estradiol y progesterona puede asociarse a cefalea premenstrual "
                    "[1]. Te sugerimos compartir este patrón con tu ginecóloga."
                ),
                "cited_chunk_indices": [1],
                "disclaimer_level": "STANDARD",
                "suggested_follow_ups": [
                    "¿Qué hábitos ayudan a aliviar la cefalea premenstrual?",
                    "¿Cómo preparo mi reporte PDF para consulta médica?",
                ],
            }
            return FakeInteractionOutput(json.dumps(payload))

    class FakeGenaiClient:
        def __init__(self) -> None:
            self.interactions = FakeInteractionsResource()

    adapter = gemini_assistant_adapter.GeminiClinicalAssistantAdapter(
        client=FakeGenaiClient(),
        model_name="gemini-3.8-flash",
    )

    memory = AssembledClinicalMemory(
        life_stage="regular_adult",
        age_years=30,
        diagnosed_conditions=[],
        hormonal_method="none",
        cycle_summary="Ciclo medio 28 días, día actual 27 (fase lútea).",
        detected_correlations=[
            "Patrón recurrente de 'cefalea' observado entre los días 26 y 28 "
            "del ciclo en 3 ciclos registrados."
        ],
        active_treatments=[],
        stage_specific_summary="",
    )
    chunk = ClinicalEvidenceChunk(
        id=uuid4(),
        article_id=uuid4(),
        chunk_index=0,
        section_heading="Fase Lútea Tardía y Cefalea Catamenial",
        content_text="El descenso brusco de estrógenos explica la cefalea premenstrual.",
        token_count=45,
        target_life_stages=["regular_adult"],
        scientific_source="FIGO Menstrual Disorders Committee",
        article_title="Fisiología del Ciclo Menstrual Adulto y Criterios FIGO",
        article_slug="criterios-figo-sangrado-uterino-anormal-fase-lutea",
        source_url="https://www.figo.org/",
        similarity_score=0.92,
    )

    result = adapter.generate_grounded_answer(
        user_query="¿Por qué me duele la cabeza siempre en el día 27 de mi ciclo?",
        clinical_memory=memory,
        evidence_chunks=[chunk],
    )

    assert len(captured_kwargs) == 1
    call = captured_kwargs[0]
    assert call["model"] == "gemini-3.8-flash"
    assert call["store"] is False
    assert call["response_mime_type"] == "application/json"
    assert "fase lútea tardía" in result.answer_markdown
    assert len(result.citations) == 1
    assert result.citations[0].article_slug == chunk.article_slug


@pytest.mark.asyncio
async def test_emergency_query_makes_zero_calls_to_gemini_llm() -> None:
    """Verify red flag emergency cuts execution in Stage 1 with 0 calls to Gemini."""
    llm_calls = 0

    class SpyAssistantGenerator:
        def generate_grounded_answer(
            self,
            *,
            user_query: str,
            clinical_memory: AssembledClinicalMemory,
            evidence_chunks: list[ClinicalEvidenceChunk],
        ) -> object:
            nonlocal llm_calls
            llm_calls += 1
            raise AssertionError("Gemini LLM must NEVER be called on emergencies!")

    class FakeEvidenceRetrieval:
        async def retrieve_top_k_chunks(
            self,
            query_text: str,
            life_stage: str | None = None,
            top_k: int = 5,
        ) -> list[ClinicalEvidenceChunk]:
            return []

    class InMemoryAssistantRepo:
        def __init__(self) -> None:
            self.conversations: dict[object, AssistantConversation] = {}
            self.messages: list[AssistantMessage] = []

        async def create_conversation(
            self, conversation: AssistantConversation
        ) -> AssistantConversation:
            self.conversations[conversation.id] = conversation
            return conversation

        async def get_conversation(
            self, conversation_id: object, user_id: object
        ) -> AssistantConversation | None:
            conv = self.conversations.get(conversation_id)
            if conv and conv.user_id == user_id:
                return conv
            return None

        async def list_conversations(
            self, user_id: object
        ) -> list[AssistantConversation]:
            return [c for c in self.conversations.values() if c.user_id == user_id]

        async def append_message(self, message: AssistantMessage) -> AssistantMessage:
            self.messages.append(message)
            return message

        async def list_messages(
            self, conversation_id: object, user_id: object
        ) -> list[AssistantMessage]:
            return [m for m in self.messages if m.conversation_id == conversation_id]

    repo = InMemoryAssistantRepo()
    user_id = uuid4()
    conv = AssistantConversation(
        id=uuid4(),
        user_id=user_id,
        title="Consulta de embarazo",
        life_stage_at_creation="pregnancy",
    )
    await repo.create_conversation(conv)

    memory = AssembledClinicalMemory(
        life_stage="pregnancy",
        age_years=29,
        diagnosed_conditions=[],
        hormonal_method="none",
        cycle_summary="Embarazo activo (28 semanas).",
        detected_correlations=[],
        active_treatments=[],
        stage_specific_summary="28 semanas de gestación.",
    )

    use_case = AskClinicalAssistantUseCase(
        repository=repo,
        safety_interceptor=DeterministicSafetyInterceptor(),
        evidence_retriever=FakeEvidenceRetrieval(),
        llm_generator=SpyAssistantGenerator(),  # type: ignore[arg-type]
    )

    assistant_msg = await use_case.execute(
        user_id=user_id,
        conversation_id=conv.id,
        query_text="Tengo 28 semanas de embarazo, dolor de cabeza fuerte y veo luces",
        clinical_memory=memory,
    )

    assert llm_calls == 0
    assert assistant_msg.is_emergency_intercepted is True
    assert assistant_msg.safety_triage_category == "OBSTETRIC_PREECLAMPSIA_EMERGENCY"
    assert assistant_msg.disclaimer_level == "EMERGENCY_URGENT"
