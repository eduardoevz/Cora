"""Use cases for mature health (menopause and senior vitality)."""

from uuid import UUID

from app.modules.mature_health.application.dtos.mature_health_dtos import (
    BleedingSafetyEvaluationOutput,
    DexaEvaluationOutput,
    FallRiskEvaluationOutput,
    MenopauseHubSummaryOutput,
    PelvicLogOutput,
    RecordBleedingObservationInput,
    RecordCardiometabolicInput,
    RecordDexaInput,
    RecordFallAssessmentInput,
    RecordHotFlashInput,
    RecordPelvicLogInput,
    SaveSupportContactInput,
    SeniorVitalityHubSummaryOutput,
)
from app.modules.mature_health.application.ports.mature_health_repository_port import (
    IMatureHealthRepository,
)
from app.modules.mature_health.domain.models.bone_fall_and_urogynecology import (
    ContinenceAndPelvicLog,
    DexaBoneResult,
    FallRiskAssessment,
)
from app.modules.mature_health.domain.models.trusted_support_contact import (
    TrustedSupportContact,
)
from app.modules.mature_health.domain.models.vasomotor_and_metabolic_logs import (
    CardiometabolicPanel,
    HotFlashEpisode,
    VaginalBleedingObservation,
)
from app.modules.mature_health.domain.services.menopause_transition_service import (
    MenopauseTransitionService,
)
from app.modules.mature_health.domain.services.senior_vitality_evaluator import (
    SeniorVitalityEvaluator,
)
from app.modules.mature_health.domain.value_objects import (
    MenopauseClinicalAlert,
)


class MatureHealthUseCases:
    """Orchestrates all use cases for mature health contexts."""

    def __init__(
        self,
        repository: IMatureHealthRepository,
        menopause_service: MenopauseTransitionService | None = None,
        senior_evaluator: SeniorVitalityEvaluator | None = None,
    ) -> None:
        self._repo = repository
        self._menopause_service = menopause_service or MenopauseTransitionService()
        self._senior_evaluator = senior_evaluator or SeniorVitalityEvaluator()

    async def record_hot_flash(
        self, user_id: UUID, input_dto: RecordHotFlashInput
    ) -> HotFlashEpisode:
        episode = HotFlashEpisode(
            user_id=user_id,
            occurred_at=input_dto.occurred_at,
            severity=input_dto.severity,
            flash_type=input_dto.flash_type,
            duration_minutes=input_dto.duration_minutes,
            triggers=list(input_dto.triggers),
            sleep_disruption_level=input_dto.sleep_disruption_level,
            associated_with_hrt=input_dto.associated_with_hrt,
            notes=input_dto.notes,
        )
        return await self._repo.save_hot_flash_episode(episode)

    async def list_hot_flashes(
        self, user_id: UUID, limit: int = 50
    ) -> list[HotFlashEpisode]:
        return await self._repo.list_hot_flash_episodes(user_id, limit=limit)

    async def record_cardiometabolic_panel(
        self, user_id: UUID, input_dto: RecordCardiometabolicInput
    ) -> tuple[CardiometabolicPanel, str, list[str]]:
        panel = CardiometabolicPanel(
            user_id=user_id,
            measurement_date=input_dto.measurement_date,
            systolic_bp=input_dto.systolic_bp,
            diastolic_bp=input_dto.diastolic_bp,
            total_cholesterol_mg_dl=input_dto.total_cholesterol_mg_dl,
            ldl_cholesterol_mg_dl=input_dto.ldl_cholesterol_mg_dl,
            hdl_cholesterol_mg_dl=input_dto.hdl_cholesterol_mg_dl,
            triglycerides_mg_dl=input_dto.triglycerides_mg_dl,
            fasting_glucose_mg_dl=input_dto.fasting_glucose_mg_dl,
            notes=input_dto.notes,
        )
        assessment = self._menopause_service.evaluate_cardiometabolic_panel(panel)
        saved = await self._repo.save_cardiometabolic_panel(
            panel,
            risk_level=assessment.risk_level.value,
            flagged_params=list(assessment.flagged_parameters),
        )
        return (saved, assessment.risk_level.value, list(assessment.flagged_parameters))

    async def record_bleeding_observation(
        self, user_id: UUID, input_dto: RecordBleedingObservationInput
    ) -> BleedingSafetyEvaluationOutput:
        obs = VaginalBleedingObservation(
            user_id=user_id,
            observation_date=input_dto.observation_date,
            days_of_prior_amenorrhea=input_dto.days_of_prior_amenorrhea,
            flow_intensity=input_dto.flow_intensity,
            has_cramping=input_dto.has_cramping,
            notes=input_dto.notes,
        )
        alert = self._menopause_service.evaluate_bleeding_safety(obs)
        is_triggered = alert is not None
        saved = await self._repo.save_bleeding_observation(
            obs, is_alert_triggered=is_triggered
        )
        return BleedingSafetyEvaluationOutput(
            observation_id=saved.id,
            is_alert_triggered=is_triggered,
            alert=alert,
        )

    async def record_dexa_scan(
        self, user_id: UUID, input_dto: RecordDexaInput
    ) -> DexaEvaluationOutput:
        dexa = DexaBoneResult(
            user_id=user_id,
            scan_date=input_dto.scan_date,
            anatomical_site=input_dto.anatomical_site,
            t_score=input_dto.t_score,
            z_score=input_dto.z_score,
            bmd_g_cm2=input_dto.bmd_g_cm2,
            previous_fragility_fracture=input_dto.previous_fragility_fracture,
            notes=input_dto.notes,
        )
        classification = self._senior_evaluator.classify_bone_density(dexa)
        saved = await self._repo.save_dexa_bone_result(
            dexa, category=classification.category.value
        )
        return DexaEvaluationOutput(scan_id=saved.id, classification=classification)

    async def record_fall_assessment(
        self, user_id: UUID, input_dto: RecordFallAssessmentInput
    ) -> FallRiskEvaluationOutput:
        assessment = FallRiskAssessment(
            user_id=user_id,
            assessment_date=input_dto.assessment_date,
            falls_past_year=input_dto.falls_past_year,
            has_gait_unsteadiness=input_dto.has_gait_unsteadiness,
            uses_walking_aid=input_dto.uses_walking_aid,
            timed_up_and_go_seconds=input_dto.timed_up_and_go_seconds,
            environmental_hazards_identified=list(
                input_dto.environmental_hazards_identified
            ),
            notes=input_dto.notes,
        )
        eval_result = self._senior_evaluator.evaluate_fall_risk(assessment)
        saved = await self._repo.save_fall_risk_assessment(
            assessment,
            risk_level=eval_result.risk_level.value,
            score=eval_result.score,
        )
        return FallRiskEvaluationOutput(assessment_id=saved.id, result=eval_result)

    async def record_pelvic_log(
        self, user_id: UUID, input_dto: RecordPelvicLogInput
    ) -> PelvicLogOutput:
        log = ContinenceAndPelvicLog(
            user_id=user_id,
            log_date=input_dto.log_date,
            incontinence_type=input_dto.incontinence_type,
            daily_pad_count=input_dto.daily_pad_count,
            has_pelvic_heaviness=input_dto.has_pelvic_heaviness,
            vaginal_dryness_level=input_dto.vaginal_dryness_level,
            has_dyspareunia=input_dto.has_dyspareunia,
            notes=input_dto.notes,
        )
        guidance = self._senior_evaluator.evaluate_pelvic_health(log)
        saved = await self._repo.save_pelvic_log(log)
        return PelvicLogOutput(log_id=saved.id, guidance=guidance)

    async def save_support_contact(
        self, user_id: UUID, input_dto: SaveSupportContactInput
    ) -> TrustedSupportContact:
        contact = TrustedSupportContact(
            user_id=user_id,
            contact_name=input_dto.contact_name,
            relationship=input_dto.relationship,
            phone_number=input_dto.phone_number,
            notes=input_dto.notes,
            is_primary=input_dto.is_primary,
        )
        return await self._repo.save_support_contact(contact)

    async def get_support_contact(self, user_id: UUID) -> TrustedSupportContact | None:
        return await self._repo.get_support_contact(user_id)

    async def get_menopause_summary(
        self, user_id: UUID, user_age: int = 50
    ) -> MenopauseHubSummaryOutput:
        hot_flashes = await self._repo.list_hot_flash_episodes(user_id, limit=100)
        latest_cardio = await self._repo.get_latest_cardiometabolic_panel(user_id)
        bleeding_obs = await self._repo.list_bleeding_observations(user_id, limit=10)

        # STRAW+10 calculation from latest bleeding observation or defaults
        days_amenorrhea = 0
        if bleeding_obs:
            days_amenorrhea = bleeding_obs[0].days_of_prior_amenorrhea

        straw_stage = self._menopause_service.classify_straw10_stage(
            age=user_age,
            consecutive_cycle_lengths=[],
            days_since_last_menstruation=days_amenorrhea,
        )

        cardio_assessment = None
        if latest_cardio:
            cardio_assessment = self._menopause_service.evaluate_cardiometabolic_panel(
                latest_cardio[0]
            )

        alerts: list[MenopauseClinicalAlert] = []
        if bleeding_obs:
            bleeding_alert = self._menopause_service.evaluate_bleeding_safety(
                bleeding_obs[0]
            )
            if bleeding_alert:
                alerts.append(bleeding_alert)

        return MenopauseHubSummaryOutput(
            straw10_stage=straw_stage,
            hot_flashes_count_last_30_days=len(hot_flashes),
            latest_cardiometabolic_assessment=cardio_assessment,
            active_alerts=alerts,
        )

    async def get_senior_vitality_summary(
        self, user_id: UUID
    ) -> SeniorVitalityHubSummaryOutput:
        latest_dexa = await self._repo.get_latest_dexa_bone_result(user_id)
        latest_fall = await self._repo.get_latest_fall_risk_assessment(user_id)
        pelvic_logs = await self._repo.list_pelvic_logs(user_id, limit=1)
        contact = await self._repo.get_support_contact(user_id)

        bone_classification = None
        if latest_dexa:
            bone_classification = self._senior_evaluator.classify_bone_density(
                latest_dexa[0]
            )

        fall_risk_result = None
        if latest_fall:
            fall_risk_result = self._senior_evaluator.evaluate_fall_risk(latest_fall[0])

        fracture_alert = None
        if latest_dexa and latest_fall:
            fracture_alert = self._senior_evaluator.generate_fracture_prevention_alert(
                latest_dexa[0], latest_fall[0]
            )

        pelvic_guidance = None
        if pelvic_logs:
            pelvic_guidance = self._senior_evaluator.evaluate_pelvic_health(
                pelvic_logs[0]
            )

        return SeniorVitalityHubSummaryOutput(
            latest_bone_classification=bone_classification,
            latest_fall_risk=fall_risk_result,
            fracture_alert=fracture_alert,
            latest_pelvic_guidance=pelvic_guidance,
            trusted_contact_name=contact.contact_name if contact else None,
            trusted_contact_phone=contact.phone_number if contact else None,
        )
