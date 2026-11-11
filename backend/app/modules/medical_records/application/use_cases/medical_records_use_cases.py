from datetime import UTC, date, datetime
from uuid import UUID, uuid4

from app.modules.identity.domain.value_objects.life_stage import LifeStage
from app.modules.medical_records.application.ports.file_storage_port import (
    IFileStorage,
    PresignedUploadUrlResponse,
)
from app.modules.medical_records.application.ports.medical_records_repository_port import (  # noqa: E501
    IMedicalRecordsRepository,
)
from app.modules.medical_records.domain.exceptions.medical_records_exceptions import (
    MedicalRecordNotFoundError,
    SpecialistNotFoundError,
)
from app.modules.medical_records.domain.models.medical_record_and_vaccine import (
    MedicalExamRecord,
    PreventiveScreeningItem,
    SpecialistContact,
    VaccinationEntry,
)
from app.modules.medical_records.domain.services.preventive_screening_calendar_service import (  # noqa: E501
    PreventiveScreeningCalendarService,
)
from app.modules.medical_records.domain.value_objects.record_metadata import (
    AttachmentSpec,
    ExamType,
    SpecialtyType,
    VaccineType,
)


class MedicalRecordsUseCases:
    """Orchestrates use cases for digital medical folder, vaccines, and directory."""

    def __init__(
        self,
        repo: IMedicalRecordsRepository,
        storage: IFileStorage,
        calendar_service: PreventiveScreeningCalendarService | None = None,
    ) -> None:
        self._repo = repo
        self._storage = storage
        self._calendar_service = (
            calendar_service or PreventiveScreeningCalendarService()
        )

    # --- Medical Exams ---

    async def record_medical_exam(
        self,
        user_id: UUID,
        exam_type: ExamType,
        title: str,
        performed_at: date,
        clinic_or_lab: str | None = None,
        notes: str | None = None,
        exam_id: UUID | None = None,
    ) -> MedicalExamRecord:
        now = datetime.now(UTC)
        record = MedicalExamRecord(
            id=exam_id or uuid4(),
            user_id=user_id,
            exam_type=exam_type,
            title=title.strip(),
            performed_at=performed_at,
            clinic_or_lab=clinic_or_lab.strip() if clinic_or_lab else None,
            notes=notes.strip() if notes else None,
            attachment=None,
            created_at=now,
            updated_at=now,
        )
        return await self._repo.save_medical_exam(record)

    async def list_medical_exams(
        self,
        user_id: UUID,
        exam_type: ExamType | None = None,
    ) -> list[MedicalExamRecord]:
        return await self._repo.list_medical_exams(user_id, exam_type=exam_type)

    async def get_medical_exam(
        self,
        user_id: UUID,
        exam_id: UUID,
    ) -> MedicalExamRecord:
        record = await self._repo.get_medical_exam_by_id(exam_id, user_id)
        if not record:
            raise MedicalRecordNotFoundError(str(exam_id))
        return record

    async def generate_exam_upload_url(
        self,
        user_id: UUID,
        exam_id: UUID,
        file_name: str,
        mime_type: str,
        size_bytes: int,
    ) -> PresignedUploadUrlResponse:
        exam = await self.get_medical_exam(user_id, exam_id)
        spec = AttachmentSpec.create(
            user_id=user_id,
            record_id=exam_id,
            file_name=file_name,
            mime_type=mime_type,
            size_bytes=size_bytes,
        )
        upload_resp = await self._storage.create_presigned_upload_url(
            user_id=user_id,
            record_id=exam_id,
            file_name=spec.file_name,
            mime_type=spec.mime_type,
            max_size_bytes=15 * 1024 * 1024,
            expires_in_seconds=900,
        )
        exam.attachment = spec
        exam.updated_at = datetime.now(UTC)
        await self._repo.save_medical_exam(exam)
        return upload_resp

    async def get_exam_download_url(
        self,
        user_id: UUID,
        exam_id: UUID,
    ) -> str:
        exam = await self.get_medical_exam(user_id, exam_id)
        if not exam.attachment:
            raise MedicalRecordNotFoundError(
                f"El estudio {exam_id} no cuenta con archivo adjunto."
            )
        return await self._storage.create_presigned_download_url(
            user_id=user_id,
            storage_key=exam.attachment.storage_key,
            expires_in_seconds=900,
        )

    async def delete_medical_exam(
        self,
        user_id: UUID,
        exam_id: UUID,
    ) -> bool:
        exam = await self._repo.get_medical_exam_by_id(exam_id, user_id)
        if not exam:
            raise MedicalRecordNotFoundError(str(exam_id))
        return await self._repo.delete_medical_exam(exam_id, user_id)

    # --- Preventive Calendar ---

    async def get_preventive_calendar(
        self,
        user_id: UUID,
        user_age: int,
        life_stage: LifeStage,
        diagnosed_conditions: list[str] | None = None,
    ) -> list[PreventiveScreeningItem]:
        past_exams = await self._repo.list_medical_exams(user_id)
        return self._calendar_service.compute_due_screenings(
            user_age=user_age,
            life_stage=life_stage,
            diagnosed_conditions=diagnosed_conditions or [],
            past_exams=past_exams,
        )

    # --- Vaccinations ---

    async def record_vaccination(
        self,
        user_id: UUID,
        vaccine_type: VaccineType,
        dose_number: int,
        administered_at: date,
        lot_number: str | None = None,
        administrator_clinic: str | None = None,
        notes: str | None = None,
    ) -> VaccinationEntry:
        entry = VaccinationEntry(
            id=uuid4(),
            user_id=user_id,
            vaccine_type=vaccine_type,
            dose_number=dose_number,
            administered_at=administered_at,
            lot_number=lot_number.strip() if lot_number else None,
            administrator_clinic=(
                administrator_clinic.strip() if administrator_clinic else None
            ),
            notes=notes.strip() if notes else None,
            created_at=datetime.now(UTC),
        )
        return await self._repo.save_vaccination(entry)

    async def list_vaccinations(
        self,
        user_id: UUID,
    ) -> list[VaccinationEntry]:
        return await self._repo.list_vaccinations(user_id)

    # --- Specialists ---

    async def save_specialist(
        self,
        user_id: UUID,
        full_name: str,
        specialty: SpecialtyType,
        clinic_name: str | None = None,
        phone_number: str | None = None,
        email: str | None = None,
        notes: str | None = None,
        is_favorite: bool = False,
        specialist_id: UUID | None = None,
    ) -> SpecialistContact:
        contact = SpecialistContact(
            id=specialist_id or uuid4(),
            user_id=user_id,
            full_name=full_name.strip(),
            specialty=specialty,
            clinic_name=clinic_name.strip() if clinic_name else None,
            phone_number=phone_number.strip() if phone_number else None,
            email=email.strip().lower() if email else None,
            notes=notes.strip() if notes else None,
            is_favorite=is_favorite,
            created_at=datetime.now(UTC),
        )
        return await self._repo.save_specialist(contact)

    async def list_specialists(
        self,
        user_id: UUID,
    ) -> list[SpecialistContact]:
        return await self._repo.list_specialists(user_id)

    async def delete_specialist(
        self,
        user_id: UUID,
        specialist_id: UUID,
    ) -> bool:
        contact = await self._repo.get_specialist_by_id(specialist_id, user_id)
        if not contact:
            raise SpecialistNotFoundError(str(specialist_id))
        return await self._repo.delete_specialist(specialist_id, user_id)
