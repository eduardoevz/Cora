"""Service for projecting authorized clinical context to partner."""

from dataclasses import dataclass, field

from app.modules.partner_sharing.domain.entities import (
    PartnerLink,
    PartnerLinkStatus,
    PartnerProjectedView,
)


@dataclass(frozen=True)
class RawPartnerSourceData:
    """Full cross-module clinical data assembled for partner projection."""

    owner_first_name: str
    current_life_stage: str
    fertility_window_summary: str | None = None
    pregnancy_week: int | None = None
    fetal_milestone: str | None = None
    recent_mood_summary: str | None = None
    support_tips: list[str] = field(default_factory=list)


class PartnerProjectionBuilder:
    """Filters clinical source data according to PartnerLink.scope mask."""

    def build_projection(
        self,
        link: PartnerLink,
        source: RawPartnerSourceData,
    ) -> PartnerProjectedView:
        if link.status != PartnerLinkStatus.ACTIVE:
            raise PermissionError(f"Link is not active (status={link.status.value})")

        scope = link.scope

        fertility_summary = (
            source.fertility_window_summary if scope.share_fertility_window else None
        )
        pregnancy_week = (
            source.pregnancy_week if scope.share_pregnancy_milestones else None
        )
        fetal_milestone = (
            source.fetal_milestone if scope.share_pregnancy_milestones else None
        )
        mood_summary = (
            source.recent_mood_summary if scope.share_mood_and_support_tips else None
        )
        support_tips = (
            list(source.support_tips) if scope.share_mood_and_support_tips else []
        )

        return PartnerProjectedView(
            owner_first_name=source.owner_first_name,
            current_life_stage=source.current_life_stage,
            fertility_window_summary=fertility_summary,
            pregnancy_week=pregnancy_week,
            fetal_milestone=fetal_milestone,
            recent_mood_summary=mood_summary,
            support_tips=support_tips,
        )
