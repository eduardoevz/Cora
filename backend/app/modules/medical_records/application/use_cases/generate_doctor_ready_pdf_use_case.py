from datetime import UTC, datetime, timedelta
from uuid import UUID

from app.modules.clinical_tracking.application.ports.cycle_repository_port import (
    ICycleRepository,
)
from app.modules.identity.application.ports.user_profile_repository_port import (
    IUserProfileRepository,
)
from app.modules.identity.domain.exceptions.identity_exceptions import (
    UserProfileNotFoundError,
)
from app.modules.identity.domain.value_objects.life_stage import LifeStage
from app.modules.maternal_care.application.ports.pregnancy_repository_port import (
    IPregnancyRepository,
)
from app.modules.mature_health.application.ports.mature_health_repository_port import (
    IMatureHealthRepository,
)
from app.modules.medical_records.application.dtos.doctor_report_dtos import (
    CycleReportSummary,
    DoctorReportData,
    TreatmentAdherenceItem,
    VitalsReportSummary,
)
from app.modules.medical_records.application.ports.clinical_report_renderer_port import (  # noqa: E501
    IClinicalReportRenderer,
)
from app.modules.treatments.application.ports.treatment_repository_port import (
    ITreatmentRepository,
)


class GenerateDoctorReadyPdfUseCase:
    """Consolidates cross-bounded clinical data and renders a Doctor-Ready PDF."""

    def __init__(
        self,
        profile_repo: IUserProfileRepository,
        report_renderer: IClinicalReportRenderer,
        cycle_repo: ICycleRepository | None = None,
        treatment_repo: ITreatmentRepository | None = None,
        pregnancy_repo: IPregnancyRepository | None = None,
        mature_health_repo: IMatureHealthRepository | None = None,
    ) -> None:
        self._profile_repo = profile_repo
        self._renderer = report_renderer
        self._cycle_repo = cycle_repo
        self._treatment_repo = treatment_repo
        self._pregnancy_repo = pregnancy_repo
        self._mature_health_repo = mature_health_repo

    async def execute(
        self,
        user_id: UUID,
        reporting_window_months: int = 6,
        specialist_notes: str | None = None,
    ) -> bytes:
        profile = await self._profile_repo.get_by_id(user_id)
        if not profile:
            raise UserProfileNotFoundError(f"User {user_id} not found")

        now = datetime.now(UTC)
        patient_age = (
            now.year - profile.onboarding_context.birth_year
            if profile.onboarding_context
            else 30
        )
        patient_name = f"{profile.first_name} {profile.last_name}".strip()
        life_stage = profile.current_life_stage

        cutoff_date = (now - timedelta(days=reporting_window_months * 30)).date()

        # 1. Cycle Data
        cycle_summary: CycleReportSummary | None = None
        if self._cycle_repo:
            cycles = await self._cycle_repo.list_cycles(str(user_id), limit=12)
            recent_cycles = [
                c
                for c in cycles
                if c.start_date >= cutoff_date and c.cycle_length_days is not None
            ]
            if recent_cycles:
                lengths = [
                    c.cycle_length_days for c in recent_cycles if c.cycle_length_days
                ]
                avg_length = round(sum(lengths) / len(lengths), 1)
                min_len = min(lengths)
                max_len = max(lengths)
                variability = max_len - min_len
                is_reg = variability <= 7 and 24 <= avg_length <= 38
                cycle_summary = CycleReportSummary(
                    total_cycles_logged=len(recent_cycles),
                    average_length_days=avg_length,
                    min_length_days=min_len,
                    max_length_days=max_len,
                    variability_days=variability,
                    is_regular=is_reg,
                    atypical_alerts_detected=[],
                    last_period_date=recent_cycles[0].start_date,
                )

        # 2. Treatments Data
        treatment_items: list[TreatmentAdherenceItem] = []
        if self._treatment_repo:
            regimens = await self._treatment_repo.get_regimens(str(user_id))
            for reg in regimens:
                freq_str = (
                    f"{reg.schedule.schedule_type.value} "
                    f"({reg.schedule.scheduled_time})"
                )
                treatment_items.append(
                    TreatmentAdherenceItem(
                        medication_name=reg.name,
                        dosage=reg.dosage,
                        frequency=freq_str,
                        adherence_percentage=100.0,
                        status="Activo" if reg.is_active else "Inactivo",
                    )
                )

        # 3. Vitals & Stage Specifics
        vitals_summary: VitalsReportSummary | None = None
        stage_notes: list[str] = []

        if life_stage == LifeStage.PREGNANCY:
            stage_notes.append("Paciente en seguimiento de embarazo activo.")
        elif life_stage == LifeStage.POSTPARTUM:
            stage_notes.append("Seguimiento puerperal y recuperación posparto.")
        elif life_stage in (LifeStage.PERIMENOPAUSE, LifeStage.SENIOR_VITALITY):
            stage_notes.append(
                "Evaluación de transición hormonal y salud ósea/cardiometabólica."
            )

        # Query mature health cardiometabolic if available
        if self._mature_health_repo:
            cardio_res = (
                await self._mature_health_repo.get_latest_cardiometabolic_panel(user_id)
            )
            if cardio_res:
                cardio, _, _ = cardio_res
                bp_str = "N/D"
                if cardio.systolic_bp and cardio.diastolic_bp:
                    bp_str = f"{cardio.systolic_bp}/{cardio.diastolic_bp} mmHg"
                vitals_summary = VitalsReportSummary(
                    latest_blood_pressure=bp_str,
                    mean_systolic=cardio.systolic_bp,
                    mean_diastolic=cardio.diastolic_bp,
                    fasting_glucose_mg_dl=float(cardio.fasting_glucose_mg_dl)
                    if cardio.fasting_glucose_mg_dl
                    else None,
                    bmi=None,
                    weight_kg=None,
                )

        report_data = DoctorReportData(
            user_id=user_id,
            patient_name=patient_name,
            patient_age=patient_age,
            life_stage=life_stage,
            generated_at=now,
            reporting_window_months=reporting_window_months,
            cycle_summary=cycle_summary,
            treatment_summary=treatment_items,
            vitals_summary=vitals_summary,
            stage_specific_notes=stage_notes,
            specialist_notes=specialist_notes,
        )

        return await self._renderer.render_doctor_ready_pdf(report_data)
