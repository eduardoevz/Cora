"""SQLAlchemy 2.0 ORM models for Education Content and pgvector chunks."""

from datetime import UTC, datetime
from typing import Any
from uuid import UUID, uuid4

from pgvector.sqlalchemy import Vector
from sqlalchemy import JSON, DateTime, ForeignKey, Index, Integer, String, Text, Uuid
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.modules.education_content.domain.entities import (
    ClinicalArticle,
    ClinicalEvidenceChunk,
)

JSONVariant = JSON().with_variant(JSONB(), "postgresql")
EmbeddingVariant = JSON().with_variant(Vector(768), "postgresql")


class ClinicalArticleORM(Base):
    """ORM representation of a curated clinical article."""

    __tablename__ = "clinical_articles"

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid4
    )
    slug: Mapped[str] = mapped_column(
        String(160), unique=True, nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    body_markdown: Mapped[str] = mapped_column(Text, nullable=False)
    target_life_stages: Mapped[list[str]] = mapped_column(
        JSONVariant, nullable=False, default=list
    )
    clinical_tags: Mapped[list[str]] = mapped_column(
        JSONVariant, nullable=False, default=list
    )
    scientific_source: Mapped[str] = mapped_column(String(255), nullable=False)
    source_url: Mapped[str] = mapped_column(String(500), nullable=False)
    reviewed_by: Mapped[str] = mapped_column(String(200), nullable=False)
    reading_time_minutes: Mapped[int] = mapped_column(
        Integer, nullable=False, default=5
    )
    published_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )

    chunks: Mapped[list["ClinicalEvidenceChunkORM"]] = relationship(
        "ClinicalEvidenceChunkORM",
        back_populates="article",
        cascade="all, delete-orphan",
    )

    def to_domain(self) -> ClinicalArticle:
        """Convert ORM row into pure ClinicalArticle domain entity."""
        pub = self.published_at
        if pub.tzinfo is None:
            pub = pub.replace(tzinfo=UTC)
        return ClinicalArticle(
            id=self.id,
            slug=self.slug,
            title=self.title,
            summary=self.summary,
            body_markdown=self.body_markdown,
            target_life_stages=list(self.target_life_stages or []),
            clinical_tags=list(self.clinical_tags or []),
            scientific_source=self.scientific_source,
            source_url=self.source_url,
            reviewed_by=self.reviewed_by,
            reading_time_minutes=self.reading_time_minutes,
            published_at=pub,
        )


class ClinicalEvidenceChunkORM(Base):
    """ORM representation of a semantic clinical chunk indexed in pgvector."""

    __tablename__ = "clinical_evidence_chunks"

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid4
    )
    article_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("clinical_articles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    chunk_index: Mapped[int] = mapped_column(Integer, nullable=False)
    section_heading: Mapped[str] = mapped_column(String(255), nullable=False)
    content_text: Mapped[str] = mapped_column(Text, nullable=False)
    token_count: Mapped[int] = mapped_column(Integer, nullable=False)
    target_life_stages: Mapped[list[str]] = mapped_column(
        JSONVariant, nullable=False, default=list
    )
    scientific_source: Mapped[str] = mapped_column(String(255), nullable=False)
    embedding: Mapped[Any] = mapped_column(EmbeddingVariant, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
    )

    article: Mapped[ClinicalArticleORM] = relationship(
        "ClinicalArticleORM",
        back_populates="chunks",
    )

    __table_args__ = (
        Index(
            "ix_clinical_evidence_chunks_article_idx",
            "article_id",
            "chunk_index",
        ),
    )

    def to_domain(
        self,
        article_title: str = "",
        article_slug: str = "",
        source_url: str = "",
        similarity_score: float | None = None,
    ) -> ClinicalEvidenceChunk:
        """Convert ORM row into pure ClinicalEvidenceChunk domain entity."""
        return ClinicalEvidenceChunk(
            id=self.id,
            article_id=self.article_id,
            chunk_index=self.chunk_index,
            section_heading=self.section_heading,
            content_text=self.content_text,
            token_count=self.token_count,
            target_life_stages=list(self.target_life_stages or []),
            scientific_source=self.scientific_source,
            article_title=article_title,
            article_slug=article_slug,
            source_url=source_url,
            similarity_score=similarity_score,
        )
