"""Pydantic v2 request and response schemas for Education Content."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.modules.education_content.domain.entities import ClinicalArticle


class ClinicalArticleSummaryResponse(BaseModel):
    """Summary representation of a curated clinical article."""

    id: UUID
    slug: str
    title: str
    summary: str
    target_life_stages: list[str]
    clinical_tags: list[str]
    scientific_source: str
    source_url: str
    reviewed_by: str
    reading_time_minutes: int
    published_at: datetime

    @classmethod
    def from_domain(cls, article: ClinicalArticle) -> "ClinicalArticleSummaryResponse":
        return cls(
            id=article.id,
            slug=article.slug,
            title=article.title,
            summary=article.summary,
            target_life_stages=article.target_life_stages,
            clinical_tags=article.clinical_tags,
            scientific_source=article.scientific_source,
            source_url=article.source_url,
            reviewed_by=article.reviewed_by,
            reading_time_minutes=article.reading_time_minutes,
            published_at=article.published_at,
        )


class ClinicalArticleDetailResponse(ClinicalArticleSummaryResponse):
    """Full representation of a curated clinical article including Markdown body."""

    body_markdown: str = Field(..., description="Full peer-reviewed Markdown body")

    @classmethod
    def from_domain(cls, article: ClinicalArticle) -> "ClinicalArticleDetailResponse":
        return cls(
            id=article.id,
            slug=article.slug,
            title=article.title,
            summary=article.summary,
            body_markdown=article.body_markdown,
            target_life_stages=article.target_life_stages,
            clinical_tags=article.clinical_tags,
            scientific_source=article.scientific_source,
            source_url=article.source_url,
            reviewed_by=article.reviewed_by,
            reading_time_minutes=article.reading_time_minutes,
            published_at=article.published_at,
        )


class ClinicalArticleListResponse(BaseModel):
    """Envelope for curated clinical articles."""

    items: list[ClinicalArticleSummaryResponse]
    total: int
