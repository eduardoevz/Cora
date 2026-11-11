"""Loader for the curated clinical corpus JSON seed."""

import json
from datetime import UTC, datetime
from pathlib import Path
from uuid import UUID

from app.modules.education_content.domain.entities import (
    ClinicalArticle,
    normalize_life_stage,
)

DEFAULT_CORPUS_PATH = Path(__file__).resolve().parent / "curated_clinical_corpus.json"


def load_curated_clinical_corpus(
    corpus_path: Path = DEFAULT_CORPUS_PATH,
) -> list[ClinicalArticle]:
    """Load and parse curated clinical articles from JSON seed."""
    raw_items = json.loads(corpus_path.read_text(encoding="utf-8"))
    articles: list[ClinicalArticle] = []
    for item in raw_items:
        stages = [
            normalize_life_stage(str(stage))
            for stage in item.get("target_life_stages", [])
        ]
        articles.append(
            ClinicalArticle(
                id=UUID(str(item["id"])),
                slug=str(item["slug"]),
                title=str(item["title"]),
                summary=str(item["summary"]),
                body_markdown=str(item["body_markdown"]),
                target_life_stages=stages,
                clinical_tags=[str(t).lower() for t in item.get("clinical_tags", [])],
                scientific_source=str(item["scientific_source"]),
                source_url=str(item["source_url"]),
                reviewed_by=str(item["reviewed_by"]),
                reading_time_minutes=int(item["reading_time_minutes"]),
                published_at=datetime(2026, 1, 15, tzinfo=UTC),
            )
        )
    return articles
