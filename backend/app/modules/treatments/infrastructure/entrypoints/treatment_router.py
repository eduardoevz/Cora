import hashlib
import json
from datetime import UTC, date, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Header, Query, status
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_async_session
from app.core.errors import EntityNotFoundError
from app.core.idempotency import IdempotencyStore
from app.core.security import CurrentUserDep
from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.identity.infrastructure.adapters.postgres_user_profile_repository import (  # noqa: E501
    PostgresUserProfileRepository,
)
from app.modules.treatments.application.dtos.treatment_dtos import (
    CreateTreatmentRegimenDTO,
    LogDoseIntakeDTO,
)
from app.modules.treatments.application.ports.treatment_repository_port import (
    ITreatmentRepository,
)
from app.modules.treatments.application.use_cases.manage_treatments_use_cases import (  # noqa: E501
    CreateTreatmentRegimenUseCase,
    GetTreatmentAdherenceUseCase,
    LogDoseIntakeUseCase,
)
from app.modules.treatments.domain.services.adherence_and_missed_dose_service import (  # noqa: E501
    AdherenceAndMissedDoseService,
)
from app.modules.treatments.infrastructure.adapters.postgres_treatment_repository import (  # noqa: E501
    PostgresTreatmentRepository,
)
from app.modules.treatments.infrastructure.entrypoints.treatment_schemas import (
    AdherenceSummaryResponse,
    CreateTreatmentRegimenRequest,
    DoseIntakeLogResponse,
    LarcAlertResponse,
    LogDoseIntakeRequest,
    TreatmentRegimenResponse,
)

router = APIRouter(prefix="/treatments", tags=["Treatments & Medications"])


async def get_current_user_profile(
    current_user: CurrentUserDep,
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> UserProfile:
    repo = PostgresUserProfileRepository(session)
    profile = await repo.get_by_firebase_uid(current_user.firebase_uid)
    if profile is None:
        raise EntityNotFoundError(
            entity="UserProfile", identifier=current_user.firebase_uid
        )
    return profile


def get_treatment_repository(
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> ITreatmentRepository:
    return PostgresTreatmentRepository(session)


@router.post(
    "/regimens",
    response_model=TreatmentRegimenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create Treatment Regimen",
    description=(
        "Registers a new medication or contraceptive regimen (e.g. 21/7 cyclic, "
        "minipill, LARC, supplement, chronic treatment)."
    ),
)
async def create_treatment_regimen(
    request: CreateTreatmentRegimenRequest,
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[ITreatmentRepository, Depends(get_treatment_repository)],
) -> TreatmentRegimenResponse:
    use_case = CreateTreatmentRegimenUseCase(repository)
    dto = CreateTreatmentRegimenDTO(
        name=request.name,
        category=request.category,
        dosage=request.dosage,
        schedule_type=request.schedule_type,
        scheduled_time=request.scheduled_time,
        start_date=request.start_date.isoformat(),
        end_date=request.end_date.isoformat() if request.end_date else None,
        active_days=request.active_days,
        break_days=request.break_days,
        interval_days=request.interval_days,
        replacement_date=request.replacement_date.isoformat()
        if request.replacement_date
        else None,
        instructions=request.instructions,
    )
    regimen = await use_case.execute(user_id=str(user_profile.id), dto=dto)
    return TreatmentRegimenResponse.from_domain(regimen)


@router.get(
    "/regimens",
    response_model=list[TreatmentRegimenResponse],
    status_code=status.HTTP_200_OK,
    summary="List Treatment Regimens",
    description="Lists active and historical regimens for the authenticated user.",
)
async def list_treatment_regimens(
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[ITreatmentRepository, Depends(get_treatment_repository)],
    is_active: Annotated[
        bool | None, Query(description="Filter by active status")
    ] = None,
) -> list[TreatmentRegimenResponse]:
    regimens = await repository.get_regimens(
        user_id=str(user_profile.id), is_active=is_active
    )
    return [TreatmentRegimenResponse.from_domain(r) for r in regimens]


@router.get(
    "/regimens/{regimen_id}",
    response_model=TreatmentRegimenResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Treatment Regimen",
    description="Retrieves details of a specific treatment regimen.",
)
async def get_treatment_regimen(
    regimen_id: UUID,
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[ITreatmentRepository, Depends(get_treatment_repository)],
) -> TreatmentRegimenResponse:
    regimen = await repository.get_regimen_by_id(str(regimen_id))
    if regimen is None or regimen.user_id != str(user_profile.id):
        raise EntityNotFoundError(entity="TreatmentRegimen", identifier=str(regimen_id))
    return TreatmentRegimenResponse.from_domain(regimen)


@router.post(
    "/intakes",
    response_model=DoseIntakeLogResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Log Dose Intake (Idempotent)",
    description=(
        "Records dose intake status, evaluates delay / missed dose clinical safety, "
        "and deduplicates using client_mutation_id or X-Client-Mutation-Id."
    ),
)
async def log_dose_intake(
    request: LogDoseIntakeRequest,
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[ITreatmentRepository, Depends(get_treatment_repository)],
    session: Annotated[AsyncSession, Depends(get_async_session)],
    x_client_mutation_id: Annotated[UUID | None, Header()] = None,
) -> JSONResponse | DoseIntakeLogResponse:
    mutation_id = x_client_mutation_id or request.client_mutation_id
    idempotency_store = IdempotencyStore(session)

    if mutation_id is not None:
        cached = await idempotency_store.get_cached_response(
            user_id=user_profile.id,
            client_mutation_id=mutation_id,
        )
        if cached is not None:
            return JSONResponse(
                status_code=cached.response_status,
                content=cached.response_body,
            )

    use_case = LogDoseIntakeUseCase(repository)
    dto = LogDoseIntakeDTO(
        scheduled_for=request.scheduled_for.isoformat(),
        taken_at=request.taken_at.isoformat() if request.taken_at else None,
        status=request.status,
        notes=request.notes,
        client_mutation_id=str(mutation_id) if mutation_id else None,
    )
    intake, assessment = await use_case.execute(
        user_id=str(user_profile.id),
        regimen_id=str(request.regimen_id),
        dto=dto,
    )
    response_obj = DoseIntakeLogResponse.from_domain(intake, assessment)
    response_dict = json.loads(response_obj.model_dump_json())

    if mutation_id is not None:
        body_hash = hashlib.sha256(request.model_dump_json().encode()).hexdigest()
        await idempotency_store.record_response(
            user_id=user_profile.id,
            client_mutation_id=mutation_id,
            endpoint="/api/v1/treatments/intakes",
            request_hash=body_hash,
            response_status=status.HTTP_201_CREATED,
            response_body=response_dict,
        )

    return JSONResponse(
        status_code=status.HTTP_201_CREATED,
        content=response_dict,
    )


@router.get(
    "/adherence-summary",
    response_model=AdherenceSummaryResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Treatment Adherence Summary",
    description="Calculates adherence stats considering cyclic breaks (21/7, 24/4).",
)
async def get_adherence_summary(
    regimen_id: Annotated[UUID, Query(description="Treatment regimen UUID")],
    start_date: Annotated[date, Query(description="Start date (YYYY-MM-DD)")],
    end_date: Annotated[date, Query(description="End date (YYYY-MM-DD)")],
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[ITreatmentRepository, Depends(get_treatment_repository)],
) -> AdherenceSummaryResponse:
    use_case = GetTreatmentAdherenceUseCase(repository)
    summary = await use_case.execute(
        user_id=str(user_profile.id),
        regimen_id=str(regimen_id),
        start_date=start_date,
        end_date=end_date,
    )
    return AdherenceSummaryResponse.from_domain(summary)


@router.get(
    "/regimens/{regimen_id}/larc-alert",
    response_model=LarcAlertResponse,
    status_code=status.HTTP_200_OK,
    summary="Get LARC Replacement Alert",
    description="Evaluates remaining days and alert level for IUD/implant replacement.",
)
async def get_larc_replacement_alert(
    regimen_id: UUID,
    user_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    repository: Annotated[ITreatmentRepository, Depends(get_treatment_repository)],
) -> LarcAlertResponse:
    regimen = await repository.get_regimen_by_id(str(regimen_id))
    if regimen is None or regimen.user_id != str(user_profile.id):
        raise EntityNotFoundError(entity="TreatmentRegimen", identifier=str(regimen_id))

    service = AdherenceAndMissedDoseService()
    alert = service.check_larc_replacement(
        regimen, current_date=datetime.now(UTC).date()
    )
    return LarcAlertResponse.from_domain(alert)
