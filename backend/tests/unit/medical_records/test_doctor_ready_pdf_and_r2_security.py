from datetime import UTC, date, datetime
from uuid import uuid4

import pytest

from app.core.config import Settings
from app.modules.identity.domain.value_objects.life_stage import LifeStage
from app.modules.medical_records.application.dtos.doctor_report_dtos import (
    CycleReportSummary,
    DoctorReportData,
    TreatmentAdherenceItem,
    VitalsReportSummary,
)
from app.modules.medical_records.domain.exceptions.medical_records_exceptions import (
    InvalidAttachmentError,
    MedicalRecordNotFoundError,
)
from app.modules.medical_records.infrastructure.adapters.cloudflare_r2_storage_adapter import (  # noqa: E501
    CloudflareR2StorageAdapter,
)
from app.modules.medical_records.infrastructure.adapters.weasyprint_report_renderer import (  # noqa: E501
    WeasyPrintReportRenderer,
    safe_local_url_fetcher,
)


@pytest.fixture
def mock_settings() -> Settings:
    return Settings(
        r2_account_id="test-account-id",
        r2_access_key_id="test-key-id",
        r2_secret_access_key="test-secret-key",
        r2_bucket_name="cora-medical-documents",
        r2_endpoint_url="https://test.r2.cloudflarestorage.com",
    )


@pytest.mark.asyncio
async def test_r2_storage_adapter_presigned_upload_url(mock_settings: Settings) -> None:
    adapter = CloudflareR2StorageAdapter(settings=mock_settings)
    user_id = uuid4()
    record_id = uuid4()

    response = await adapter.create_presigned_upload_url(
        user_id=user_id,
        record_id=record_id,
        file_name="analisis_sangre.pdf",
        mime_type="application/pdf",
        expires_in_seconds=900,
    )

    assert response.expires_in_seconds <= 900
    assert (
        response.storage_key
        == f"users/{user_id}/records/{record_id}/analisis_sangre.pdf"
    )
    assert "users/" in response.upload_url
    assert (
        "X-Amz-Expires=900" in response.upload_url or "test.r2" in response.upload_url
    )


@pytest.mark.asyncio
async def test_r2_storage_adapter_presigned_download_url_and_idor_protection(
    mock_settings: Settings,
) -> None:
    adapter = CloudflareR2StorageAdapter(settings=mock_settings)
    user_id = uuid4()
    other_user_id = uuid4()
    record_id = uuid4()

    valid_key = f"users/{user_id}/records/{record_id}/ecografia.png"
    download_url = await adapter.create_presigned_download_url(
        user_id=user_id,
        storage_key=valid_key,
        expires_in_seconds=900,
    )
    assert "users/" in download_url
    assert str(user_id) in download_url

    # Anti-IDOR: Requesting another user's key raises MedicalRecordNotFoundError
    attacker_key = f"users/{other_user_id}/records/{record_id}/ecografia.png"
    with pytest.raises(MedicalRecordNotFoundError):
        await adapter.create_presigned_download_url(
            user_id=user_id,
            storage_key=attacker_key,
            expires_in_seconds=900,
        )

    # Path traversal key check
    traversal_key = f"users/{user_id}/../../etc/passwd"
    with pytest.raises(InvalidAttachmentError):
        await adapter.create_presigned_download_url(
            user_id=user_id,
            storage_key=traversal_key,
            expires_in_seconds=900,
        )


def test_weasyprint_safe_local_url_fetcher_blocks_external_ssrf() -> None:
    # Any external http / https URL must raise ValueError or return blocked payload
    with pytest.raises(ValueError) as exc_info:
        safe_local_url_fetcher("http://169.254.169.254/latest/meta-data/")
    assert "SSRF" in str(exc_info.value) or "Acceso bloqueado" in str(exc_info.value)

    with pytest.raises(ValueError):
        safe_local_url_fetcher("https://evil-external-tracker.com/pixel.png")


@pytest.mark.asyncio
async def test_doctor_ready_pdf_renders_valid_pdf_with_rich_history() -> None:
    renderer = WeasyPrintReportRenderer()
    user_id = uuid4()

    report_data = DoctorReportData(
        user_id=user_id,
        patient_name="Ana Patricia Morales",
        patient_age=34,
        life_stage=LifeStage.REGULAR_ADULT,
        generated_at=datetime(2026, 6, 1, 10, 0, tzinfo=UTC),
        reporting_window_months=6,
        cycle_summary=CycleReportSummary(
            total_cycles_logged=6,
            average_length_days=29.2,
            min_length_days=27,
            max_length_days=31,
            variability_days=4,
            is_regular=True,
            atypical_alerts_detected=[],
            last_period_date=date(2026, 5, 12),
        ),
        treatment_summary=[
            TreatmentAdherenceItem(
                medication_name="Metformina",
                dosage="850 mg",
                frequency="Cada 12 horas",
                adherence_percentage=94.5,
                status="active",
            ),
            TreatmentAdherenceItem(
                medication_name="Ácido Fólico",
                dosage="5 mg",
                frequency="Diario",
                adherence_percentage=100.0,
                status="active",
            ),
        ],
        vitals_summary=VitalsReportSummary(
            latest_blood_pressure="118/76 mmHg",
            mean_systolic=116,
            mean_diastolic=74,
            fasting_glucose_mg_dl=88.0,
            bmi=22.4,
            weight_kg=61.5,
        ),
        stage_specific_notes=[
            "Etapa reproductiva regular sin irregularidades menstruales persistentes.",
            "Consistencia en fase lútea promedio de 13 días.",
        ],
        specialist_notes=(
            "Nota para consulta: Paciente reporta leve dismenorrea en día 1 del ciclo, "
            "controlada con calor local y descanso."
        ),
    )

    pdf_bytes = await renderer.render_doctor_ready_pdf(report_data)
    assert isinstance(pdf_bytes, bytes)
    assert len(pdf_bytes) > 200
    assert pdf_bytes.startswith(b"%PDF-")
    assert b"%%EOF" in pdf_bytes[-1024:]


@pytest.mark.asyncio
async def test_doctor_ready_pdf_renders_cleanly_with_sparse_data() -> None:
    renderer = WeasyPrintReportRenderer()
    user_id = uuid4()

    # User registered 3 days ago with almost no data
    sparse_data = DoctorReportData(
        user_id=user_id,
        patient_name="Fernanda Gómez (Nueva Usuaria)",
        patient_age=24,
        life_stage=LifeStage.REGULAR_ADULT,
        generated_at=datetime(2026, 6, 1, 10, 0, tzinfo=UTC),
        reporting_window_months=3,
        cycle_summary=None,
        treatment_summary=[],
        vitals_summary=None,
        stage_specific_notes=[],
        specialist_notes=None,
    )

    pdf_bytes = await renderer.render_doctor_ready_pdf(sparse_data)
    assert isinstance(pdf_bytes, bytes)
    assert pdf_bytes.startswith(b"%PDF-")
    assert b"%%EOF" in pdf_bytes[-1024:]


@pytest.mark.asyncio
async def test_doctor_ready_pdf_escapes_xss_payloads() -> None:
    renderer = WeasyPrintReportRenderer()
    user_id = uuid4()

    malicious_data = DoctorReportData(
        user_id=user_id,
        patient_name="<script>alert('xss')</script>María",
        patient_age=30,
        life_stage=LifeStage.REGULAR_ADULT,
        generated_at=datetime.now(UTC),
        reporting_window_months=3,
        cycle_summary=None,
        treatment_summary=[],
        vitals_summary=None,
        stage_specific_notes=["<img src=x onerror=alert(1)> Inyección evitada"],
        specialist_notes="<b onmouseover=evil()>Notas maliciosas</b>",
    )

    rendered_html = renderer.render_html_preview(malicious_data)
    assert "<script>" not in rendered_html
    assert "&lt;script&gt;alert(" in rendered_html
    assert "&lt;/script&gt;" in rendered_html
    assert "<img src=x onerror=alert(1)>" not in rendered_html
    assert "&lt;img src=x onerror=alert(1)&gt;" in rendered_html
