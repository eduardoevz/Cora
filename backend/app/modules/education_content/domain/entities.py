"""Pure domain entities and value objects for the Education Content module."""

from dataclasses import dataclass, field
from datetime import UTC, datetime
from uuid import UUID, uuid4

STAGE_ALIASES: dict[str, str] = {
    "menarche_puberty": "adolescence",
    "adolescence": "adolescence",
    "adulthood": "regular_adult",
    "regular_adult": "regular_adult",
    "fertility_conception": "conception_search",
    "conception_search": "conception_search",
    "pregnancy": "pregnancy",
    "postpartum_lactation": "postpartum",
    "postpartum": "postpartum",
    "perimenopause_menopause": "perimenopause",
    "perimenopause": "perimenopause",
    "mature_health": "senior_vitality",
    "senior_vitality": "senior_vitality",
}


def normalize_life_stage(raw_stage: str) -> str:
    """Normalize any stage identifier to canonical Cora LifeStage string."""
    cleaned = raw_stage.strip().lower()
    return STAGE_ALIASES.get(cleaned, cleaned)


@dataclass(frozen=True)
class ClinicalArticle:
    """Curated, peer-reviewed clinical article tailored by biological life stage."""

    slug: str
    title: str
    summary: str
    body_markdown: str
    target_life_stages: list[str]
    clinical_tags: list[str]
    scientific_source: str
    source_url: str
    reviewed_by: str
    reading_time_minutes: int
    published_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    id: UUID = field(default_factory=uuid4)


@dataclass(frozen=True)
class ClinicalEvidenceChunk:
    """Semantic fragment of a clinical article indexed in pgvector."""

    article_id: UUID
    chunk_index: int
    section_heading: str
    content_text: str
    token_count: int
    target_life_stages: list[str]
    scientific_source: str
    article_title: str = ""
    article_slug: str = ""
    source_url: str = ""
    similarity_score: float | None = None
    id: UUID = field(default_factory=uuid4)
