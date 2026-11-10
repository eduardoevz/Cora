"""FastAPI REST router for mature health module."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_async_session
from app.core.errors import EntityNotFoundError
from app.core.security import CurrentUserDep
from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.identity.infrastructure.adapters.postgres_user_profile_repository import (  # noqa: E501
    PostgresUserProfileRepository,
)
from app.modules.mature_health.application.dtos.mature_health_dtos import (
    RecordBleedingObservationInput,
    RecordCardiometabolicInput,
    RecordDexaInput,
    RecordFallAssessmentInput,
    RecordHotFlashInput,
    RecordPelvicLogInput,
    SaveSupportContactInput,
)
from app.modules.mature_health.application.use_cases.mature_health_use_cases import (
    MatureHealthUseCases,
)
from app.modules.mature_health.domain.value_objects import (
    AnatomicalSite,
    HotFlashSeverity,
    HotFlashType,
    IncontinenceType,
)
from app.modules.mature_health.infrastructure.adapters.postgres_mature_health_repository import (  # noqa: E501
    PostgresMatureHealthRepository,
)
from app.modules.mature_health.infrastructure.entrypoints.mature_health_schemas import (
    CardiometabolicRequest,
    CardiometabolicResponse,
    DexaScanRequest,
    DexaScanResponse,
    FallAssessmentRequest,
    FallAssessmentResponse,
    HotFlashRequest,
    HotFlashResponse,
    MenopauseSummaryResponse,
    PelvicLogRequest,
    PelvicLogResponse,
    SeniorVitalitySummaryResponse,
    SupportContactRequest,
    SupportContactResponse,
    VaginalBleedingRequest,
    VaginalBleedingResponse,
)

router = APIRouter(
    prefix="/mature-health",
    tags=["Mature Health - Menopause & Senior Vitality"],
)


async def get_current_user_profile(
    current_user: CurrentUserDep,
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> UserProfile:
    repo = PostgresUserProfileRepository(session)
    profile = await repo.get_by_firebase_uid(current_user.firebase_uid)
    if profile is None:
        raise EntityNotFoundError("UserProfile", current_user.firebase_uid)
    return profile


def get_use_cases(
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> MatureHealthUseCases:
    repo = PostgresMatureHealthRepository(session)
    return MatureHealthUseCases(repo)


@router.post(
    "/hot-flashes",
    response_model=HotFlashResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar episodio de sofoco o sudores nocturnos",
)
async def record_hot_flash(
    request: HotFlashRequest,
    current_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[MatureHealthUseCases, Depends(get_use_cases)],
) -> HotFlashResponse:
    episode = await use_cases.record_hot_flash(
        user_id=current_profile.id,
        input_dto=RecordHotFlashInput(
            occurred_at=request.occurred_at,
            severity=HotFlashSeverity(request.severity),
            flash_type=HotFlashType(request.flash_type),
            duration_minutes=request.duration_minutes,
            triggers=request.triggers,
            sleep_disruption_level=request.sleep_disruption_level,
            associated_with_hrt=request.associated_with_hrt,
            notes=request.notes,
        ),
    )
    return HotFlashResponse(
        id=episode.id,
        occurred_at=episode.occurred_at,
        severity=int(episode.severity.value),
        flash_type=episode.flash_type.value,
        duration_minutes=episode.duration_minutes,
        triggers=episode.triggers,
        sleep_disruption_level=episode.sleep_disruption_level,
        associated_with_hrt=episode.associated_with_hrt,
        notes=episode.notes,
    )


@router.get(
    "/hot-flashes",
    response_model=list[HotFlashResponse],
    status_code=status.HTTP_200_OK,
    summary="Listar episodios recientes de sofocos",
)
async def list_hot_flashes(
    current_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[MatureHealthUseCases, Depends(get_use_cases)],
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
) -> list[HotFlashResponse]:
    episodes = await use_cases.list_hot_flashes(current_profile.id, limit=limit)
    return [
        HotFlashResponse(
            id=ep.id,
            occurred_at=ep.occurred_at,
            severity=int(ep.severity.value),
            flash_type=ep.flash_type.value,
            duration_minutes=ep.duration_minutes,
            triggers=ep.triggers,
            sleep_disruption_level=ep.sleep_disruption_level,
            associated_with_hrt=ep.associated_with_hrt,
            notes=ep.notes,
        )
        for ep in episodes
    ]


@router.post(
    "/cardiometabolic",
    response_model=CardiometabolicResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar panel lipídico, glucosa y presión arterial",
)
async def record_cardiometabolic(
    request: CardiometabolicRequest,
    current_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[MatureHealthUseCases, Depends(get_use_cases)],
) -> CardiometabolicResponse:
    panel, risk_level, flagged = await use_cases.record_cardiometabolic_panel(
        user_id=current_profile.id,
        input_dto=RecordCardiometabolicInput(
            measurement_date=request.measurement_date,
            systolic_bp=request.systolic_bp,
            diastolic_bp=request.diastolic_bp,
            total_cholesterol_mg_dl=request.total_cholesterol_mg_dl,
            ldl_cholesterol_mg_dl=request.ldl_cholesterol_mg_dl,
            hdl_cholesterol_mg_dl=request.hdl_cholesterol_mg_dl,
            triglycerides_mg_dl=request.triglycerides_mg_dl,
            fasting_glucose_mg_dl=request.fasting_glucose_mg_dl,
            notes=request.notes,
        ),
    )
    return CardiometabolicResponse(
        id=panel.id,
        measurement_date=panel.measurement_date,
        systolic_bp=panel.systolic_bp,
        diastolic_bp=panel.diastolic_bp,
        total_cholesterol_mg_dl=panel.total_cholesterol_mg_dl,
        ldl_cholesterol_mg_dl=panel.ldl_cholesterol_mg_dl,
        hdl_cholesterol_mg_dl=panel.hdl_cholesterol_mg_dl,
        triglycerides_mg_dl=panel.triglycerides_mg_dl,
        fasting_glucose_mg_dl=panel.fasting_glucose_mg_dl,
        risk_level=risk_level,
        flagged_parameters=flagged,
        notes=panel.notes,
    )


@router.post(
    "/vaginal-bleeding",
    response_model=VaginalBleedingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar observación de sangrado y evaluar alerta posmenopáusica",
)
async def record_vaginal_bleeding(
    request: VaginalBleedingRequest,
    current_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[MatureHealthUseCases, Depends(get_use_cases)],
) -> VaginalBleedingResponse:
    output = await use_cases.record_bleeding_observation(
        user_id=current_profile.id,
        input_dto=RecordBleedingObservationInput(
            observation_date=request.observation_date,
            days_of_prior_amenorrhea=request.days_of_prior_amenorrhea,
            flow_intensity=request.flow_intensity,
            has_cramping=request.has_cramping,
            notes=request.notes,
        ),
    )
    return VaginalBleedingResponse(
        observation_id=output.observation_id,
        is_alert_triggered=output.is_alert_triggered,
        alert_code=output.alert.code if output.alert else None,
        alert_severity=output.alert.severity.value if output.alert else None,
        alert_guidance=output.alert.clinical_guidance if output.alert else None,
    )


@router.post(
    "/dexa-scans",
    response_model=DexaScanResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar densitometría ósea DXA y clasificar según OMS",
)
async def record_dexa_scan(
    request: DexaScanRequest,
    current_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[MatureHealthUseCases, Depends(get_use_cases)],
) -> DexaScanResponse:
    output = await use_cases.record_dexa_scan(
        user_id=current_profile.id,
        input_dto=RecordDexaInput(
            scan_date=request.scan_date,
            anatomical_site=AnatomicalSite(request.anatomical_site),
            t_score=request.t_score,
            z_score=request.z_score,
            bmd_g_cm2=request.bmd_g_cm2,
            previous_fragility_fracture=request.previous_fragility_fracture,
            notes=request.notes,
        ),
    )
    return DexaScanResponse(
        scan_id=output.scan_id,
        category=output.classification.category.value,
        t_score=output.classification.t_score,
        anatomical_site=output.classification.anatomical_site.value,
        clinical_summary=output.classification.clinical_summary,
    )


@router.post(
    "/fall-assessments",
    response_model=FallAssessmentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar tamizaje de riesgo de caídas en adulto mayor",
)
async def record_fall_assessment(
    request: FallAssessmentRequest,
    current_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[MatureHealthUseCases, Depends(get_use_cases)],
) -> FallAssessmentResponse:
    output = await use_cases.record_fall_assessment(
        user_id=current_profile.id,
        input_dto=RecordFallAssessmentInput(
            assessment_date=request.assessment_date,
            falls_past_year=request.falls_past_year,
            has_gait_unsteadiness=request.has_gait_unsteadiness,
            uses_walking_aid=request.uses_walking_aid,
            timed_up_and_go_seconds=request.timed_up_and_go_seconds,
            environmental_hazards_identified=(request.environmental_hazards_identified),
            notes=request.notes,
        ),
    )
    return FallAssessmentResponse(
        assessment_id=output.assessment_id,
        risk_level=output.result.risk_level.value,
        composite_score=output.result.score,
        preventive_actions=list(output.result.preventive_actions),
    )


@router.post(
    "/pelvic-logs",
    response_model=PelvicLogResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar diario uroginecológico y de suelo pélvico",
)
async def record_pelvic_log(
    request: PelvicLogRequest,
    current_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[MatureHealthUseCases, Depends(get_use_cases)],
) -> PelvicLogResponse:
    output = await use_cases.record_pelvic_log(
        user_id=current_profile.id,
        input_dto=RecordPelvicLogInput(
            log_date=request.log_date,
            incontinence_type=IncontinenceType(request.incontinence_type),
            daily_pad_count=request.daily_pad_count,
            has_pelvic_heaviness=request.has_pelvic_heaviness,
            vaginal_dryness_level=request.vaginal_dryness_level,
            has_dyspareunia=request.has_dyspareunia,
            notes=request.notes,
        ),
    )
    return PelvicLogResponse(
        log_id=output.log_id,
        requires_urogynecology_consult=output.guidance.requires_urogynecology_consult,
        supportive_tips=list(output.guidance.supportive_tips),
    )


@router.post(
    "/support-contact",
    response_model=SupportContactResponse,
    status_code=status.HTTP_200_OK,
    summary="Configurar contacto familiar de apoyo prioritario",
)
async def save_support_contact(
    request: SupportContactRequest,
    current_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[MatureHealthUseCases, Depends(get_use_cases)],
) -> SupportContactResponse:
    contact = await use_cases.save_support_contact(
        user_id=current_profile.id,
        input_dto=SaveSupportContactInput(
            contact_name=request.contact_name,
            relationship=request.relationship,
            phone_number=request.phone_number,
            notes=request.notes,
            is_primary=request.is_primary,
        ),
    )
    return SupportContactResponse(
        id=contact.id,
        contact_name=contact.contact_name,
        relationship=contact.relationship,
        phone_number=contact.phone_number,
        notes=contact.notes,
        is_primary=contact.is_primary,
    )


@router.get(
    "/support-contact",
    response_model=SupportContactResponse | None,
    status_code=status.HTTP_200_OK,
    summary="Consultar contacto familiar de apoyo prioritario",
)
async def get_support_contact(
    current_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[MatureHealthUseCases, Depends(get_use_cases)],
) -> SupportContactResponse | None:
    contact = await use_cases.get_support_contact(current_profile.id)
    if not contact:
        return None
    return SupportContactResponse(
        id=contact.id,
        contact_name=contact.contact_name,
        relationship=contact.relationship,
        phone_number=contact.phone_number,
        notes=contact.notes,
        is_primary=contact.is_primary,
    )


@router.get(
    "/menopause/summary",
    response_model=MenopauseSummaryResponse,
    status_code=status.HTTP_200_OK,
    summary="Consultar resumen y estadificación STRAW+10 para perimenopausia",
)
async def get_menopause_summary(
    current_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[MatureHealthUseCases, Depends(get_use_cases)],
) -> MenopauseSummaryResponse:
    summary = await use_cases.get_menopause_summary(current_profile.id)
    cardio_risk = (
        summary.latest_cardiometabolic_assessment.risk_level.value
        if summary.latest_cardiometabolic_assessment
        else None
    )
    return MenopauseSummaryResponse(
        straw10_stage=summary.straw10_stage.value,
        hot_flashes_count_last_30_days=summary.hot_flashes_count_last_30_days,
        latest_cardiometabolic_risk_level=cardio_risk,
        active_alerts_count=len(summary.active_alerts),
    )


@router.get(
    "/senior-vitality/summary",
    response_model=SeniorVitalitySummaryResponse,
    status_code=status.HTTP_200_OK,
    summary="Consultar resumen integral de plenitud y vitalidad sénior",
)
async def get_senior_vitality_summary(
    current_profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[MatureHealthUseCases, Depends(get_use_cases)],
) -> SeniorVitalitySummaryResponse:
    summary = await use_cases.get_senior_vitality_summary(current_profile.id)
    return SeniorVitalitySummaryResponse(
        latest_bone_category=(
            summary.latest_bone_classification.category.value
            if summary.latest_bone_classification
            else None
        ),
        latest_fall_risk_level=(
            summary.latest_fall_risk.risk_level.value
            if summary.latest_fall_risk
            else None
        ),
        has_fracture_alert=summary.fracture_alert is not None,
        requires_urogynecology_consult=(
            summary.latest_pelvic_guidance.requires_urogynecology_consult
            if summary.latest_pelvic_guidance
            else False
        ),
        trusted_contact_name=summary.trusted_contact_name,
        trusted_contact_phone=summary.trusted_contact_phone,
    )
