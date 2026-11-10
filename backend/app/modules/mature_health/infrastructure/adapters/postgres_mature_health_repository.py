"""PostgreSQL repository adapter for mature health entities."""

from uuid import UUID

from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

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
from app.modules.mature_health.domain.value_objects import (
    AnatomicalSite,
    HotFlashSeverity,
    HotFlashType,
    IncontinenceType,
)
from app.modules.mature_health.infrastructure.orm.mature_health_orm import (
    CardiometabolicPanelModel,
    ContinenceAndPelvicLogModel,
    DexaBoneResultModel,
    FallRiskAssessmentModel,
    HotFlashEpisodeModel,
    TrustedSupportContactModel,
    VaginalBleedingObservationModel,
)


class PostgresMatureHealthRepository(IMatureHealthRepository):
    """PostgreSQL adapter implementing IMatureHealthRepository."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def save_hot_flash_episode(self, episode: HotFlashEpisode) -> HotFlashEpisode:
        assert episode.user_id is not None
        model = HotFlashEpisodeModel(
            id=episode.id,
            user_id=episode.user_id,
            occurred_at=episode.occurred_at,
            severity=int(episode.severity.value),
            flash_type=episode.flash_type.value,
            duration_minutes=episode.duration_minutes,
            triggers=list(episode.triggers),
            sleep_disruption_level=episode.sleep_disruption_level,
            associated_with_hrt=episode.associated_with_hrt,
            notes=episode.notes,
        )
        self._session.add(model)
        await self._session.commit()
        return episode

    async def list_hot_flash_episodes(
        self, user_id: UUID, limit: int = 50
    ) -> list[HotFlashEpisode]:
        stmt = (
            select(HotFlashEpisodeModel)
            .where(HotFlashEpisodeModel.user_id == user_id)
            .order_by(desc(HotFlashEpisodeModel.occurred_at))
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        models = result.scalars().all()
        return [
            HotFlashEpisode(
                id=m.id,
                user_id=m.user_id,
                occurred_at=m.occurred_at,
                severity=HotFlashSeverity(m.severity),
                flash_type=HotFlashType(m.flash_type),
                duration_minutes=m.duration_minutes,
                triggers=list(m.triggers),
                sleep_disruption_level=m.sleep_disruption_level,
                associated_with_hrt=m.associated_with_hrt,
                notes=m.notes,
            )
            for m in models
        ]

    async def save_cardiometabolic_panel(
        self,
        panel: CardiometabolicPanel,
        risk_level: str,
        flagged_params: list[str],
    ) -> CardiometabolicPanel:
        assert panel.user_id is not None
        model = CardiometabolicPanelModel(
            id=panel.id,
            user_id=panel.user_id,
            measurement_date=panel.measurement_date,
            systolic_bp=panel.systolic_bp,
            diastolic_bp=panel.diastolic_bp,
            total_cholesterol_mg_dl=panel.total_cholesterol_mg_dl,
            ldl_cholesterol_mg_dl=panel.ldl_cholesterol_mg_dl,
            hdl_cholesterol_mg_dl=panel.hdl_cholesterol_mg_dl,
            triglycerides_mg_dl=panel.triglycerides_mg_dl,
            fasting_glucose_mg_dl=panel.fasting_glucose_mg_dl,
            risk_level=risk_level,
            flagged_parameters=flagged_params,
            notes=panel.notes,
        )
        self._session.add(model)
        await self._session.commit()
        return panel

    async def get_latest_cardiometabolic_panel(
        self, user_id: UUID
    ) -> tuple[CardiometabolicPanel, str, list[str]] | None:
        stmt = (
            select(CardiometabolicPanelModel)
            .where(CardiometabolicPanelModel.user_id == user_id)
            .order_by(desc(CardiometabolicPanelModel.measurement_date))
            .limit(1)
        )
        result = await self._session.execute(stmt)
        m = result.scalars().first()
        if not m:
            return None
        panel = CardiometabolicPanel(
            id=m.id,
            user_id=m.user_id,
            measurement_date=m.measurement_date,
            systolic_bp=m.systolic_bp,
            diastolic_bp=m.diastolic_bp,
            total_cholesterol_mg_dl=m.total_cholesterol_mg_dl,
            ldl_cholesterol_mg_dl=m.ldl_cholesterol_mg_dl,
            hdl_cholesterol_mg_dl=m.hdl_cholesterol_mg_dl,
            triglycerides_mg_dl=m.triglycerides_mg_dl,
            fasting_glucose_mg_dl=m.fasting_glucose_mg_dl,
            notes=m.notes,
        )
        return (panel, m.risk_level, list(m.flagged_parameters))

    async def save_bleeding_observation(
        self, obs: VaginalBleedingObservation, is_alert_triggered: bool
    ) -> VaginalBleedingObservation:
        assert obs.user_id is not None
        model = VaginalBleedingObservationModel(
            id=obs.id,
            user_id=obs.user_id,
            observation_date=obs.observation_date,
            days_of_prior_amenorrhea=obs.days_of_prior_amenorrhea,
            flow_intensity=obs.flow_intensity,
            has_cramping=obs.has_cramping,
            is_postmenopausal_alert_triggered=is_alert_triggered,
            notes=obs.notes,
        )
        self._session.add(model)
        await self._session.commit()
        return obs

    async def list_bleeding_observations(
        self, user_id: UUID, limit: int = 50
    ) -> list[VaginalBleedingObservation]:
        stmt = (
            select(VaginalBleedingObservationModel)
            .where(VaginalBleedingObservationModel.user_id == user_id)
            .order_by(desc(VaginalBleedingObservationModel.observation_date))
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        models = result.scalars().all()
        return [
            VaginalBleedingObservation(
                id=m.id,
                user_id=m.user_id,
                observation_date=m.observation_date,
                days_of_prior_amenorrhea=m.days_of_prior_amenorrhea,
                flow_intensity=m.flow_intensity,
                has_cramping=m.has_cramping,
                notes=m.notes,
            )
            for m in models
        ]

    async def save_dexa_bone_result(
        self, dexa: DexaBoneResult, category: str
    ) -> DexaBoneResult:
        assert dexa.user_id is not None
        model = DexaBoneResultModel(
            id=dexa.id,
            user_id=dexa.user_id,
            scan_date=dexa.scan_date,
            anatomical_site=dexa.anatomical_site.value,
            t_score=dexa.t_score,
            z_score=dexa.z_score,
            bmd_g_cm2=dexa.bmd_g_cm2,
            previous_fragility_fracture=dexa.previous_fragility_fracture,
            category=category,
            notes=dexa.notes,
        )
        self._session.add(model)
        await self._session.commit()
        return dexa

    async def get_latest_dexa_bone_result(
        self, user_id: UUID
    ) -> tuple[DexaBoneResult, str] | None:
        stmt = (
            select(DexaBoneResultModel)
            .where(DexaBoneResultModel.user_id == user_id)
            .order_by(desc(DexaBoneResultModel.scan_date))
            .limit(1)
        )
        result = await self._session.execute(stmt)
        m = result.scalars().first()
        if not m:
            return None
        dexa = DexaBoneResult(
            id=m.id,
            user_id=m.user_id,
            scan_date=m.scan_date,
            anatomical_site=AnatomicalSite(m.anatomical_site),
            t_score=m.t_score,
            z_score=m.z_score,
            bmd_g_cm2=m.bmd_g_cm2,
            previous_fragility_fracture=m.previous_fragility_fracture,
            notes=m.notes,
        )
        return (dexa, m.category)

    async def save_fall_risk_assessment(
        self, assessment: FallRiskAssessment, risk_level: str, score: int
    ) -> FallRiskAssessment:
        assert assessment.user_id is not None
        model = FallRiskAssessmentModel(
            id=assessment.id,
            user_id=assessment.user_id,
            assessment_date=assessment.assessment_date,
            falls_past_year=assessment.falls_past_year,
            has_gait_unsteadiness=assessment.has_gait_unsteadiness,
            uses_walking_aid=assessment.uses_walking_aid,
            timed_up_and_go_seconds=assessment.timed_up_and_go_seconds,
            risk_level=risk_level,
            composite_score=score,
            environmental_hazards=list(assessment.environmental_hazards_identified),
            notes=assessment.notes,
        )
        self._session.add(model)
        await self._session.commit()
        return assessment

    async def get_latest_fall_risk_assessment(
        self, user_id: UUID
    ) -> tuple[FallRiskAssessment, str, int] | None:
        stmt = (
            select(FallRiskAssessmentModel)
            .where(FallRiskAssessmentModel.user_id == user_id)
            .order_by(desc(FallRiskAssessmentModel.assessment_date))
            .limit(1)
        )
        result = await self._session.execute(stmt)
        m = result.scalars().first()
        if not m:
            return None
        assessment = FallRiskAssessment(
            id=m.id,
            user_id=m.user_id,
            assessment_date=m.assessment_date,
            falls_past_year=m.falls_past_year,
            has_gait_unsteadiness=m.has_gait_unsteadiness,
            uses_walking_aid=m.uses_walking_aid,
            timed_up_and_go_seconds=m.timed_up_and_go_seconds,
            environmental_hazards_identified=list(m.environmental_hazards),
            notes=m.notes,
        )
        return (assessment, m.risk_level, m.composite_score)

    async def save_pelvic_log(
        self, log: ContinenceAndPelvicLog
    ) -> ContinenceAndPelvicLog:
        assert log.user_id is not None
        model = ContinenceAndPelvicLogModel(
            id=log.id,
            user_id=log.user_id,
            log_date=log.log_date,
            incontinence_type=log.incontinence_type.value,
            daily_pad_count=log.daily_pad_count,
            has_pelvic_heaviness=log.has_pelvic_heaviness,
            vaginal_dryness_level=log.vaginal_dryness_level,
            has_dyspareunia=log.has_dyspareunia,
            notes=log.notes,
        )
        self._session.add(model)
        await self._session.commit()
        return log

    async def list_pelvic_logs(
        self, user_id: UUID, limit: int = 50
    ) -> list[ContinenceAndPelvicLog]:
        stmt = (
            select(ContinenceAndPelvicLogModel)
            .where(ContinenceAndPelvicLogModel.user_id == user_id)
            .order_by(desc(ContinenceAndPelvicLogModel.log_date))
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        models = result.scalars().all()
        return [
            ContinenceAndPelvicLog(
                id=m.id,
                user_id=m.user_id,
                log_date=m.log_date,
                incontinence_type=IncontinenceType(m.incontinence_type),
                daily_pad_count=m.daily_pad_count,
                has_pelvic_heaviness=m.has_pelvic_heaviness,
                vaginal_dryness_level=m.vaginal_dryness_level,
                has_dyspareunia=m.has_dyspareunia,
                notes=m.notes,
            )
            for m in models
        ]

    async def save_support_contact(
        self, contact: TrustedSupportContact
    ) -> TrustedSupportContact:
        assert contact.user_id is not None
        # Inactivate existing contacts if this one is primary
        if contact.is_primary:
            stmt = select(TrustedSupportContactModel).where(
                TrustedSupportContactModel.user_id == contact.user_id
            )
            res = await self._session.execute(stmt)
            for existing in res.scalars().all():
                existing.is_primary = False

        model = TrustedSupportContactModel(
            id=contact.id,
            user_id=contact.user_id,
            contact_name=contact.contact_name,
            relationship=contact.relationship,
            phone_number=contact.phone_number,
            notes=contact.notes,
            is_primary=contact.is_primary,
        )
        self._session.add(model)
        await self._session.commit()
        return contact

    async def get_support_contact(self, user_id: UUID) -> TrustedSupportContact | None:
        stmt = (
            select(TrustedSupportContactModel)
            .where(
                TrustedSupportContactModel.user_id == user_id,
                TrustedSupportContactModel.is_primary.is_(True),
            )
            .limit(1)
        )
        result = await self._session.execute(stmt)
        m = result.scalars().first()
        if not m:
            return None
        return TrustedSupportContact(
            id=m.id,
            user_id=m.user_id,
            contact_name=m.contact_name,
            relationship=m.relationship,
            phone_number=m.phone_number,
            notes=m.notes,
            is_primary=m.is_primary,
        )
