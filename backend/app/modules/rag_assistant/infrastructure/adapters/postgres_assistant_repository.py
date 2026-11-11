"""PostgreSQL/SQLAlchemy repository for RAG Assistant conversations."""

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.rag_assistant.domain.entities import (
    AssistantConversation,
    AssistantMessage,
)
from app.modules.rag_assistant.infrastructure.orm.models import (
    AssistantConversationORM,
    AssistantMessageORM,
)


class PostgresAssistantRepository:
    """Persists and queries AssistantConversation and AssistantMessage entities."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def create_conversation(
        self, conversation: AssistantConversation
    ) -> AssistantConversation:
        row = AssistantConversationORM(
            id=conversation.id,
            user_id=conversation.user_id,
            title=conversation.title,
            life_stage_at_creation=conversation.life_stage_at_creation,
            created_at=conversation.created_at,
            updated_at=conversation.updated_at,
        )
        self._session.add(row)
        await self._session.commit()
        await self._session.refresh(row)
        return row.to_domain()

    async def get_conversation(
        self, conversation_id: UUID, user_id: UUID
    ) -> AssistantConversation | None:
        stmt = select(AssistantConversationORM).where(
            AssistantConversationORM.id == conversation_id,
            AssistantConversationORM.user_id == user_id,
        )
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return row.to_domain() if row else None

    async def list_conversations(self, user_id: UUID) -> list[AssistantConversation]:
        stmt = (
            select(AssistantConversationORM)
            .where(AssistantConversationORM.user_id == user_id)
            .order_by(AssistantConversationORM.updated_at.desc())
        )
        rows = (await self._session.execute(stmt)).scalars().all()
        return [r.to_domain() for r in rows]

    async def append_message(self, message: AssistantMessage) -> AssistantMessage:
        serialized_citations = [
            {
                "article_id": str(c.article_id),
                "article_slug": c.article_slug,
                "article_title": c.article_title,
                "section_heading": c.section_heading,
                "scientific_source": c.scientific_source,
                "source_url": c.source_url,
            }
            for c in message.citations
        ]
        row = AssistantMessageORM(
            id=message.id,
            conversation_id=message.conversation_id,
            role=message.role,
            content_markdown=message.content_markdown,
            citations=serialized_citations,
            safety_triage_category=message.safety_triage_category,
            is_emergency_intercepted=message.is_emergency_intercepted,
            disclaimer_level=message.disclaimer_level,
            suggested_follow_ups=message.suggested_follow_ups,
            created_at=message.created_at,
        )
        self._session.add(row)

        conv_stmt = select(AssistantConversationORM).where(
            AssistantConversationORM.id == message.conversation_id
        )
        conv_row = (await self._session.execute(conv_stmt)).scalar_one_or_none()
        if conv_row is not None:
            conv_row.updated_at = datetime.now(UTC)

        await self._session.commit()
        await self._session.refresh(row)
        return row.to_domain()

    async def list_messages(
        self, conversation_id: UUID, user_id: UUID
    ) -> list[AssistantMessage]:
        conv = await self.get_conversation(conversation_id, user_id)
        if conv is None:
            return []
        stmt = (
            select(AssistantMessageORM)
            .where(AssistantMessageORM.conversation_id == conversation_id)
            .order_by(AssistantMessageORM.created_at.asc())
        )
        rows = (await self._session.execute(stmt)).scalars().all()
        return [r.to_domain() for r in rows]
