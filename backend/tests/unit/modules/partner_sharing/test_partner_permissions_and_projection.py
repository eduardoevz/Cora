"""Unit tests for partner invitations, scope mask permissions, and projection."""

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest

from app.modules.partner_sharing.domain.entities import (
    PartnerInvitation,
    PartnerLink,
    PartnerLinkStatus,
    SharingScopeMask,
)
from app.modules.partner_sharing.domain.services.partner_projection_builder import (
    PartnerProjectionBuilder,
    RawPartnerSourceData,
)


def test_invitation_expiration_and_hash_validation() -> None:
    """Verify invitation is valid within 24 hours and expires afterwards."""
    now = datetime.now(UTC)
    owner_id = uuid4()
    code_hash = PartnerInvitation.hash_code("CORA-8842")

    invitation = PartnerInvitation(
        id=uuid4(),
        owner_user_id=owner_id,
        invitation_code_hash=code_hash,
        expires_at=now + timedelta(hours=24),
        created_at=now,
    )
    assert invitation.is_expired(current_time=now) is False
    assert invitation.is_expired(current_time=now + timedelta(hours=25)) is True
    assert invitation.verify_code("CORA-8842") is True
    assert invitation.verify_code("WRONG-CODE") is False


def test_scope_mask_defaults_to_false_for_all_permissions() -> None:
    """Verify minimum privilege principle: all permissions default to False."""
    mask = SharingScopeMask()
    assert mask.share_fertility_window is False
    assert mask.share_pregnancy_milestones is False
    assert mask.share_mood_and_support_tips is False


def test_partner_projection_excludes_unauthorized_fields_strictly() -> None:
    """Verify projection builder only surfaces fields permitted by SharingScopeMask."""
    owner_id = uuid4()
    partner_id = uuid4()

    # User only authorizes pregnancy milestones
    link = PartnerLink(
        id=uuid4(),
        owner_user_id=owner_id,
        partner_user_id=partner_id,
        status=PartnerLinkStatus.ACTIVE,
        scope=SharingScopeMask(
            share_fertility_window=False,
            share_pregnancy_milestones=True,
            share_mood_and_support_tips=False,
        ),
    )

    source_data = RawPartnerSourceData(
        owner_first_name="Camila",
        current_life_stage="pregnancy",
        fertility_window_summary="Días fértiles estimados del 12 al 17.",
        pregnancy_week=24,
        fetal_milestone="El bebé tiene el tamaño de una papaya y escucha tu voz.",
        recent_mood_summary="Sensible y con cansancio por la tarde.",
        support_tips=["Ofrécele un masaje suave en los pies o un té relajante."],
    )

    builder = PartnerProjectionBuilder()
    projection = builder.build_projection(link=link, source=source_data)

    assert projection.owner_first_name == "Camila"
    assert projection.current_life_stage == "pregnancy"

    # Authorized
    assert projection.pregnancy_week == 24
    assert "papaya" in (projection.fetal_milestone or "")

    # Denied by mask
    assert projection.fertility_window_summary is None
    assert projection.recent_mood_summary is None
    assert projection.support_tips == []


def test_paused_or_revoked_link_denies_projection() -> None:
    """Verify projection raises or returns empty when link is not ACTIVE."""
    owner_id = uuid4()
    partner_id = uuid4()

    link_revoked = PartnerLink(
        id=uuid4(),
        owner_user_id=owner_id,
        partner_user_id=partner_id,
        status=PartnerLinkStatus.REVOKED,
        scope=SharingScopeMask(share_pregnancy_milestones=True),
    )

    source_data = RawPartnerSourceData(
        owner_first_name="Sofia",
        current_life_stage="pregnancy",
        pregnancy_week=18,
    )

    builder = PartnerProjectionBuilder()
    with pytest.raises(PermissionError, match="Link is not active"):
        builder.build_projection(link=link_revoked, source=source_data)
