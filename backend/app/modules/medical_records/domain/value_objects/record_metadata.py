from dataclasses import dataclass
from enum import StrEnum
from pathlib import PurePosixPath
from uuid import UUID

from app.modules.medical_records.domain.exceptions.medical_records_exceptions import (
    InvalidAttachmentError,
)

MAX_ATTACHMENT_SIZE_BYTES = 15 * 1024 * 1024  # 15 MB
ALLOWED_MIME_TYPES = frozenset(
    {
        "application/pdf",
        "image/jpeg",
        "image/png",
        "image/webp",
    }
)


class ExamType(StrEnum):
    PAP_SMEAR = "pap_smear"
    HPV_TEST = "hpv_test"
    PELVIC_ULTRASOUND = "pelvic_ultrasound"
    BREAST_ULTRASOUND = "breast_ultrasound"
    MAMMOGRAM = "mammogram"
    BONE_DENSITOMETRY_DEXA = "bone_densitometry_dexa"
    BLOOD_PANEL = "blood_panel"
    PRENATAL_ULTRASOUND = "prenatal_ultrasound"
    OTHER = "other"


class VaccineType(StrEnum):
    HPV = "hpv"
    TDAP = "tdap"
    RUBELLA_MMR = "rubella_mmr"
    INFLUENZA = "influenza"
    SHINGLES_ZOSTER = "shingles_zoster"
    HEPATITIS_B = "hepatitis_b"
    COVID19 = "covid19"
    OTHER = "other"


class SpecialtyType(StrEnum):
    GYNECOLOGY = "gynecology"
    OBSTETRICS = "obstetrics"
    UROLOGY = "urology"
    ENDOCRINOLOGY = "endocrinology"
    GENERAL_MEDICINE = "general_medicine"
    NUTRITION = "nutrition"
    PSYCHOLOGY = "psychology"
    GERIATRICS = "geriatrics"
    OTHER = "other"


class ScreeningUrgency(StrEnum):
    DUE_NOW = "due_now"
    UPCOMING = "upcoming"
    UP_TO_DATE = "up_to_date"


class ScreeningStatus(StrEnum):
    PENDING = "pending"
    COMPLETED = "completed"
    OVERDUE = "overdue"


@dataclass(frozen=True)
class AttachmentSpec:
    file_name: str
    mime_type: str
    size_bytes: int
    storage_key: str

    @classmethod
    def create(
        cls,
        user_id: UUID,
        record_id: UUID,
        file_name: str,
        mime_type: str,
        size_bytes: int,
    ) -> "AttachmentSpec":
        stripped_name = file_name.strip()
        if not stripped_name:
            raise InvalidAttachmentError("El nombre del archivo no puede estar vacío.")

        posix_path = PurePosixPath(stripped_name)
        if ".." in posix_path.parts or posix_path.is_absolute():
            raise InvalidAttachmentError(
                "Nombre de archivo inseguro o ruta no permitida."
            )

        safe_filename = posix_path.name
        if not safe_filename:
            raise InvalidAttachmentError("Nombre de archivo inválido.")

        norm_mime = mime_type.strip().lower()
        if norm_mime not in ALLOWED_MIME_TYPES:
            raise InvalidAttachmentError(
                f"Tipo de archivo no permitido: {mime_type}. "
                "Formatos admitidos: PDF, JPEG, PNG y WebP."
            )

        if size_bytes <= 0:
            raise InvalidAttachmentError("El archivo no puede estar vacío.")

        if size_bytes > MAX_ATTACHMENT_SIZE_BYTES:
            max_mb = MAX_ATTACHMENT_SIZE_BYTES // (1024 * 1024)
            raise InvalidAttachmentError(
                f"El tamaño del archivo excede el límite máximo de {max_mb} MB."
            )

        storage_key = f"users/{user_id}/records/{record_id}/{safe_filename}"

        return cls(
            file_name=safe_filename,
            mime_type=norm_mime,
            size_bytes=size_bytes,
            storage_key=storage_key,
        )
