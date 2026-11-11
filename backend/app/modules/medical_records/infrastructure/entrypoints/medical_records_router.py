from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_async_session
from app.core.errors import EntityNotFoundError
from app.core.security import CurrentUserDep
from app.modules.clinical_tracking.infrastructure.adapters.postgres_cycle_repository import (  # noqa: E501
    PostgresCycleRepository,
)
from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.identity.infrastructure.adapters.postgres_user_profile_repository import (  # noqa: E501
    PostgresUserProfileRepository,
)
from app.modules.maternal_care.infrastructure.adapters.postgres_pregnancy_repository import (  # noqa: E501
    PostgresPregnancyRepository,
)
from app.modules.mature_health.infrastructure.adapters.postgres_mature_health_repository import (  # noqa: E501
    PostgresMatureHealthRepository,
)
from app.modules.medical_records.application.ports.file_storage_port import (
    IFileStorage,
)
from app.modules.medical_records.application.use_cases.generate_doctor_ready_pdf_use_case import (  # noqa: E501
    GenerateDoctorReadyPdfUseCase,
)
from app.modules.medical_records.application.use_cases.medical_records_use_cases import (  # noqa: E501
    MedicalRecordsUseCases,
)
from app.modules.medical_records.domain.value_objects.record_metadata import (
    ExamType,
)
from app.modules.medical_records.infrastructure.adapters.cloudflare_r2_storage_adapter import (  # noqa: E501
    CloudflareR2StorageAdapter,
)
from app.modules.medical_records.infrastructure.adapters.postgres_medical_records_repository import (  # noqa: E501
    PostgresMedicalRecordsRepository,
)
from app.modules.medical_records.infrastructure.adapters.weasyprint_report_renderer import (  # noqa: E501
    WeasyPrintReportRenderer,
)
from app.modules.medical_records.infrastructure.entrypoints.medical_records_schemas import (  # noqa: E501
    DoctorReportPdfRequest,
    MedicalExamRequest,
    MedicalExamResponse,
    PresignedDownloadUrlResponseSchema,
    PresignedUploadUrlResponseSchema,
    PreventiveCalendarResponse,
    PreventiveScreeningItemSchema,
    RequestUploadUrlRequest,
    SpecialistContactRequest,
    SpecialistContactResponse,
    VaccinationEntryRequest,
    VaccinationEntryResponse,
)
from app.modules.treatments.infrastructure.adapters.postgres_treatment_repository import (  # noqa: E501
    PostgresTreatmentRepository,
)

router = APIRouter(
    prefix="/medical-records",
    tags=["Medical Records - Folder, Vaccines & Doctor-Ready PDF"],
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


def get_file_storage() -> IFileStorage:
    return CloudflareR2StorageAdapter()


def get_medical_records_use_cases(
    session: Annotated[AsyncSession, Depends(get_async_session)],
    storage: Annotated[IFileStorage, Depends(get_file_storage)],
) -> MedicalRecordsUseCases:
    repo = PostgresMedicalRecordsRepository(session)
    return MedicalRecordsUseCases(repo=repo, storage=storage)


def get_doctor_pdf_use_case(
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> GenerateDoctorReadyPdfUseCase:
    profile_repo = PostgresUserProfileRepository(session)
    cycle_repo = PostgresCycleRepository(session)
    treatment_repo = PostgresTreatmentRepository(session)
    pregnancy_repo = PostgresPregnancyRepository(session)
    mature_health_repo = PostgresMatureHealthRepository(session)
    renderer = WeasyPrintReportRenderer()
    return GenerateDoctorReadyPdfUseCase(
        profile_repo=profile_repo,
        report_renderer=renderer,
        cycle_repo=cycle_repo,
        treatment_repo=treatment_repo,
        pregnancy_repo=pregnancy_repo,
        mature_health_repo=mature_health_repo,
    )


# --- Medical Exams ---


@router.post(
    "/exams",
    response_model=MedicalExamResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar un nuevo estudio o examen clínico en la carpeta",
)
async def create_medical_exam(
    payload: MedicalExamRequest,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[
        MedicalRecordsUseCases, Depends(get_medical_records_use_cases)
    ],
) -> MedicalExamResponse:
    exam = await use_cases.record_medical_exam(
        user_id=profile.id,
        exam_type=payload.exam_type,
        title=payload.title,
        performed_at=payload.performed_at,
        clinic_or_lab=payload.clinic_or_lab,
        notes=payload.notes,
    )
    return MedicalExamResponse.model_validate(exam)


@router.get(
    "/exams",
    response_model=list[MedicalExamResponse],
    status_code=status.HTTP_200_OK,
    summary="Listar estudios médicos registrados por la usuaria",
)
async def list_medical_exams(
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[
        MedicalRecordsUseCases, Depends(get_medical_records_use_cases)
    ],
    exam_type: Annotated[
        ExamType | None,
        Query(description="Filtrar por tipo de estudio"),
    ] = None,
) -> list[MedicalExamResponse]:
    exams = await use_cases.list_medical_exams(user_id=profile.id, exam_type=exam_type)
    return [MedicalExamResponse.model_validate(e) for e in exams]


@router.get(
    "/exams/{exam_id}",
    response_model=MedicalExamResponse,
    status_code=status.HTTP_200_OK,
    summary="Obtener detalle de un estudio médico específico",
)
async def get_medical_exam_detail(
    exam_id: UUID,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[
        MedicalRecordsUseCases, Depends(get_medical_records_use_cases)
    ],
) -> MedicalExamResponse:
    exam = await use_cases.get_medical_exam(user_id=profile.id, exam_id=exam_id)
    return MedicalExamResponse.model_validate(exam)


@router.delete(
    "/exams/{exam_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Eliminar un estudio médico de la carpeta",
)
async def delete_medical_exam(
    exam_id: UUID,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[
        MedicalRecordsUseCases, Depends(get_medical_records_use_cases)
    ],
) -> Response:
    await use_cases.delete_medical_exam(user_id=profile.id, exam_id=exam_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/exams/{exam_id}/upload-url",
    response_model=PresignedUploadUrlResponseSchema,
    status_code=status.HTTP_200_OK,
    summary="Solicitar URL prefirmada para carga segura a Cloudflare R2 (≤ 15 MB)",
)
async def get_exam_upload_url(
    exam_id: UUID,
    payload: RequestUploadUrlRequest,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[
        MedicalRecordsUseCases, Depends(get_medical_records_use_cases)
    ],
) -> PresignedUploadUrlResponseSchema:
    upload_res = await use_cases.generate_exam_upload_url(
        user_id=profile.id,
        exam_id=exam_id,
        file_name=payload.file_name,
        mime_type=payload.mime_type,
        size_bytes=payload.size_bytes,
    )
    return PresignedUploadUrlResponseSchema(
        upload_url=upload_res.upload_url,
        storage_key=upload_res.storage_key,
        expires_in_seconds=upload_res.expires_in_seconds,
        required_headers=upload_res.required_headers,
    )


@router.get(
    "/exams/{exam_id}/download-url",
    response_model=PresignedDownloadUrlResponseSchema,
    status_code=status.HTTP_200_OK,
    summary="Solicitar URL de descarga temporal prefirmada con protección anti-IDOR",
)
async def get_exam_download_url(
    exam_id: UUID,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[
        MedicalRecordsUseCases, Depends(get_medical_records_use_cases)
    ],
) -> PresignedDownloadUrlResponseSchema:
    download_url = await use_cases.get_exam_download_url(
        user_id=profile.id, exam_id=exam_id
    )
    return PresignedDownloadUrlResponseSchema(
        download_url=download_url, expires_in_seconds=900
    )


# --- Calendario Preventivo ---


@router.get(
    "/preventive-calendar",
    response_model=PreventiveCalendarResponse,
    status_code=status.HTTP_200_OK,
    summary="Calendario preventivo clínico proyectado según edad, etapa y antecedentes",
)
async def get_preventive_calendar(
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[
        MedicalRecordsUseCases, Depends(get_medical_records_use_cases)
    ],
) -> PreventiveCalendarResponse:
    now_year = datetime.now(UTC).year
    user_age = 30
    conditions: list[str] = []
    if profile.onboarding_context:
        user_age = now_year - profile.onboarding_context.birth_year
        conditions = list(profile.onboarding_context.diagnosed_conditions)

    screenings = await use_cases.get_preventive_calendar(
        user_id=profile.id,
        user_age=user_age,
        life_stage=profile.current_life_stage,
        diagnosed_conditions=conditions,
    )
    return PreventiveCalendarResponse(
        screenings=[PreventiveScreeningItemSchema.model_validate(s) for s in screenings]
    )


# --- Vacunación ---


@router.post(
    "/vaccinations",
    response_model=VaccinationEntryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar dosis de vacuna administrada",
)
async def record_vaccination(
    payload: VaccinationEntryRequest,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[
        MedicalRecordsUseCases, Depends(get_medical_records_use_cases)
    ],
) -> VaccinationEntryResponse:
    entry = await use_cases.record_vaccination(
        user_id=profile.id,
        vaccine_type=payload.vaccine_type,
        dose_number=payload.dose_number,
        administered_at=payload.administered_at,
        lot_number=payload.lot_number,
        administrator_clinic=payload.administrator_clinic,
        notes=payload.notes,
    )
    return VaccinationEntryResponse.model_validate(entry)


@router.get(
    "/vaccinations",
    response_model=list[VaccinationEntryResponse],
    status_code=status.HTTP_200_OK,
    summary="Listar cartilla de vacunación de la usuaria",
)
async def list_vaccinations(
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[
        MedicalRecordsUseCases, Depends(get_medical_records_use_cases)
    ],
) -> list[VaccinationEntryResponse]:
    entries = await use_cases.list_vaccinations(user_id=profile.id)
    return [VaccinationEntryResponse.model_validate(e) for e in entries]


# --- Directorio de Especialistas ---


@router.post(
    "/specialists",
    response_model=SpecialistContactResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Guardar contacto de especialista médico de confianza",
)
async def save_specialist(
    payload: SpecialistContactRequest,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[
        MedicalRecordsUseCases, Depends(get_medical_records_use_cases)
    ],
) -> SpecialistContactResponse:
    specialist = await use_cases.save_specialist(
        user_id=profile.id,
        full_name=payload.full_name,
        specialty=payload.specialty,
        clinic_name=payload.clinic_name,
        phone_number=payload.phone_number,
        email=payload.email,
        notes=payload.notes,
        is_favorite=payload.is_favorite,
    )
    return SpecialistContactResponse.model_validate(specialist)


@router.get(
    "/specialists",
    response_model=list[SpecialistContactResponse],
    status_code=status.HTTP_200_OK,
    summary="Listar directorio de especialistas médicos de la usuaria",
)
async def list_specialists(
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[
        MedicalRecordsUseCases, Depends(get_medical_records_use_cases)
    ],
) -> list[SpecialistContactResponse]:
    contacts = await use_cases.list_specialists(user_id=profile.id)
    return [SpecialistContactResponse.model_validate(c) for c in contacts]


@router.delete(
    "/specialists/{specialist_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Eliminar contacto de especialista médico",
)
async def delete_specialist(
    specialist_id: UUID,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    use_cases: Annotated[
        MedicalRecordsUseCases, Depends(get_medical_records_use_cases)
    ],
) -> Response:
    await use_cases.delete_specialist(user_id=profile.id, specialist_id=specialist_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# --- Doctor-Ready PDF Report ---


@router.post(
    "/doctor-report/pdf",
    status_code=status.HTTP_200_OK,
    summary="Generar y descargar reporte clínico paginado Doctor-Ready PDF (A4)",
    responses={
        200: {
            "content": {"application/pdf": {}},
            "description": (
                "Documento PDF binario de 1 a 2 páginas A4 listo para consulta médica."
            ),
        }
    },
)
async def generate_doctor_ready_pdf(
    payload: DoctorReportPdfRequest,
    profile: Annotated[UserProfile, Depends(get_current_user_profile)],
    pdf_use_case: Annotated[
        GenerateDoctorReadyPdfUseCase, Depends(get_doctor_pdf_use_case)
    ],
) -> Response:
    pdf_bytes = await pdf_use_case.execute(
        user_id=profile.id,
        reporting_window_months=payload.reporting_window_months,
        specialist_notes=payload.specialist_notes,
    )
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": 'attachment; filename="cora_doctor_ready_report.pdf"'
        },
    )
