"""FastAPI router for the Clinical RAG Assistant (/api/v1/assistant)."""

from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.database import get_async_session
from app.core.errors import EntityNotFoundError
from app.core.security import CurrentUserDep
from app.modules.clinical_tracking.infrastructure.adapters import (
    postgres_cycle_repository,
    postgres_wellness_repository,
)
from app.modules.education_content.infrastructure.adapters import (
    gemini_embedding_adapter,
    postgres_education_repository,
)
from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.identity.infrastructure.adapters import (
    postgres_user_profile_repository,
)
from app.modules.rag_assistant.application.use_cases.assistant_use_cases import (
    AskClinicalAssistantUseCase,
    CreateAssistantConversationUseCase,
    ListAssistantConversationsUseCase,
    ListConversationMessagesUseCase,
)
from app.modules.rag_assistant.domain.entities import AssembledClinicalMemory
from app.modules.rag_assistant.domain.services.clinical_memory_assembler import (
    CycleDaySymptomPoint,
    RawUserClinicalSnapshot,
    UserClinicalMemoryAssembler,
)
from app.modules.rag_assistant.domain.services.safety_interceptor import (
    DeterministicSafetyInterceptor,
)
from app.modules.rag_assistant.infrastructure.adapters import (
    gemini_assistant_adapter,
    postgres_assistant_repository,
)
from app.modules.rag_assistant.infrastructure.entrypoints.schemas import (
    AssistantMessageListResponse,
    AssistantMessageResponse,
    ConversationListResponse,
    ConversationResponse,
    CreateConversationRequest,
    SendAssistantMessageRequest,
)
from app.modules.treatments.infrastructure.adapters import (
    postgres_treatment_repository,
)

router = APIRouter(prefix="/assistant", tags=["Clinical RAG Assistant"])


async def get_current_user_profile(
    current_user: CurrentUserDep,
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> UserProfile:
    """Resolve authenticated UserProfile from Firebase UID."""
    repo = postgres_user_profile_repository.PostgresUserProfileRepository(session)
    profile = await repo.get_by_firebase_uid(current_user.firebase_uid)
    if profile is None:
        raise EntityNotFoundError("UserProfile", current_user.firebase_uid)
    return profile


async def _assemble_user_clinical_memory(
    profile: UserProfile,
    session: AsyncSession,
) -> AssembledClinicalMemory:
    """Assemble PII-free longitudinal clinical context for profile."""
    user_id = profile.id
    life_stage = profile.current_life_stage.value
    birth_year = (
        profile.onboarding_context.birth_year
        if profile.onboarding_context and profile.onboarding_context.birth_year
        else 1995
    )
    diagnosed_conditions = [
        str(c) for c in (profile.onboarding_context.diagnosed_conditions or [])
    ]
    hormonal_method = (
        profile.onboarding_context.hormonal_method.value
        if profile.onboarding_context
        and profile.onboarding_context.hormonal_method is not None
        else "none"
    )

    cycle_repo = postgres_cycle_repository.PostgresCycleRepository(session)
    cycles = await cycle_repo.list_cycles(str(user_id), limit=6)
    closed_lengths = [
        c.cycle_length_days for c in cycles if c.cycle_length_days is not None
    ]
    current_cycle_day: int | None = None
    if cycles and cycles[0].end_date is None:
        today = datetime.now(UTC).date()
        delta = (today - cycles[0].start_date).days + 1
        if 1 <= delta <= 90:
            current_cycle_day = delta

    wellness_repo = postgres_wellness_repository.PostgresWellnessRepository(session)
    logs = await wellness_repo.get_history(
        user_id=str(user_id),
        start_date=datetime(2020, 1, 1, tzinfo=UTC).date(),
        end_date=datetime.now(UTC).date(),
    )
    symptom_points: list[CycleDaySymptomPoint] = []
    for idx, cyc in enumerate(cycles[:4], start=1):
        for log in logs:
            if cyc.start_date <= log.log_date and (
                cyc.end_date is None or log.log_date <= cyc.end_date
            ):
                c_day = (log.log_date - cyc.start_date).days + 1
                for tag in log.mood_tags:
                    symptom_points.append(
                        CycleDaySymptomPoint(
                            cycle_index=idx,
                            cycle_day=c_day,
                            symptom=str(tag.value),
                        )
                    )

    treatment_repo = postgres_treatment_repository.PostgresTreatmentRepository(session)
    regimens = await treatment_repo.get_regimens(str(user_id))
    active_treatments = [f"{r.name} ({r.dosage})" for r in regimens if r.is_active]

    snapshot = RawUserClinicalSnapshot(
        first_name=profile.first_name,
        last_name=profile.last_name,
        email="",
        birth_year=birth_year,
        current_life_stage=life_stage,
        diagnosed_conditions=diagnosed_conditions,
        hormonal_method=hormonal_method,
        recent_cycle_lengths=closed_lengths,
        current_cycle_day=current_cycle_day,
        symptom_points=symptom_points,
        active_treatments=active_treatments,
    )
    assembler = UserClinicalMemoryAssembler()
    return assembler.assemble(snapshot)


@router.post(
    "/conversations",
    response_model=ConversationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Crear una nueva conversación con el asistente clínico Cora",
)
async def create_conversation(
    payload: CreateConversationRequest,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> ConversationResponse:
    """Create a new clinical assistant conversation thread."""
    repo = postgres_assistant_repository.PostgresAssistantRepository(session)
    use_case = CreateAssistantConversationUseCase(repository=repo)
    conv = await use_case.execute(
        user_id=profile.id,
        title=payload.title,
        life_stage=profile.current_life_stage.value,
    )
    return ConversationResponse.from_domain(conv)


@router.get(
    "/conversations",
    response_model=ConversationListResponse,
    summary="Listar conversaciones del asistente clínico de la usuaria",
)
async def list_conversations(
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> ConversationListResponse:
    """List all assistant conversations owned by the authenticated user."""
    repo = postgres_assistant_repository.PostgresAssistantRepository(session)
    use_case = ListAssistantConversationsUseCase(repository=repo)
    convs = await use_case.execute(user_id=profile.id)
    items = [ConversationResponse.from_domain(c) for c in convs]
    return ConversationListResponse(items=items, total=len(items))


@router.get(
    "/conversations/{conversation_id}/messages",
    response_model=AssistantMessageListResponse,
    summary="Obtener historial de mensajes y citas de una conversación",
)
async def list_conversation_messages(
    conversation_id: UUID,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> AssistantMessageListResponse:
    """Return chronological messages in a conversation owned by the user."""
    repo = postgres_assistant_repository.PostgresAssistantRepository(session)
    conv = await repo.get_conversation(conversation_id, profile.id)
    if conv is None:
        raise EntityNotFoundError(
            entity="AssistantConversation", identifier=str(conversation_id)
        )
    use_case = ListConversationMessagesUseCase(repository=repo)
    msgs = await use_case.execute(
        conversation_id=conversation_id,
        user_id=profile.id,
    )
    items = [AssistantMessageResponse.from_domain(m) for m in msgs]
    return AssistantMessageListResponse(items=items, total=len(items))


@router.post(
    "/conversations/{conversation_id}/messages",
    response_model=AssistantMessageResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Enviar consulta al pipeline RAG clínico de 4 etapas",
)
async def send_assistant_message(
    conversation_id: UUID,
    payload: SendAssistantMessageRequest,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> AssistantMessageResponse:
    """Execute 4-stage clinical RAG pipeline (Safety -> Memory/Vector -> Gemini)."""
    repo = postgres_assistant_repository.PostgresAssistantRepository(session)
    conv = await repo.get_conversation(conversation_id, profile.id)
    if conv is None:
        raise EntityNotFoundError(
            entity="AssistantConversation", identifier=str(conversation_id)
        )

    settings = get_settings()
    embedder = gemini_embedding_adapter.GeminiEmbeddingAdapter(
        api_key=settings.gemini_api_key,
        model_name=settings.gemini_embedding_model,
        dimensions=settings.gemini_embedding_dimensions,
    )
    edu_repo = postgres_education_repository.PostgresEducationRepository(
        session=session,
        embedding_generator=embedder,
    )
    llm_adapter = gemini_assistant_adapter.GeminiClinicalAssistantAdapter(
        api_key=settings.gemini_api_key,
        model_name=settings.gemini_generation_model,
    )

    clinical_memory = await _assemble_user_clinical_memory(
        profile=profile,
        session=session,
    )

    use_case = AskClinicalAssistantUseCase(
        repository=repo,
        safety_interceptor=DeterministicSafetyInterceptor(),
        evidence_retriever=edu_repo,
        llm_generator=llm_adapter,
    )
    assistant_msg = await use_case.execute(
        user_id=profile.id,
        conversation_id=conversation_id,
        query_text=payload.query,
        clinical_memory=clinical_memory,
    )
    return AssistantMessageResponse.from_domain(assistant_msg)
