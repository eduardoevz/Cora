"""Integration tests for the automated clinical evidence ingestion script."""

from pathlib import Path

import pytest
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.core.database import Base
from app.modules.education_content.infrastructure.orm.models import (
    ClinicalArticleORM,
    ClinicalEvidenceChunkORM,
)
from scripts.ingest_clinical_library import (
    get_canonical_clinical_corpus,
    run_ingestion,
)


def test_canonical_clinical_corpus_structure() -> None:
    """Verify that all 6 canonical articles are present and valid."""
    articles = get_canonical_clinical_corpus()
    assert len(articles) == 6

    expected_slugs = {
        "guia-figo-sangrado-y-ciclo-menstrual",
        "criterios-acog-hipertension-gestacional-preeclampsia",
        "transicion-menopausica-criterios-straw10",
        "escala-edimburgo-epds-salud-mental-perinatal",
        "calendario-vacunacion-preventiva-salud-femenina",
        "biomarcadores-fertilidad-metodo-sintotermico",
    }

    actual_slugs = {a.slug for a in articles}
    assert actual_slugs == expected_slugs

    for article in articles:
        assert article.title.strip() != ""
        assert article.summary.strip() != ""
        assert article.body_markdown.strip() != ""
        assert len(article.target_life_stages) > 0
        assert article.scientific_source.strip() != ""
        assert article.source_url.startswith("https://")
        assert article.reading_time_minutes > 0


@pytest.mark.asyncio
async def test_dry_run_ingestion_processes_chunks() -> None:
    """Ensure dry-run parses all articles into chunks without writing to DB."""
    chunk_count = await run_ingestion(dry_run=True)
    assert chunk_count >= 12  # At least ~2 chunks per article


@pytest.mark.asyncio
async def test_live_ingestion_in_test_database(tmp_path: Path) -> None:
    """Ensure ingestion runs end-to-end with mock embeddings in SQLite."""
    test_db_file = tmp_path / "test_ingestion.sqlite"
    test_db_url = f"sqlite+aiosqlite:///{test_db_file}"
    test_engine = create_async_engine(test_db_url, echo=False)

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Ingest using mock embeddings into SQLite
    ingested = await run_ingestion(
        dry_run=False,
        skip_embed=True,
        db_url=test_db_url,
    )
    assert ingested == 6

    # Verify rows persisted in DB
    session_factory = async_sessionmaker(
        test_engine, class_=AsyncSession, expire_on_commit=False
    )
    async with session_factory() as session:
        art_count = await session.scalar(
            select(func.count()).select_from(ClinicalArticleORM)
        )
        chunk_count = await session.scalar(
            select(func.count()).select_from(ClinicalEvidenceChunkORM)
        )
        assert art_count == 6
        assert chunk_count is not None and chunk_count >= 12

    await test_engine.dispose()
