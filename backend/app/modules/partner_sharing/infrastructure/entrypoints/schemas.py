"""Pydantic v2 schemas for Partner Sharing endpoints."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.modules.partner_sharing.domain.entities import (
    PartnerInvitation,
    PartnerLink,
    PartnerProjectedView,
    SharingScopeMask,
)


class CreateInvitationResponse(BaseModel):
    invitation_code: str
    expires_at: datetime

    @classmethod
    def from_domain(
        cls, raw_code: str, inv: PartnerInvitation
    ) -> "CreateInvitationResponse":
        return cls(invitation_code=raw_code, expires_at=inv.expires_at)


class RedeemInvitationRequest(BaseModel):
    invitation_code: str = Field(
        ..., min_length=4, max_length=30, description="Código de invitación de pareja"
    )


class SharingScopeSchema(BaseModel):
    share_fertility_window: bool = False
    share_pregnancy_milestones: bool = False
    share_mood_and_support_tips: bool = False

    def to_domain(self) -> SharingScopeMask:
        return SharingScopeMask(
            share_fertility_window=self.share_fertility_window,
            share_pregnancy_milestones=self.share_pregnancy_milestones,
            share_mood_and_support_tips=self.share_mood_and_support_tips,
        )


class UpdatePermissionsRequest(BaseModel):
    permissions: SharingScopeSchema | None = None
    status: str | None = Field(
        None, description="ACTIVE o PAUSED para suspender temporalmente"
    )


class PartnerLinkResponse(BaseModel):
    id: UUID
    owner_user_id: UUID
    partner_user_id: UUID
    status: str
    permissions: SharingScopeSchema
    created_at: datetime
    updated_at: datetime

    @classmethod
    def from_domain(cls, link: PartnerLink) -> "PartnerLinkResponse":
        return cls(
            id=link.id,
            owner_user_id=link.owner_user_id,
            partner_user_id=link.partner_user_id,
            status=link.status.value,
            permissions=SharingScopeSchema(
                share_fertility_window=link.scope.share_fertility_window,
                share_pregnancy_milestones=link.scope.share_pregnancy_milestones,
                share_mood_and_support_tips=link.scope.share_mood_and_support_tips,
            ),
            created_at=link.created_at,
            updated_at=link.updated_at,
        )


class PartnerProjectedViewResponse(BaseModel):
    owner_first_name: str
    current_life_stage: str
    fertility_window_summary: str | None = None
    pregnancy_week: int | None = None
    fetal_milestone: str | None = None
    recent_mood_summary: str | None = None
    support_tips: list[str] = Field(default_factory=list)

    @classmethod
    def from_domain(cls, proj: PartnerProjectedView) -> "PartnerProjectedViewResponse":
        return cls(
            owner_first_name=proj.owner_first_name,
            current_life_stage=proj.current_life_stage,
            fertility_window_summary=proj.fertility_window_summary,
            pregnancy_week=proj.pregnancy_week,
            fetal_milestone=proj.fetal_milestone,
            recent_mood_summary=proj.recent_mood_summary,
            support_tips=proj.support_tips,
        )
