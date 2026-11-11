import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_async_session
from app.core.errors import EntityNotFoundError
from app.core.security import CurrentUserDep
from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.identity.infrastructure.adapters.postgres_user_profile_repository import (  # noqa: E501
    PostgresUserProfileRepository,
)
from app.modules.maternal_care.application.dtos.pregnancy_dtos import (
    CreatePregnancyEpisodeDTO,
    CreatePrenatalAppointmentDTO,
    LogContractionSessionDTO,
    LogKickSessionDTO,
    LogMaternalVitalsDTO,
    SaveBirthPlanDTO,
)
from app.modules.maternal_care.application.use_cases.pregnancy_use_cases import (
    CreatePregnancyEpisodeUseCase,
    GetActivePregnancySummaryUseCase,
    LogMaternalVitalsUseCase,
    ManageBirthPlanUseCase,
    ManagePrenatalAppointmentsUseCase,
    RecordContractionSessionUseCase,
    RecordKickSessionUseCase,
)
from app.modules.maternal_care.domain.services.contraction_and_kick_analyzer import (  # noqa: E501
    ContractionAndKickAnalyzer,
)
from app.modules.maternal_care.domain.services.fetal_weekly_milestones_catalog import (  # noqa: E501
    FetalWeeklyMilestonesCatalog,
)
from app.modules.maternal_care.domain.services.maternal_risk_evaluator import (
    MaternalRiskEvaluator,
)
from app.modules.maternal_care.infrastructure.adapters.postgres_pregnancy_repository import (  # noqa: E501
    PostgresPregnancyRepository,
)
from app.modules.maternal_care.infrastructure.entrypoints.pregnancy_schemas import (  # noqa: E501
    BirthPlanRequest,
    BirthPlanResponse,
    ContractionSessionResponse,
    CreatePregnancyEpisodeRequest,
    CreatePrenatalAppointmentRequest,
    FetalMilestoneResponse,
    KickSessionResponse,
    LogContractionSessionRequest,
    LogKickSessionRequest,
    LogMaternalVitalsRequest,
    MaternalVitalsResponse,
    PregnancyEpisodeResponse,
    PregnancySummaryResponse,
    PrenatalAppointmentResponse,
    ToggleAppointmentRequest,
)

router = APIRouter(prefix="/pregnancy", tags=["Maternal Care & Pregnancy"])


async def get_current_user_profile(
    current_user: CurrentUserDep,
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> UserProfile:
    repo = PostgresUserProfileRepository(session)
    profile = await repo.get_by_firebase_uid(current_user.firebase_uid)
    if profile is None:
        raise EntityNotFoundError(
            "UserProfile",
            f"Perfil de usuario para UID {current_user.firebase_uid} no encontrado",
        )
    return profile


@router.post(
    "/episodes",
    response_model=PregnancyEpisodeResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Crear o activar episodio de embarazo",
)
async def create_pregnancy_episode(
    payload: CreatePregnancyEpisodeRequest,
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> PregnancyEpisodeResponse:
    repo = PostgresPregnancyRepository(session)
    use_case = CreatePregnancyEpisodeUseCase(repo)
    dto = CreatePregnancyEpisodeDTO(
        last_menstrual_period=payload.last_menstrual_period,
        ultrasound_edd=payload.ultrasound_edd,
        clinical_edd=payload.clinical_edd,
    )
    episode = await use_case.execute(user.id, dto)
    return PregnancyEpisodeResponse(
        id=episode.id,
        user_id=episode.user_id,
        clinical_edd=episode.clinical_edd,
        last_menstrual_period=episode.last_menstrual_period,
        ultrasound_edd=episode.ultrasound_edd,
        is_active=episode.is_active,
        started_at=episode.started_at,
        ended_at=episode.ended_at,
        recalibration_history=episode.recalibration_history,
    )


@router.get(
    "/active",
    response_model=PregnancySummaryResponse,
    summary="Obtener resumen del embarazo activo",
)
async def get_active_pregnancy_summary(
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> PregnancySummaryResponse:
    repo = PostgresPregnancyRepository(session)
    catalog = FetalWeeklyMilestonesCatalog()
    use_case = GetActivePregnancySummaryUseCase(repo, catalog)
    summary = await use_case.execute(user.id)
    return PregnancySummaryResponse(**summary)


@router.get(
    "/milestone/{week}",
    response_model=FetalMilestoneResponse,
    summary="Consultar hito fetal de una semana específica (4-42)",
)
async def get_fetal_milestone(
    week: Annotated[int, Path(ge=4, le=42, description="Semana de gestación")],
) -> FetalMilestoneResponse:
    catalog = FetalWeeklyMilestonesCatalog()
    milestone = catalog.get_milestone(week)
    return FetalMilestoneResponse(
        week=milestone.week,
        fruit_comparison=milestone.fruit_or_vegetable_comparison,
        approximate_length_cm=milestone.approximate_length_cm,
        approximate_weight_grams=milestone.approximate_weight_grams,
        anatomical_highlights=milestone.anatomical_highlights,
        clinical_recommendations=milestone.clinical_recommendations,
        suggested_tests=milestone.suggested_tests,
    )


@router.post(
    "/vitals",
    response_model=MaternalVitalsResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar signos vitales maternos con evaluación ACOG",
)
async def log_maternal_vitals(
    payload: LogMaternalVitalsRequest,
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> MaternalVitalsResponse:
    repo = PostgresPregnancyRepository(session)
    evaluator = MaternalRiskEvaluator()
    use_case = LogMaternalVitalsUseCase(repo, evaluator)
    dto = LogMaternalVitalsDTO(
        systolic_mmhg=payload.systolic_mmhg,
        diastolic_mmhg=payload.diastolic_mmhg,
        glucose_mg_dl=payload.glucose_mg_dl,
        glucose_timing=payload.glucose_timing,
        weight_kg=payload.weight_kg,
        symptoms=[s.model_dump() for s in payload.symptoms],
        measured_at=payload.measured_at,
    )
    saved = await use_case.execute(user.id, dto)
    return MaternalVitalsResponse(**saved)


@router.get(
    "/vitals/history",
    response_model=list[MaternalVitalsResponse],
    summary="Historial de signos vitales maternos",
)
async def get_vitals_history(
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
) -> list[MaternalVitalsResponse]:
    repo = PostgresPregnancyRepository(session)
    episode = await repo.get_active_episode(user.id)
    if not episode:
        return []
    history = await repo.get_vitals_history(episode.id, limit=limit)
    return [MaternalVitalsResponse(**h) for h in history]


@router.post(
    "/contractions/sessions",
    response_model=ContractionSessionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Guardar sesión de contracciones con análisis de patrón 5-1-1 o pretérmino",
)
async def record_contraction_session(
    payload: LogContractionSessionRequest,
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> ContractionSessionResponse:
    repo = PostgresPregnancyRepository(session)
    analyzer = ContractionAndKickAnalyzer()
    use_case = RecordContractionSessionUseCase(repo, analyzer)
    dto = LogContractionSessionDTO(
        events=[e.model_dump() for e in payload.events],
        ended_at=payload.ended_at,
    )
    result = await use_case.execute(user.id, dto)
    return ContractionSessionResponse(**result)


@router.get(
    "/contractions/history",
    response_model=list[ContractionSessionResponse],
    summary="Historial de sesiones de contracciones",
)
async def get_contraction_history(
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
    limit: Annotated[int, Query(ge=1, le=50)] = 10,
) -> list[ContractionSessionResponse]:
    repo = PostgresPregnancyRepository(session)
    episode = await repo.get_active_episode(user.id)
    if not episode:
        return []
    history = await repo.get_latest_contraction_sessions(episode.id, limit=limit)
    return [ContractionSessionResponse(**h) for h in history]


@router.post(
    "/kick-sessions",
    response_model=KickSessionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Guardar sesión de monitor de patadas fetales (Cardiff)",
)
async def record_kick_session(
    payload: LogKickSessionRequest,
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> KickSessionResponse:
    repo = PostgresPregnancyRepository(session)
    analyzer = ContractionAndKickAnalyzer()
    use_case = RecordKickSessionUseCase(repo, analyzer)
    dto = LogKickSessionDTO(
        kicks_count=payload.kicks_count,
        duration_minutes=payload.duration_minutes,
        target_reached_at_minutes=payload.target_reached_at_minutes,
        started_at=payload.started_at,
    )
    result = await use_case.execute(user.id, dto)
    return KickSessionResponse(**result)


@router.get(
    "/kick-sessions/history",
    response_model=list[KickSessionResponse],
    summary="Historial de sesiones de patadas fetales",
)
async def get_kick_sessions_history(
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
    limit: Annotated[int, Query(ge=1, le=50)] = 10,
) -> list[KickSessionResponse]:
    repo = PostgresPregnancyRepository(session)
    episode = await repo.get_active_episode(user.id)
    if not episode:
        return []
    history = await repo.get_latest_kick_sessions(episode.id, limit=limit)
    return [KickSessionResponse(**h) for h in history]


@router.get(
    "/birth-plan",
    response_model=BirthPlanResponse,
    summary="Consultar preferencias del plan de parto",
)
async def get_birth_plan(
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> BirthPlanResponse:
    repo = PostgresPregnancyRepository(session)
    use_case = ManageBirthPlanUseCase(repo)
    plan = await use_case.get_plan(user.id)
    return BirthPlanResponse(
        companion_preferences=plan.companion_preferences,
        pain_management=plan.pain_management,
        delivery_environment=plan.delivery_environment,
        immediate_postpartum=plan.immediate_postpartum,
        special_requests=plan.special_requests,
    )


@router.put(
    "/birth-plan",
    response_model=BirthPlanResponse,
    summary="Actualizar preferencias del plan de parto",
)
async def update_birth_plan(
    payload: BirthPlanRequest,
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> BirthPlanResponse:
    repo = PostgresPregnancyRepository(session)
    use_case = ManageBirthPlanUseCase(repo)
    dto = SaveBirthPlanDTO(
        companion_preferences=payload.companion_preferences,
        pain_management=payload.pain_management,
        delivery_environment=payload.delivery_environment,
        immediate_postpartum=payload.immediate_postpartum,
        special_requests=payload.special_requests,
    )
    saved = await use_case.save_plan(user.id, dto)
    return BirthPlanResponse(
        companion_preferences=saved.companion_preferences,
        pain_management=saved.pain_management,
        delivery_environment=saved.delivery_environment,
        immediate_postpartum=saved.immediate_postpartum,
        special_requests=saved.special_requests,
    )


@router.get(
    "/appointments",
    response_model=list[PrenatalAppointmentResponse],
    summary="Listar citas de la agenda prenatal",
)
async def list_prenatal_appointments(
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> list[PrenatalAppointmentResponse]:
    repo = PostgresPregnancyRepository(session)
    use_case = ManagePrenatalAppointmentsUseCase(repo)
    appointments = await use_case.list_appointments(user.id)
    return [
        PrenatalAppointmentResponse(
            id=a.id,
            pregnancy_episode_id=a.pregnancy_episode_id,
            scheduled_at=a.scheduled_at,
            doctor_or_clinic=a.doctor_or_clinic,
            gestational_week=a.gestational_week,
            topics_to_discuss=a.topics_to_discuss,
            notes=a.notes,
            is_completed=a.is_completed,
        )
        for a in appointments
    ]


@router.post(
    "/appointments",
    response_model=PrenatalAppointmentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Agendar una nueva cita prenatal",
)
async def create_prenatal_appointment(
    payload: CreatePrenatalAppointmentRequest,
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> PrenatalAppointmentResponse:
    repo = PostgresPregnancyRepository(session)
    use_case = ManagePrenatalAppointmentsUseCase(repo)
    dto = CreatePrenatalAppointmentDTO(
        scheduled_at=payload.scheduled_at,
        doctor_or_clinic=payload.doctor_or_clinic,
        gestational_week=payload.gestational_week,
        topics_to_discuss=payload.topics_to_discuss,
        notes=payload.notes,
    )
    appointment = await use_case.create_appointment(user.id, dto)
    return PrenatalAppointmentResponse(
        id=appointment.id,
        pregnancy_episode_id=appointment.pregnancy_episode_id,
        scheduled_at=appointment.scheduled_at,
        doctor_or_clinic=appointment.doctor_or_clinic,
        gestational_week=appointment.gestational_week,
        topics_to_discuss=appointment.topics_to_discuss,
        notes=appointment.notes,
        is_completed=appointment.is_completed,
    )


@router.patch(
    "/appointments/{appointment_id}/toggle",
    response_model=PrenatalAppointmentResponse,
    summary="Marcar cita prenatal como completada o pendiente",
)
async def toggle_appointment_completion(
    appointment_id: Annotated[uuid.UUID, Path()],
    payload: ToggleAppointmentRequest,
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> PrenatalAppointmentResponse:
    repo = PostgresPregnancyRepository(session)
    use_case = ManagePrenatalAppointmentsUseCase(repo)
    appointment = await use_case.toggle_completion(
        appointment_id, payload.is_completed, user_id=user.id
    )
    return PrenatalAppointmentResponse(
        id=appointment.id,
        pregnancy_episode_id=appointment.pregnancy_episode_id,
        scheduled_at=appointment.scheduled_at,
        doctor_or_clinic=appointment.doctor_or_clinic,
        gestational_week=appointment.gestational_week,
        topics_to_discuss=appointment.topics_to_discuss,
        notes=appointment.notes,
        is_completed=appointment.is_completed,
    )
