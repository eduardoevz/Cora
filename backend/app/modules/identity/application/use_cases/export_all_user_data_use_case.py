"""Use case to assemble and export all user data across modules into a portable ZIP."""

import io
import json
import zipfile
from datetime import UTC, datetime

from app.modules.clinical_tracking.infrastructure.adapters import (
    postgres_cycle_repository,
    postgres_wellness_repository,
)
from app.modules.identity.domain.models.user_profile import UserProfile
from app.modules.partner_sharing.infrastructure.adapters import (
    postgres_partner_sharing_repository,
)
from app.modules.rag_assistant.infrastructure.adapters import (
    postgres_assistant_repository,
)
from app.modules.treatments.infrastructure.adapters import (
    postgres_treatment_repository,
)


class ExportAllUserDataUseCase:
    """Consolidates cross-bounded clinical and identity records into a ZIP."""

    async def execute(self, profile: UserProfile, session: object) -> bytes:
        user_id = profile.id
        now_str = datetime.now(UTC).isoformat()

        # 1. Profile JSON
        profile_data = {
            "id": str(profile.id),
            "firebase_uid": profile.firebase_uid,
            "first_name": profile.first_name,
            "last_name": profile.last_name,
            "current_life_stage": profile.current_life_stage.value,
            "birth_year": profile.onboarding_context.birth_year,
            "primary_intents": [
                i.value for i in profile.onboarding_context.primary_intents
            ],
            "hormonal_method": (
                profile.onboarding_context.hormonal_method.value
                if profile.onboarding_context.hormonal_method
                else "none"
            ),
            "diagnosed_conditions": [
                str(c) for c in profile.onboarding_context.diagnosed_conditions
            ],
            "created_at": profile.created_at.isoformat(),
            "updated_at": profile.updated_at.isoformat(),
        }

        # 2. Cycles & Wellness
        cycle_repo = postgres_cycle_repository.PostgresCycleRepository(
            session  # type: ignore[arg-type]
        )
        cycles = await cycle_repo.list_cycles(str(user_id), limit=100)
        cycles_data = [
            {
                "id": str(c.id),
                "start_date": c.start_date.isoformat(),
                "end_date": c.end_date.isoformat() if c.end_date else None,
                "cycle_length_days": c.cycle_length_days,
            }
            for c in cycles
        ]

        wellness_repo = postgres_wellness_repository.PostgresWellnessRepository(
            session  # type: ignore[arg-type]
        )
        wellness_logs = await wellness_repo.get_history(
            user_id=str(user_id),
            start_date=datetime(2020, 1, 1, tzinfo=UTC).date(),
            end_date=datetime.now(UTC).date(),
        )
        wellness_data = [
            {
                "id": str(w.id),
                "log_date": w.log_date.isoformat(),
                "mood_tags": [m.value for m in w.mood_tags],
                "notes": w.notes,
            }
            for w in wellness_logs
        ]

        # 3. Treatments
        treatment_repo = postgres_treatment_repository.PostgresTreatmentRepository(
            session  # type: ignore[arg-type]
        )
        regimens = await treatment_repo.get_regimens(str(user_id))
        treatments_data = [
            {
                "id": str(r.id),
                "name": r.name,
                "dosage": r.dosage,
                "is_active": r.is_active,
            }
            for r in regimens
        ]

        # 4. Assistant Conversations
        assistant_repo = postgres_assistant_repository.PostgresAssistantRepository(
            session  # type: ignore[arg-type]
        )
        conversations = await assistant_repo.list_conversations(user_id)
        conversations_data = []
        for conv in conversations:
            msgs = await assistant_repo.list_messages(conv.id, user_id)
            conversations_data.append(
                {
                    "id": str(conv.id),
                    "title": conv.title,
                    "life_stage": conv.life_stage_at_creation,
                    "created_at": conv.created_at.isoformat(),
                    "messages": [
                        {
                            "id": str(m.id),
                            "role": m.role,
                            "content": m.content_markdown,
                            "created_at": m.created_at.isoformat(),
                        }
                        for m in msgs
                    ],
                }
            )

        # 5. Partner Sharing Links
        partner_repo = (
            postgres_partner_sharing_repository.PostgresPartnerSharingRepository(
                session  # type: ignore[arg-type]
            )
        )
        links = await partner_repo.list_links_as_owner(user_id)
        partner_data = [
            {
                "id": str(lnk.id),
                "partner_user_id": str(lnk.partner_user_id),
                "status": lnk.status.value,
                "permissions": lnk.scope.to_dict(),
                "created_at": lnk.created_at.isoformat(),
            }
            for lnk in links
        ]

        # 6. Manifest
        manifest = {
            "app": "Cora Health Platform",
            "export_version": "1.0",
            "generated_at": now_str,
            "user_id": str(user_id),
            "files_included": [
                "profile.json",
                "cycles.json",
                "wellness_logs.json",
                "treatments.json",
                "assistant_conversations.json",
                "partner_sharing.json",
            ],
            "legal_notice": (
                "Este archivo contiene la totalidad de tus datos personales y de salud "
                "registrados en Cora, exportados conforme a los derechos GDPR / ARCO."
            ),
        }

        # Build in-memory ZIP
        zip_buffer = io.BytesIO()
        with zipfile.ZipFile(
            zip_buffer, "w", zipfile.ZIP_DEFLATED, compresslevel=6
        ) as zf:
            zf.writestr(
                "manifest.json", json.dumps(manifest, indent=2, ensure_ascii=False)
            )
            zf.writestr(
                "profile.json",
                json.dumps(profile_data, indent=2, ensure_ascii=False),
            )
            zf.writestr(
                "cycles.json",
                json.dumps(cycles_data, indent=2, ensure_ascii=False),
            )
            zf.writestr(
                "wellness_logs.json",
                json.dumps(wellness_data, indent=2, ensure_ascii=False),
            )
            zf.writestr(
                "treatments.json",
                json.dumps(treatments_data, indent=2, ensure_ascii=False),
            )
            zf.writestr(
                "assistant_conversations.json",
                json.dumps(conversations_data, indent=2, ensure_ascii=False),
            )
            zf.writestr(
                "partner_sharing.json",
                json.dumps(partner_data, indent=2, ensure_ascii=False),
            )

        return zip_buffer.getvalue()
