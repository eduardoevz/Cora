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
from app.modules.maternal_care.application.dtos.postpartum_dtos import (
    AddMilkStashDTO,
    EvaluateEpdsScreeningDTO,
    LogLactationSessionDTO,
    RecordPostpartumRecoveryDTO,
)
from app.modules.maternal_care.application.use_cases.postpartum_use_cases import (  # noqa: E501
    AddMilkStashUseCase,
    ConsumeMilkStashUseCase,
    EvaluateEpdsScreeningUseCase,
    GetActiveMilkStashUseCase,
    GetLatestEpdsScreeningUseCase,
    GetRecentLactationSessionsUseCase,
    GetRecentPostpartumRecoveryLogsUseCase,
    LogLactationSessionUseCase,
    RecordPostpartumRecoveryUseCase,
)
from app.modules.maternal_care.infrastructure.adapters.postgres_postpartum_repository import (  # noqa: E501
    PostgresPostpartumRepository,
)
from app.modules.maternal_care.infrastructure.entrypoints.postpartum_schemas import (  # noqa: E501
    AddMilkStashRequest,
    EpdsScreeningResponse,
    EvaluateEpdsRequest,
    LactationSessionResponse,
    LogLactationSessionRequest,
    MilkStashResponse,
    PostpartumRecoveryResponse,
    RecordPostpartumRecoveryRequest,
)

router = APIRouter(
    prefix="/postpartum", tags=["Maternal Care - Postpartum & Lactation"]
)


async def get_current_user_profile(
    current_user: CurrentUserDep,
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> UserProfile:
    repo = PostgresUserProfileRepository(session)
    profile = await repo.get_by_firebase_uid(current_user.firebase_uid)
    if profile is None:
        raise EntityNotFoundError(
            "UserProfile",
            f"Perfil para UID {current_user.firebase_uid} no encontrado",
        )
    return profile


@router.post(
    "/recovery-logs",
    response_model=PostpartumRecoveryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar evolución del puerperio y evaluar alertas clínicas",
)
async def record_recovery_log(
    payload: RecordPostpartumRecoveryRequest,
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> PostpartumRecoveryResponse:
    repo = PostgresPostpartumRepository(session)
    use_case = RecordPostpartumRecoveryUseCase(repo)
    dto = RecordPostpartumRecoveryDTO(
        days_postpartum=payload.days_postpartum,
        lochia_stage=payload.lochia_stage,
        lochia_flow=payload.lochia_flow,
        foul_odor=payload.foul_odor,
        maternal_temperature_c=payload.maternal_temperature_c,
        perineal_wound_status=payload.perineal_wound_status,
        cesarean_wound_status=payload.cesarean_wound_status,
        pelvic_floor_symptoms=payload.pelvic_floor_symptoms,
        notes=payload.notes,
    )
    result = await use_case.execute(user.id, dto)
    return PostpartumRecoveryResponse.model_validate(result)


@router.get(
    "/recovery-logs/recent",
    response_model=list[PostpartumRecoveryResponse],
    summary="Obtener registros puerperales recientes",
)
async def get_recent_recovery_logs(
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
) -> list[PostpartumRecoveryResponse]:
    repo = PostgresPostpartumRepository(session)
    use_case = GetRecentPostpartumRecoveryLogsUseCase(repo)
    results = await use_case.execute(user.id, limit=limit)
    return [PostpartumRecoveryResponse.model_validate(r) for r in results]


@router.post(
    "/lactation-sessions",
    response_model=LactationSessionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar sesión de lactancia materna o biberón",
)
async def log_lactation_session(
    payload: LogLactationSessionRequest,
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> LactationSessionResponse:
    repo = PostgresPostpartumRepository(session)
    use_case = LogLactationSessionUseCase(repo)
    dto = LogLactationSessionDTO(
        started_at=payload.started_at,
        ended_at=payload.ended_at,
        left_duration_seconds=payload.left_duration_seconds,
        right_duration_seconds=payload.right_duration_seconds,
        last_offered_breast=payload.last_offered_breast,
        bottle_volume_ml=payload.bottle_volume_ml,
        feeding_type=payload.feeding_type,
        notes=payload.notes,
    )
    result = await use_case.execute(user.id, dto)
    return LactationSessionResponse.model_validate(result)


@router.get(
    "/lactation-sessions/recent",
    response_model=list[LactationSessionResponse],
    summary="Obtener sesiones recientes de lactancia",
)
async def get_recent_lactation_sessions(
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
) -> list[LactationSessionResponse]:
    repo = PostgresPostpartumRepository(session)
    use_case = GetRecentLactationSessionsUseCase(repo)
    results = await use_case.execute(user.id, limit=limit)
    return [LactationSessionResponse.model_validate(r) for r in results]


@router.post(
    "/milk-stash",
    response_model=MilkStashResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Añadir lote de leche extraída al banco de leche",
)
async def add_milk_stash_entry(
    payload: AddMilkStashRequest,
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> MilkStashResponse:
    repo = PostgresPostpartumRepository(session)
    use_case = AddMilkStashUseCase(repo)
    dto = AddMilkStashDTO(
        pumped_at=payload.pumped_at,
        volume_ml=payload.volume_ml,
        storage_location=payload.storage_location,
        notes=payload.notes,
    )
    result = await use_case.execute(user.id, dto)
    return MilkStashResponse.model_validate(result)


@router.get(
    "/milk-stash",
    response_model=list[MilkStashResponse],
    summary="Listar lotes activos del banco de leche (orden FIFO por caducidad)",
)
async def get_active_milk_stash(
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> list[MilkStashResponse]:
    repo = PostgresPostpartumRepository(session)
    use_case = GetActiveMilkStashUseCase(repo)
    results = await use_case.execute(user.id)
    return [MilkStashResponse.model_validate(r) for r in results]


@router.patch(
    "/milk-stash/{stash_id}/consume",
    response_model=MilkStashResponse,
    summary="Marcar lote de leche como consumido",
)
async def consume_milk_stash_entry(
    stash_id: Annotated[uuid.UUID, Path(description="UUID del lote de leche")],
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> MilkStashResponse:
    repo = PostgresPostpartumRepository(session)
    use_case = ConsumeMilkStashUseCase(repo)
    result = await use_case.execute(stash_id=stash_id, user_id=user.id)
    if result is None:
        raise EntityNotFoundError("MilkStashEntry", str(stash_id))
    return MilkStashResponse.model_validate(result)


@router.post(
    "/epds-screenings",
    response_model=EpdsScreeningResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Evaluar y registrar Escala de Depresión Posparto de Edimburgo (EPDS)",
)
async def evaluate_epds_screening(
    payload: EvaluateEpdsRequest,
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> EpdsScreeningResponse:
    repo = PostgresPostpartumRepository(session)
    use_case = EvaluateEpdsScreeningUseCase(repo)
    responses_dict = payload.responses.model_dump()
    dto = EvaluateEpdsScreeningDTO(
        days_postpartum=payload.days_postpartum,
        responses=responses_dict,
    )
    result = await use_case.execute(user.id, dto)
    return EpdsScreeningResponse.model_validate(result)


@router.get(
    "/epds-screenings/latest",
    response_model=EpdsScreeningResponse | None,
    summary="Obtener último tamizaje de depresión posparto (EPDS)",
)
async def get_latest_epds_screening(
    user: Annotated[UserProfile, Depends(get_current_user_profile)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> EpdsScreeningResponse | None:
    repo = PostgresPostpartumRepository(session)
    use_case = GetLatestEpdsScreeningUseCase(repo)
    result = await use_case.execute(user.id)
    if result is None:
        return None
    return EpdsScreeningResponse.model_validate(result)
