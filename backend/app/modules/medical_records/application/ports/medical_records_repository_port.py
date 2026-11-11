from typing import Protocol
from uuid import UUID

from app.modules.medical_records.domain.models.medical_record_and_vaccine import (
    MedicalExamRecord,
    SpecialistContact,
    VaccinationEntry,
)
from app.modules.medical_records.domain.value_objects.record_metadata import ExamType


class IMedicalRecordsRepository(Protocol):
    """Port for medical records, vaccinations, and specialist directory persistence."""

    async def save_medical_exam(self, exam: MedicalExamRecord) -> MedicalExamRecord: ...

    async def get_medical_exam_by_id(
        self, exam_id: UUID, user_id: UUID
    ) -> MedicalExamRecord | None: ...

    async def list_medical_exams(
        self, user_id: UUID, exam_type: ExamType | None = None
    ) -> list[MedicalExamRecord]: ...

    async def delete_medical_exam(self, exam_id: UUID, user_id: UUID) -> bool: ...

    async def save_vaccination(
        self, vaccination: VaccinationEntry
    ) -> VaccinationEntry: ...

    async def list_vaccinations(self, user_id: UUID) -> list[VaccinationEntry]: ...

    async def save_specialist(
        self, specialist: SpecialistContact
    ) -> SpecialistContact: ...

    async def list_specialists(self, user_id: UUID) -> list[SpecialistContact]: ...

    async def get_specialist_by_id(
        self, specialist_id: UUID, user_id: UUID
    ) -> SpecialistContact | None: ...

    async def delete_specialist(self, specialist_id: UUID, user_id: UUID) -> bool: ...
