from uuid import UUID

from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.medical_records.application.ports.medical_records_repository_port import (  # noqa: E501
    IMedicalRecordsRepository,
)
from app.modules.medical_records.domain.models.medical_record_and_vaccine import (
    MedicalExamRecord,
    SpecialistContact,
    VaccinationEntry,
)
from app.modules.medical_records.domain.value_objects.record_metadata import (
    AttachmentSpec,
    ExamType,
    SpecialtyType,
    VaccineType,
)
from app.modules.medical_records.infrastructure.orm.medical_records_orm import (
    MedicalExamRecordOrm,
    SpecialistContactOrm,
    VaccinationEntryOrm,
)


class PostgresMedicalRecordsRepository(IMedicalRecordsRepository):
    """PostgreSQL adapter for medical records, vaccines, and specialists."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    @staticmethod
    def _to_domain_exam(orm: MedicalExamRecordOrm) -> MedicalExamRecord:
        attachment: AttachmentSpec | None = None
        if (
            orm.attachment_file_name
            and orm.attachment_mime_type
            and orm.attachment_size_bytes is not None
            and orm.attachment_storage_key
        ):
            attachment = AttachmentSpec(
                file_name=orm.attachment_file_name,
                mime_type=orm.attachment_mime_type,
                size_bytes=orm.attachment_size_bytes,
                storage_key=orm.attachment_storage_key,
            )
        return MedicalExamRecord(
            id=orm.id,
            user_id=orm.user_id,
            exam_type=ExamType(orm.exam_type),
            title=orm.title,
            performed_at=orm.performed_at,
            clinic_or_lab=orm.clinic_or_lab,
            notes=orm.notes,
            attachment=attachment,
            created_at=orm.created_at,
            updated_at=orm.updated_at,
        )

    async def save_medical_exam(self, exam: MedicalExamRecord) -> MedicalExamRecord:
        orm = MedicalExamRecordOrm(
            id=exam.id,
            user_id=exam.user_id,
            exam_type=exam.exam_type.value,
            title=exam.title,
            performed_at=exam.performed_at,
            clinic_or_lab=exam.clinic_or_lab,
            notes=exam.notes,
            attachment_file_name=exam.attachment.file_name if exam.attachment else None,
            attachment_mime_type=exam.attachment.mime_type if exam.attachment else None,
            attachment_size_bytes=exam.attachment.size_bytes
            if exam.attachment
            else None,
            attachment_storage_key=exam.attachment.storage_key
            if exam.attachment
            else None,
            created_at=exam.created_at,
            updated_at=exam.updated_at,
        )
        await self._session.merge(orm)
        await self._session.commit()
        return exam

    async def get_medical_exam_by_id(
        self, exam_id: UUID, user_id: UUID
    ) -> MedicalExamRecord | None:
        stmt = select(MedicalExamRecordOrm).where(
            MedicalExamRecordOrm.id == exam_id,
            MedicalExamRecordOrm.user_id == user_id,
        )
        res = await self._session.execute(stmt)
        record = res.scalar_one_or_none()
        if not record:
            return None
        return self._to_domain_exam(record)

    async def list_medical_exams(
        self, user_id: UUID, exam_type: ExamType | None = None
    ) -> list[MedicalExamRecord]:
        stmt = select(MedicalExamRecordOrm).where(
            MedicalExamRecordOrm.user_id == user_id
        )
        if exam_type is not None:
            stmt = stmt.where(MedicalExamRecordOrm.exam_type == exam_type.value)
        stmt = stmt.order_by(desc(MedicalExamRecordOrm.performed_at))
        res = await self._session.execute(stmt)
        records = res.scalars().all()
        return [self._to_domain_exam(r) for r in records]

    async def delete_medical_exam(self, exam_id: UUID, user_id: UUID) -> bool:
        stmt = select(MedicalExamRecordOrm).where(
            MedicalExamRecordOrm.id == exam_id,
            MedicalExamRecordOrm.user_id == user_id,
        )
        res = await self._session.execute(stmt)
        record = res.scalar_one_or_none()
        if not record:
            return False
        await self._session.delete(record)
        await self._session.commit()
        return True

    async def save_vaccination(self, vaccination: VaccinationEntry) -> VaccinationEntry:
        orm = VaccinationEntryOrm(
            id=vaccination.id,
            user_id=vaccination.user_id,
            vaccine_type=vaccination.vaccine_type.value,
            dose_number=vaccination.dose_number,
            administered_at=vaccination.administered_at,
            lot_number=vaccination.lot_number,
            administrator_clinic=vaccination.administrator_clinic,
            notes=vaccination.notes,
            created_at=vaccination.created_at,
        )
        await self._session.merge(orm)
        await self._session.commit()
        return vaccination

    async def list_vaccinations(self, user_id: UUID) -> list[VaccinationEntry]:
        stmt = (
            select(VaccinationEntryOrm)
            .where(VaccinationEntryOrm.user_id == user_id)
            .order_by(desc(VaccinationEntryOrm.administered_at))
        )
        res = await self._session.execute(stmt)
        records = res.scalars().all()
        return [
            VaccinationEntry(
                id=r.id,
                user_id=r.user_id,
                vaccine_type=VaccineType(r.vaccine_type),
                dose_number=r.dose_number,
                administered_at=r.administered_at,
                lot_number=r.lot_number,
                administrator_clinic=r.administrator_clinic,
                notes=r.notes,
                created_at=r.created_at,
            )
            for r in records
        ]

    async def save_specialist(self, specialist: SpecialistContact) -> SpecialistContact:
        orm = SpecialistContactOrm(
            id=specialist.id,
            user_id=specialist.user_id,
            full_name=specialist.full_name,
            specialty=specialist.specialty.value,
            clinic_name=specialist.clinic_name,
            phone_number=specialist.phone_number,
            email=specialist.email,
            notes=specialist.notes,
            is_favorite=specialist.is_favorite,
            created_at=specialist.created_at,
        )
        await self._session.merge(orm)
        await self._session.commit()
        return specialist

    async def list_specialists(self, user_id: UUID) -> list[SpecialistContact]:
        stmt = (
            select(SpecialistContactOrm)
            .where(SpecialistContactOrm.user_id == user_id)
            .order_by(
                desc(SpecialistContactOrm.is_favorite),
                desc(SpecialistContactOrm.created_at),
            )
        )
        res = await self._session.execute(stmt)
        records = res.scalars().all()
        return [
            SpecialistContact(
                id=r.id,
                user_id=r.user_id,
                full_name=r.full_name,
                specialty=SpecialtyType(r.specialty),
                clinic_name=r.clinic_name,
                phone_number=r.phone_number,
                email=r.email,
                notes=r.notes,
                is_favorite=r.is_favorite,
                created_at=r.created_at,
            )
            for r in records
        ]

    async def get_specialist_by_id(
        self, specialist_id: UUID, user_id: UUID
    ) -> SpecialistContact | None:
        stmt = select(SpecialistContactOrm).where(
            SpecialistContactOrm.id == specialist_id,
            SpecialistContactOrm.user_id == user_id,
        )
        res = await self._session.execute(stmt)
        record = res.scalar_one_or_none()
        if not record:
            return None
        return SpecialistContact(
            id=record.id,
            user_id=record.user_id,
            full_name=record.full_name,
            specialty=SpecialtyType(record.specialty),
            clinic_name=record.clinic_name,
            phone_number=record.phone_number,
            email=record.email,
            notes=record.notes,
            is_favorite=record.is_favorite,
            created_at=record.created_at,
        )

    async def delete_specialist(self, specialist_id: UUID, user_id: UUID) -> bool:
        stmt = select(SpecialistContactOrm).where(
            SpecialistContactOrm.id == specialist_id,
            SpecialistContactOrm.user_id == user_id,
        )
        res = await self._session.execute(stmt)
        record = res.scalar_one_or_none()
        if not record:
            return False
        await self._session.delete(record)
        await self._session.commit()
        return True
