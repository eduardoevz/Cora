import uuid
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.maternal_care.application.ports.pregnancy_repository_port import (
    IPregnancyRepository,
)
from app.modules.maternal_care.domain.models.pregnancy_episode import (
    BirthPlanPreference,
    PregnancyEpisode,
    PrenatalAppointment,
)
from app.modules.maternal_care.infrastructure.orm.pregnancy_orm import (
    BirthPlanModel,
    ContractionSessionModel,
    KickSessionModel,
    MaternalVitalsLogModel,
    PregnancyEpisodeModel,
    PrenatalAppointmentModel,
)


class PostgresPregnancyRepository(IPregnancyRepository):
    """PostgreSQL adapter implementing IPregnancyRepository."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_active_episode(self, user_id: uuid.UUID) -> PregnancyEpisode | None:
        stmt = (
            select(PregnancyEpisodeModel)
            .where(
                PregnancyEpisodeModel.user_id == user_id,
                PregnancyEpisodeModel.is_active.is_(True),
            )
            .order_by(desc(PregnancyEpisodeModel.started_at))
            .limit(1)
        )
        res = await self._session.execute(stmt)
        model = res.scalar_one_or_none()
        return model.to_domain() if model else None

    async def create_episode(self, episode: PregnancyEpisode) -> PregnancyEpisode:
        # If there is already an active episode, deactivate it
        existing_active = await self.get_active_episode(episode.user_id)
        if existing_active:
            stmt = select(PregnancyEpisodeModel).where(
                PregnancyEpisodeModel.id == existing_active.id
            )
            res = await self._session.execute(stmt)
            active_model = res.scalar_one_or_none()
            if active_model:
                active_model.is_active = False
                active_model.ended_at = datetime.now(UTC)

        model = PregnancyEpisodeModel.from_domain(episode)
        self._session.add(model)
        await self._session.commit()
        return model.to_domain()

    async def update_episode(self, episode: PregnancyEpisode) -> PregnancyEpisode:
        stmt = select(PregnancyEpisodeModel).where(
            PregnancyEpisodeModel.id == episode.id
        )
        res = await self._session.execute(stmt)
        model = res.scalar_one_or_none()
        if model:
            model.clinical_edd = episode.clinical_edd
            model.ultrasound_edd = episode.ultrasound_edd
            model.is_active = episode.is_active
            model.ended_at = episode.ended_at
            model.recalibration_history = episode.recalibration_history
            model.updated_at = datetime.now(UTC)
            await self._session.commit()
            return model.to_domain()
        return episode

    async def save_vitals_log(self, vitals_data: dict[str, Any]) -> dict[str, Any]:
        log_id = vitals_data.get("id") or uuid.uuid4()
        model = MaternalVitalsLogModel(
            id=log_id,
            pregnancy_episode_id=vitals_data["pregnancy_episode_id"],
            user_id=vitals_data["user_id"],
            measured_at=vitals_data["measured_at"],
            gestational_weeks=vitals_data["gestational_weeks"],
            systolic_mmhg=vitals_data.get("systolic_mmhg"),
            diastolic_mmhg=vitals_data.get("diastolic_mmhg"),
            glucose_mg_dl=vitals_data.get("glucose_mg_dl"),
            glucose_timing=vitals_data.get("glucose_timing"),
            weight_kg=vitals_data.get("weight_kg"),
            symptoms=vitals_data.get("symptoms", []),
            alerts=vitals_data.get("alerts", []),
        )
        self._session.add(model)
        await self._session.commit()
        return {
            "id": model.id,
            "pregnancy_episode_id": model.pregnancy_episode_id,
            "user_id": model.user_id,
            "measured_at": model.measured_at,
            "gestational_weeks": model.gestational_weeks,
            "systolic_mmhg": model.systolic_mmhg,
            "diastolic_mmhg": model.diastolic_mmhg,
            "glucose_mg_dl": model.glucose_mg_dl,
            "glucose_timing": model.glucose_timing,
            "weight_kg": model.weight_kg,
            "symptoms": model.symptoms,
            "alerts": model.alerts,
            "created_at": model.created_at,
        }

    async def get_vitals_history(
        self, pregnancy_episode_id: uuid.UUID, limit: int = 50
    ) -> list[dict[str, Any]]:
        stmt = (
            select(MaternalVitalsLogModel)
            .where(MaternalVitalsLogModel.pregnancy_episode_id == pregnancy_episode_id)
            .order_by(desc(MaternalVitalsLogModel.measured_at))
            .limit(limit)
        )
        res = await self._session.execute(stmt)
        models = res.scalars().all()
        return [
            {
                "id": m.id,
                "pregnancy_episode_id": m.pregnancy_episode_id,
                "user_id": m.user_id,
                "measured_at": m.measured_at,
                "gestational_weeks": m.gestational_weeks,
                "systolic_mmhg": m.systolic_mmhg,
                "diastolic_mmhg": m.diastolic_mmhg,
                "glucose_mg_dl": m.glucose_mg_dl,
                "glucose_timing": m.glucose_timing,
                "weight_kg": m.weight_kg,
                "symptoms": m.symptoms,
                "alerts": m.alerts,
                "created_at": m.created_at,
            }
            for m in models
        ]

    async def save_contraction_session(
        self, session_data: dict[str, Any]
    ) -> dict[str, Any]:
        session_id = session_data.get("id") or uuid.uuid4()
        model = ContractionSessionModel(
            id=session_id,
            pregnancy_episode_id=session_data["pregnancy_episode_id"],
            user_id=session_data["user_id"],
            started_at=session_data["started_at"],
            ended_at=session_data.get("ended_at"),
            gestational_weeks=session_data["gestational_weeks"],
            pattern=session_data["pattern"],
            total_contractions=session_data["total_contractions"],
            avg_interval_seconds=session_data.get("avg_interval_seconds"),
            avg_duration_seconds=session_data.get("avg_duration_seconds"),
            events=session_data.get("events", []),
            alert=session_data.get("alert"),
        )
        self._session.add(model)
        await self._session.commit()
        return {
            "id": model.id,
            "pregnancy_episode_id": model.pregnancy_episode_id,
            "started_at": model.started_at,
            "ended_at": model.ended_at,
            "gestational_weeks": model.gestational_weeks,
            "pattern": model.pattern,
            "total_contractions": model.total_contractions,
            "avg_interval_seconds": model.avg_interval_seconds,
            "avg_duration_seconds": model.avg_duration_seconds,
            "events": model.events,
            "alert": model.alert,
            "created_at": model.created_at,
        }

    async def get_latest_contraction_sessions(
        self, pregnancy_episode_id: uuid.UUID, limit: int = 10
    ) -> list[dict[str, Any]]:
        stmt = (
            select(ContractionSessionModel)
            .where(ContractionSessionModel.pregnancy_episode_id == pregnancy_episode_id)
            .order_by(desc(ContractionSessionModel.started_at))
            .limit(limit)
        )
        res = await self._session.execute(stmt)
        models = res.scalars().all()
        return [
            {
                "id": m.id,
                "pregnancy_episode_id": m.pregnancy_episode_id,
                "started_at": m.started_at,
                "ended_at": m.ended_at,
                "gestational_weeks": m.gestational_weeks,
                "pattern": m.pattern,
                "total_contractions": m.total_contractions,
                "avg_interval_seconds": m.avg_interval_seconds,
                "avg_duration_seconds": m.avg_duration_seconds,
                "events": m.events,
                "alert": m.alert,
                "created_at": m.created_at,
            }
            for m in models
        ]

    async def save_kick_session(self, session_data: dict[str, Any]) -> dict[str, Any]:
        session_id = session_data.get("id") or uuid.uuid4()
        model = KickSessionModel(
            id=session_id,
            pregnancy_episode_id=session_data["pregnancy_episode_id"],
            user_id=session_data["user_id"],
            started_at=session_data["started_at"],
            duration_minutes=session_data["duration_minutes"],
            gestational_weeks=session_data["gestational_weeks"],
            kicks_count=session_data["kicks_count"],
            target_reached=session_data["target_reached"],
            target_reached_at_minutes=session_data.get("target_reached_at_minutes"),
            is_reassuring=session_data["is_reassuring"],
            alert=session_data.get("alert"),
        )
        self._session.add(model)
        await self._session.commit()
        return {
            "id": model.id,
            "pregnancy_episode_id": model.pregnancy_episode_id,
            "started_at": model.started_at,
            "duration_minutes": model.duration_minutes,
            "gestational_weeks": model.gestational_weeks,
            "kicks_count": model.kicks_count,
            "target_reached": model.target_reached,
            "target_reached_at_minutes": model.target_reached_at_minutes,
            "is_reassuring": model.is_reassuring,
            "alert": model.alert,
            "created_at": model.created_at,
        }

    async def get_latest_kick_sessions(
        self, pregnancy_episode_id: uuid.UUID, limit: int = 10
    ) -> list[dict[str, Any]]:
        stmt = (
            select(KickSessionModel)
            .where(KickSessionModel.pregnancy_episode_id == pregnancy_episode_id)
            .order_by(desc(KickSessionModel.started_at))
            .limit(limit)
        )
        res = await self._session.execute(stmt)
        models = res.scalars().all()
        return [
            {
                "id": m.id,
                "pregnancy_episode_id": m.pregnancy_episode_id,
                "started_at": m.started_at,
                "duration_minutes": m.duration_minutes,
                "gestational_weeks": m.gestational_weeks,
                "kicks_count": m.kicks_count,
                "target_reached": m.target_reached,
                "target_reached_at_minutes": m.target_reached_at_minutes,
                "is_reassuring": m.is_reassuring,
                "alert": m.alert,
                "created_at": m.created_at,
            }
            for m in models
        ]

    async def get_birth_plan(
        self, pregnancy_episode_id: uuid.UUID
    ) -> BirthPlanPreference | None:
        stmt = select(BirthPlanModel).where(
            BirthPlanModel.pregnancy_episode_id == pregnancy_episode_id
        )
        res = await self._session.execute(stmt)
        model = res.scalar_one_or_none()
        return model.to_domain() if model else None

    async def save_birth_plan(
        self,
        pregnancy_episode_id: uuid.UUID,
        user_id: uuid.UUID,
        birth_plan: BirthPlanPreference,
    ) -> BirthPlanPreference:
        stmt = select(BirthPlanModel).where(
            BirthPlanModel.pregnancy_episode_id == pregnancy_episode_id
        )
        res = await self._session.execute(stmt)
        existing = res.scalar_one_or_none()

        if existing is None:
            model = BirthPlanModel(
                pregnancy_episode_id=pregnancy_episode_id,
                user_id=user_id,
                companion_preferences=birth_plan.companion_preferences,
                pain_management=birth_plan.pain_management,
                delivery_environment=birth_plan.delivery_environment,
                immediate_postpartum=birth_plan.immediate_postpartum,
                special_requests=birth_plan.special_requests,
            )
            self._session.add(model)
        else:
            existing.companion_preferences = birth_plan.companion_preferences
            existing.pain_management = birth_plan.pain_management
            existing.delivery_environment = birth_plan.delivery_environment
            existing.immediate_postpartum = birth_plan.immediate_postpartum
            existing.special_requests = birth_plan.special_requests
            existing.updated_at = datetime.now(UTC)
            model = existing

        await self._session.commit()
        return model.to_domain()

    async def list_appointments(
        self, pregnancy_episode_id: uuid.UUID
    ) -> list[PrenatalAppointment]:
        stmt = (
            select(PrenatalAppointmentModel)
            .where(
                PrenatalAppointmentModel.pregnancy_episode_id == pregnancy_episode_id
            )
            .order_by(PrenatalAppointmentModel.scheduled_at)
        )
        res = await self._session.execute(stmt)
        models = res.scalars().all()
        return [m.to_domain() for m in models]

    async def create_appointment(
        self, appointment: PrenatalAppointment, user_id: uuid.UUID
    ) -> PrenatalAppointment:
        model = PrenatalAppointmentModel(
            id=appointment.id,
            pregnancy_episode_id=appointment.pregnancy_episode_id,
            user_id=user_id,
            scheduled_at=appointment.scheduled_at,
            doctor_or_clinic=appointment.doctor_or_clinic,
            gestational_week=appointment.gestational_week,
            topics_to_discuss=appointment.topics_to_discuss,
            notes=appointment.notes,
            is_completed=appointment.is_completed,
        )
        self._session.add(model)
        await self._session.commit()
        return model.to_domain()

    async def toggle_appointment_completion(
        self, appointment_id: uuid.UUID, is_completed: bool
    ) -> PrenatalAppointment | None:
        stmt = select(PrenatalAppointmentModel).where(
            PrenatalAppointmentModel.id == appointment_id
        )
        res = await self._session.execute(stmt)
        model = res.scalar_one_or_none()
        if model:
            model.is_completed = is_completed
            model.updated_at = datetime.now(UTC)
            await self._session.commit()
            return model.to_domain()
        return None
