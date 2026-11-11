from datetime import UTC, date, datetime
from uuid import uuid4

import pytest

from app.modules.identity.domain.value_objects.life_stage import LifeStage
from app.modules.medical_records.domain.exceptions.medical_records_exceptions import (
    InvalidAttachmentError,
)
from app.modules.medical_records.domain.models.medical_record_and_vaccine import (
    MedicalExamRecord,
    SpecialistContact,
    VaccinationEntry,
)
from app.modules.medical_records.domain.services.preventive_screening_calendar_service import (  # noqa: E501
    PreventiveScreeningCalendarService,
)
from app.modules.medical_records.domain.value_objects.record_metadata import (
    AttachmentSpec,
    ExamType,
    ScreeningUrgency,
    SpecialtyType,
    VaccineType,
)


def test_attachment_spec_validates_allowed_mime_types() -> None:
    user_id = uuid4()
    record_id = uuid4()

    # Valid PDF
    spec_pdf = AttachmentSpec.create(
        user_id=user_id,
        record_id=record_id,
        file_name="ultrasound_report.pdf",
        mime_type="application/pdf",
        size_bytes=2 * 1024 * 1024,
    )
    assert spec_pdf.file_name == "ultrasound_report.pdf"
    assert spec_pdf.mime_type == "application/pdf"
    assert (
        spec_pdf.storage_key
        == f"users/{user_id}/records/{record_id}/ultrasound_report.pdf"
    )

    # Valid JPEG
    spec_jpg = AttachmentSpec.create(
        user_id=user_id,
        record_id=record_id,
        file_name="scan.jpg",
        mime_type="image/jpeg",
        size_bytes=500_000,
    )
    assert spec_jpg.mime_type == "image/jpeg"

    # Valid PNG
    spec_png = AttachmentSpec.create(
        user_id=user_id,
        record_id=record_id,
        file_name="mammogram.png",
        mime_type="image/png",
        size_bytes=1_200_000,
    )
    assert spec_png.mime_type == "image/png"

    # Valid WebP
    spec_webp = AttachmentSpec.create(
        user_id=user_id,
        record_id=record_id,
        file_name="dxa.webp",
        mime_type="image/webp",
        size_bytes=800_000,
    )
    assert spec_webp.mime_type == "image/webp"


def test_attachment_spec_rejects_disallowed_mime_or_executable() -> None:
    user_id = uuid4()
    record_id = uuid4()

    with pytest.raises(InvalidAttachmentError) as exc_info:
        AttachmentSpec.create(
            user_id=user_id,
            record_id=record_id,
            file_name="malicious.exe",
            mime_type="application/x-msdownload",
            size_bytes=1024,
        )
    assert "MIME" in exc_info.value.detail or "Tipo de archivo" in exc_info.value.detail

    with pytest.raises(InvalidAttachmentError):
        AttachmentSpec.create(
            user_id=user_id,
            record_id=record_id,
            file_name="script.html",
            mime_type="text/html",
            size_bytes=1024,
        )


def test_attachment_spec_rejects_oversized_file() -> None:
    user_id = uuid4()
    record_id = uuid4()
    oversized = 16 * 1024 * 1024  # 16 MB > 15 MB limit

    with pytest.raises(InvalidAttachmentError) as exc_info:
        AttachmentSpec.create(
            user_id=user_id,
            record_id=record_id,
            file_name="huge_scan.pdf",
            mime_type="application/pdf",
            size_bytes=oversized,
        )
    assert "15 MB" in exc_info.value.detail or "15" in exc_info.value.detail


def test_attachment_spec_rejects_empty_or_path_traversal_filename() -> None:
    user_id = uuid4()
    record_id = uuid4()

    with pytest.raises(InvalidAttachmentError):
        AttachmentSpec.create(
            user_id=user_id,
            record_id=record_id,
            file_name="",
            mime_type="application/pdf",
            size_bytes=1024,
        )

    with pytest.raises(InvalidAttachmentError):
        AttachmentSpec.create(
            user_id=user_id,
            record_id=record_id,
            file_name="../../../etc/passwd",
            mime_type="application/pdf",
            size_bytes=1024,
        )


def test_medical_exam_record_creation_and_immutability() -> None:
    user_id = uuid4()
    exam_id = uuid4()
    now = datetime.now(UTC)

    record = MedicalExamRecord(
        id=exam_id,
        user_id=user_id,
        exam_type=ExamType.MAMMOGRAM,
        title="Mamografía Digital Bilateral",
        performed_at=date(2026, 3, 15),
        clinic_or_lab="Hospital Ángeles",
        notes="BI-RADS 1: Hallazgos negativos/benignos.",
        attachment=None,
        created_at=now,
        updated_at=now,
    )
    assert record.id == exam_id
    assert record.exam_type == ExamType.MAMMOGRAM
    assert record.title == "Mamografía Digital Bilateral"
    assert record.performed_at == date(2026, 3, 15)


def test_vaccination_entry_and_specialist_contact() -> None:
    user_id = uuid4()
    vax_id = uuid4()
    vax = VaccinationEntry(
        id=vax_id,
        user_id=user_id,
        vaccine_type=VaccineType.TDAP,
        dose_number=1,
        administered_at=date(2026, 4, 10),
        lot_number="TD-9942",
        administrator_clinic="Centro de Salud San Ángel",
        notes="Dosis de refuerzo en tercer trimestre",
        created_at=datetime.now(UTC),
    )
    assert vax.vaccine_type == VaccineType.TDAP
    assert vax.dose_number == 1

    spec_id = uuid4()
    specialist = SpecialistContact(
        id=spec_id,
        user_id=user_id,
        full_name="Dra. Mariana Garza",
        specialty=SpecialtyType.GYNECOLOGY,
        clinic_name="Clínica Ginecológica del Valle",
        phone_number="+525512345678",
        email="dra.garza@vallegin.mx",
        notes="Ginecóloga de cabecera",
        is_favorite=True,
        created_at=datetime.now(UTC),
    )
    assert specialist.specialty == SpecialtyType.GYNECOLOGY
    assert specialist.is_favorite is True


@pytest.mark.parametrize(
    ("age", "life_stage", "expected_screening_codes"),
    [
        (
            16,
            LifeStage.ADOLESCENCE,
            ["HPV_VACCINE"],
        ),
        (
            27,
            LifeStage.REGULAR_ADULT,
            ["PAP_SMEAR", "BREAST_SELF_AWARENESS"],
        ),
        (
            32,
            LifeStage.PREGNANCY,
            ["PRENATAL_ULTRASOUND", "TDAP_PREGNANCY", "GESTATIONAL_DIABETES_SCREENING"],
        ),
        (
            48,
            LifeStage.PERIMENOPAUSE,
            ["MAMMOGRAM", "CARDIOMETABOLIC_PANEL", "PAP_OR_HPV"],
        ),
        (
            67,
            LifeStage.SENIOR_VITALITY,
            [
                "BONE_DENSITOMETRY_DEXA",
                "SHINGLES_VACCINE",
                "CARDIOMETABOLIC_PANEL",
                "MAMMOGRAM",
            ],
        ),
    ],
)
def test_preventive_screening_calendar_generates_guideline_based_items(
    age: int,
    life_stage: LifeStage,
    expected_screening_codes: list[str],
) -> None:
    service = PreventiveScreeningCalendarService()
    screenings = service.compute_due_screenings(
        user_age=age,
        life_stage=life_stage,
        diagnosed_conditions=[],
        past_exams=[],
    )
    screening_codes = [s.screening_code for s in screenings]
    for code in expected_screening_codes:
        assert code in screening_codes, (
            f"Expected {code} in {screening_codes} for age {age}"
        )


def test_preventive_screening_updates_urgency_based_on_recent_exam() -> None:
    service = PreventiveScreeningCalendarService()
    user_id = uuid4()

    # User aged 48 without past exams -> MAMMOGRAM is DUE_NOW
    screenings_without_exam = service.compute_due_screenings(
        user_age=48,
        life_stage=LifeStage.PERIMENOPAUSE,
        diagnosed_conditions=[],
        past_exams=[],
    )
    mammo_item = next(
        s for s in screenings_without_exam if s.screening_code == "MAMMOGRAM"
    )
    assert mammo_item.urgency == ScreeningUrgency.DUE_NOW

    # User had mammogram 3 months ago -> MAMMOGRAM is UP_TO_DATE
    recent_exam = MedicalExamRecord(
        id=uuid4(),
        user_id=user_id,
        exam_type=ExamType.MAMMOGRAM,
        title="Mamografía Bilateral Reciente",
        performed_at=date(2026, 2, 1),
        clinic_or_lab="Hospital Español",
        notes="Normal",
        attachment=None,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )
    screenings_with_exam = service.compute_due_screenings(
        user_age=48,
        life_stage=LifeStage.PERIMENOPAUSE,
        diagnosed_conditions=[],
        past_exams=[recent_exam],
        reference_date=date(2026, 5, 1),
    )
    mammo_recent = next(
        s for s in screenings_with_exam if s.screening_code == "MAMMOGRAM"
    )
    assert mammo_recent.urgency == ScreeningUrgency.UP_TO_DATE
    assert mammo_recent.last_performed_at == date(2026, 2, 1)
