import uuid
from datetime import UTC, date, datetime
from decimal import Decimal
from typing import Any

from app.core.errors import EntityNotFoundError
from app.modules.maternal_care.application.dtos.pregnancy_dtos import (
    CreatePregnancyEpisodeDTO,
    CreatePrenatalAppointmentDTO,
    LogContractionSessionDTO,
    LogKickSessionDTO,
    LogMaternalVitalsDTO,
    SaveBirthPlanDTO,
)
from app.modules.maternal_care.application.ports.pregnancy_repository_port import (
    IPregnancyRepository,
)
from app.modules.maternal_care.domain.exceptions.maternal_care_exceptions import (
    PregnancyEpisodeValidationError,
)
from app.modules.maternal_care.domain.models.pregnancy_episode import (
    BirthPlanPreference,
    PregnancyEpisode,
    PrenatalAppointment,
)
from app.modules.maternal_care.domain.services.contraction_and_kick_analyzer import (
    ContractionAndKickAnalyzer,
    ContractionEvent,
    ContractionIntensity,
    ContractionSession,
    KickSession,
)
from app.modules.maternal_care.domain.services.fetal_weekly_milestones_catalog import (
    FetalWeeklyMilestonesCatalog,
)
from app.modules.maternal_care.domain.services.maternal_risk_evaluator import (
    MaternalRiskEvaluator,
)
from app.modules.maternal_care.domain.value_objects.maternal_vitals import (
    BloodPressure,
    CapillaryGlucoseReading,
    GlucoseTiming,
    MaternalSymptom,
    MaternalSymptomType,
)


class CreatePregnancyEpisodeUseCase:
    def __init__(self, repo: IPregnancyRepository) -> None:
        self._repo = repo

    async def execute(
        self, user_id: uuid.UUID, dto: CreatePregnancyEpisodeDTO
    ) -> PregnancyEpisode:
        if dto.clinical_edd is not None:
            clinical_edd = dto.clinical_edd
        elif dto.ultrasound_edd is not None:
            clinical_edd = dto.ultrasound_edd
        elif dto.last_menstrual_period is not None:
            clinical_edd = dto.last_menstrual_period + datetime.resolution * 0
            # Naegele: LMP + 280 days
            from datetime import timedelta

            clinical_edd = dto.last_menstrual_period + timedelta(days=280)
        else:
            raise PregnancyEpisodeValidationError(
                "Debe proporcionar al menos la fecha de última menstruación (FUM) "
                "o la fecha probable de parto (FPP)."
            )

        episode = PregnancyEpisode(
            id=uuid.uuid4(),
            user_id=user_id,
            clinical_edd=clinical_edd,
            is_active=True,
            started_at=datetime.now(UTC),
            last_menstrual_period=dto.last_menstrual_period,
            ultrasound_edd=dto.ultrasound_edd,
        )
        return await self._repo.create_episode(episode)


class GetActivePregnancySummaryUseCase:
    def __init__(
        self,
        repo: IPregnancyRepository,
        catalog: FetalWeeklyMilestonesCatalog,
    ) -> None:
        self._repo = repo
        self._catalog = catalog

    async def execute(
        self, user_id: uuid.UUID, as_of: date | None = None
    ) -> dict[str, Any]:
        episode = await self._repo.get_active_episode(user_id)
        if not episode:
            raise EntityNotFoundError(
                "PregnancyEpisode",
                f"No hay un episodio de embarazo activo para el usuario {user_id}",
            )

        ref_date = as_of or datetime.now(UTC).date()
        ga = episode.calculate_gestational_age(ref_date)
        milestone = self._catalog.get_milestone(ga.weeks)
        trimester = episode.current_trimester(ref_date)
        days_remaining = max(0, (episode.clinical_edd - ref_date).days)

        recent_vitals = await self._repo.get_vitals_history(episode.id, limit=5)

        return {
            "episode_id": episode.id,
            "user_id": episode.user_id,
            "clinical_edd": episode.clinical_edd,
            "last_menstrual_period": episode.last_menstrual_period,
            "ultrasound_edd": episode.ultrasound_edd,
            "gestational_weeks": ga.weeks,
            "gestational_days": ga.days,
            "gestational_age_formatted": str(ga),
            "trimester": trimester,
            "days_to_edd": days_remaining,
            "milestone": {
                "week": milestone.week,
                "fruit_comparison": milestone.fruit_or_vegetable_comparison,
                "approximate_length_cm": milestone.approximate_length_cm,
                "approximate_weight_grams": milestone.approximate_weight_grams,
                "anatomical_highlights": milestone.anatomical_highlights,
                "clinical_recommendations": milestone.clinical_recommendations,
                "suggested_tests": milestone.suggested_tests,
            },
            "recent_vitals": recent_vitals,
        }


class LogMaternalVitalsUseCase:
    def __init__(
        self,
        repo: IPregnancyRepository,
        evaluator: MaternalRiskEvaluator,
    ) -> None:
        self._repo = repo
        self._evaluator = evaluator

    async def execute(
        self, user_id: uuid.UUID, dto: LogMaternalVitalsDTO
    ) -> dict[str, Any]:
        episode = await self._repo.get_active_episode(user_id)
        if not episode:
            raise EntityNotFoundError(
                "PregnancyEpisode",
                f"No hay un episodio de embarazo activo para el usuario {user_id}",
            )

        measured_at = dto.measured_at or datetime.now(UTC)
        ga = episode.calculate_gestational_age(measured_at.date())

        # Construct and validate BloodPressure VO
        bp: BloodPressure | None = None
        if dto.systolic_mmhg is not None and dto.diastolic_mmhg is not None:
            bp = BloodPressure(
                systolic_mmhg=dto.systolic_mmhg,
                diastolic_mmhg=dto.diastolic_mmhg,
            )

        # Construct and validate Glucose VO
        glucose: CapillaryGlucoseReading | None = None
        if dto.glucose_mg_dl is not None and dto.glucose_timing is not None:
            glucose = CapillaryGlucoseReading(
                measured_at=measured_at,
                value_mg_dl=dto.glucose_mg_dl,
                timing=GlucoseTiming(dto.glucose_timing),
            )

        # Parse symptoms
        symptoms: list[MaternalSymptom] = []
        for s in dto.symptoms:
            stype = MaternalSymptomType(s["symptom_type"])
            symptoms.append(MaternalSymptom(stype, s.get("notes")))

        # Run clinical evaluator
        alerts = self._evaluator.evaluate_vitals(
            blood_pressure=bp,
            gestational_weeks=ga.weeks,
            symptoms=symptoms,
            glucose=glucose,
        )

        alerts_payload = [
            {
                "severity": a.severity.value,
                "category": a.category.value,
                "title": a.title,
                "message": a.message,
                "action_recommended": a.action_recommended,
            }
            for a in alerts
        ]

        vitals_payload = {
            "pregnancy_episode_id": episode.id,
            "user_id": user_id,
            "measured_at": measured_at,
            "gestational_weeks": ga.weeks,
            "systolic_mmhg": dto.systolic_mmhg,
            "diastolic_mmhg": dto.diastolic_mmhg,
            "glucose_mg_dl": dto.glucose_mg_dl,
            "glucose_timing": dto.glucose_timing,
            "weight_kg": dto.weight_kg,
            "symptoms": dto.symptoms,
            "alerts": alerts_payload,
        }

        saved = await self._repo.save_vitals_log(vitals_payload)
        return saved


class RecordContractionSessionUseCase:
    def __init__(
        self,
        repo: IPregnancyRepository,
        analyzer: ContractionAndKickAnalyzer,
    ) -> None:
        self._repo = repo
        self._analyzer = analyzer

    async def execute(
        self, user_id: uuid.UUID, dto: LogContractionSessionDTO
    ) -> dict[str, Any]:
        episode = await self._repo.get_active_episode(user_id)
        if not episode:
            raise EntityNotFoundError(
                "PregnancyEpisode",
                f"No hay un episodio de embarazo activo para el usuario {user_id}",
            )

        parsed_events: list[ContractionEvent] = []
        for e in dto.events:
            parsed_events.append(
                ContractionEvent(
                    started_at=datetime.fromisoformat(e["started_at"]),
                    duration_seconds=int(e["duration_seconds"]),
                    intensity=ContractionIntensity(e.get("intensity", "moderate")),
                )
            )

        session = ContractionSession(events=parsed_events)
        started_at = parsed_events[0].started_at if parsed_events else datetime.now(UTC)
        ga = episode.calculate_gestational_age(started_at.date())

        assessment = self._analyzer.analyze_contractions(
            session=session, gestational_weeks=ga.weeks
        )

        alert_payload = None
        if assessment.alert:
            alert_payload = {
                "severity": assessment.alert.severity.value,
                "category": assessment.alert.category.value,
                "title": assessment.alert.title,
                "message": assessment.alert.message,
                "action_recommended": assessment.alert.action_recommended,
            }

        session_data = {
            "pregnancy_episode_id": episode.id,
            "user_id": user_id,
            "started_at": started_at,
            "ended_at": dto.ended_at,
            "gestational_weeks": ga.weeks,
            "pattern": assessment.pattern.value,
            "total_contractions": assessment.total_contractions,
            "avg_interval_seconds": Decimal(
                str(round(assessment.average_interval_minutes * 60, 1))
            ),
            "avg_duration_seconds": Decimal(
                str(round(assessment.average_duration_seconds, 1))
            ),
            "events": dto.events,
            "alert": alert_payload,
        }

        saved = await self._repo.save_contraction_session(session_data)
        saved["assessment"] = {
            "pattern": assessment.pattern.value,
            "average_interval_minutes": assessment.average_interval_minutes,
            "average_duration_seconds": assessment.average_duration_seconds,
            "alert": alert_payload,
        }
        return saved


class RecordKickSessionUseCase:
    def __init__(
        self,
        repo: IPregnancyRepository,
        analyzer: ContractionAndKickAnalyzer,
    ) -> None:
        self._repo = repo
        self._analyzer = analyzer

    async def execute(
        self, user_id: uuid.UUID, dto: LogKickSessionDTO
    ) -> dict[str, Any]:
        episode = await self._repo.get_active_episode(user_id)
        if not episode:
            raise EntityNotFoundError(
                "PregnancyEpisode",
                f"No hay un episodio de embarazo activo para el usuario {user_id}",
            )

        started_at = dto.started_at or datetime.now(UTC)
        ga = episode.calculate_gestational_age(started_at.date())

        session = KickSession(
            started_at=started_at,
            kicks_count=dto.kicks_count,
            duration_minutes=dto.duration_minutes,
            target_reached_at_minutes=dto.target_reached_at_minutes,
        )

        assessment = self._analyzer.analyze_kicks(
            session=session, gestational_weeks=ga.weeks
        )

        alert_payload = None
        if assessment.alert:
            alert_payload = {
                "severity": assessment.alert.severity.value,
                "category": assessment.alert.category.value,
                "title": assessment.alert.title,
                "message": assessment.alert.message,
                "action_recommended": assessment.alert.action_recommended,
            }

        session_data = {
            "pregnancy_episode_id": episode.id,
            "user_id": user_id,
            "started_at": started_at,
            "duration_minutes": dto.duration_minutes,
            "gestational_weeks": ga.weeks,
            "kicks_count": dto.kicks_count,
            "target_reached": assessment.target_reached,
            "target_reached_at_minutes": dto.target_reached_at_minutes,
            "is_reassuring": assessment.is_reassuring,
            "alert": alert_payload,
        }

        saved = await self._repo.save_kick_session(session_data)
        return saved


class ManageBirthPlanUseCase:
    def __init__(self, repo: IPregnancyRepository) -> None:
        self._repo = repo

    async def get_plan(self, user_id: uuid.UUID) -> BirthPlanPreference:
        episode = await self._repo.get_active_episode(user_id)
        if not episode:
            raise EntityNotFoundError(
                "PregnancyEpisode",
                f"No hay un episodio de embarazo activo para el usuario {user_id}",
            )
        plan = await self._repo.get_birth_plan(episode.id)
        return plan or BirthPlanPreference()

    async def save_plan(
        self, user_id: uuid.UUID, dto: SaveBirthPlanDTO
    ) -> BirthPlanPreference:
        episode = await self._repo.get_active_episode(user_id)
        if not episode:
            raise EntityNotFoundError(
                "PregnancyEpisode",
                f"No hay un episodio de embarazo activo para el usuario {user_id}",
            )
        domain_plan = BirthPlanPreference(
            companion_preferences=dto.companion_preferences,
            pain_management=dto.pain_management,
            delivery_environment=dto.delivery_environment,
            immediate_postpartum=dto.immediate_postpartum,
            special_requests=dto.special_requests,
        )
        return await self._repo.save_birth_plan(episode.id, user_id, domain_plan)


class ManagePrenatalAppointmentsUseCase:
    def __init__(self, repo: IPregnancyRepository) -> None:
        self._repo = repo

    async def list_appointments(self, user_id: uuid.UUID) -> list[PrenatalAppointment]:
        episode = await self._repo.get_active_episode(user_id)
        if not episode:
            raise EntityNotFoundError(
                "PregnancyEpisode",
                f"No hay un episodio de embarazo activo para el usuario {user_id}",
            )
        return await self._repo.list_appointments(episode.id)

    async def create_appointment(
        self, user_id: uuid.UUID, dto: CreatePrenatalAppointmentDTO
    ) -> PrenatalAppointment:
        episode = await self._repo.get_active_episode(user_id)
        if not episode:
            raise EntityNotFoundError(
                "PregnancyEpisode",
                f"No hay un episodio de embarazo activo para el usuario {user_id}",
            )
        appointment = PrenatalAppointment(
            id=uuid.uuid4(),
            pregnancy_episode_id=episode.id,
            scheduled_at=dto.scheduled_at,
            doctor_or_clinic=dto.doctor_or_clinic,
            gestational_week=dto.gestational_week,
            topics_to_discuss=dto.topics_to_discuss,
            notes=dto.notes,
            is_completed=False,
        )
        return await self._repo.create_appointment(appointment, user_id)

    async def toggle_completion(
        self, appointment_id: uuid.UUID, is_completed: bool
    ) -> PrenatalAppointment:
        res = await self._repo.toggle_appointment_completion(
            appointment_id, is_completed
        )
        if not res:
            raise EntityNotFoundError(
                "PrenatalAppointment",
                f"Cita prenatal {appointment_id} no encontrada",
            )
        return res
