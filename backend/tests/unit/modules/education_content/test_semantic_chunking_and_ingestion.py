"""Unit tests for semantic chunking, clinical corpus validation, and ingestion."""

from datetime import UTC, datetime
from uuid import uuid4

import pytest

from app.modules.education_content.application.use_cases.education_use_cases import (
    IngestClinicalCorpusUseCase,
    ListCuratedArticlesUseCase,
)
from app.modules.education_content.domain.entities import (
    ClinicalArticle,
    ClinicalEvidenceChunk,
)
from app.modules.education_content.domain.services.semantic_chunker import (
    SemanticMarkdownChunker,
)
from app.modules.education_content.infrastructure.adapters import (
    gemini_embedding_adapter,
)
from app.modules.education_content.infrastructure.seeds.corpus_loader import (
    load_curated_clinical_corpus,
)

GeminiEmbeddingAdapter = gemini_embedding_adapter.GeminiEmbeddingAdapter


def test_semantic_chunker_preserves_headings_and_target_word_limits() -> None:
    """Verify markdown chunking respects section headings, word bounds, and overlap."""
    para1 = " ".join(["fisiologia"] * 180)
    para2 = " ".join(["endometrio"] * 180)
    para3 = " ".join(["progesterona"] * 180)
    markdown_body = (
        f"## Fase Folicular y Ovulación\n\n{para1}\n\n{para2}\n\n"
        f"### Fase Lútea Tardía\n\n{para3}"
    )

    article = ClinicalArticle(
        id=uuid4(),
        slug="fisiologia-ciclo-menstrual-figo",
        title="Fisiología del Ciclo Menstrual según Criterios FIGO",
        summary="Guía clínica sobre las fases del ciclo ovárico y endometrial.",
        body_markdown=markdown_body,
        target_life_stages=["adolescence", "regular_adult"],
        clinical_tags=["ciclo", "ovulacion", "figo"],
        scientific_source=(
            "FIGO — Federación Internacional de Ginecología y Obstetricia"
        ),
        source_url="https://www.figo.org/menstrual-disorders",
        reviewed_by="Comité Clínico Cora (Ginecología y Obstetricia)",
        reading_time_minutes=6,
        published_at=datetime.now(UTC),
    )

    chunker = SemanticMarkdownChunker(target_words=320, max_words=450, overlap_words=50)
    chunks = chunker.chunk_article(article)

    assert len(chunks) >= 2
    assert chunks[0].chunk_index == 0
    assert chunks[0].section_heading == "Fase Folicular y Ovulación"
    assert chunks[0].article_title == article.title
    assert chunks[0].scientific_source == article.scientific_source
    assert chunks[0].target_life_stages == ["adolescence", "regular_adult"]
    assert 150 <= chunks[0].token_count <= 600
    assert any(c.section_heading == "Fase Lútea Tardía" for c in chunks)


def test_curated_clinical_corpus_covers_all_seven_life_stages() -> None:
    """Verify the curated clinical JSON seed covers all 7 biological life stages."""
    articles = load_curated_clinical_corpus()
    assert len(articles) >= 14

    covered_stages = {
        stage for article in articles for stage in article.target_life_stages
    }
    required_stages = {
        "adolescence",
        "regular_adult",
        "conception_search",
        "pregnancy",
        "postpartum",
        "perimenopause",
        "senior_vitality",
    }
    assert required_stages.issubset(covered_stages)
    for article in articles:
        assert article.scientific_source
        assert len(article.body_markdown.split()) >= 120


def test_gemini_embedding_adapter_calls_gemini_embedding_2_with_768_dims() -> None:
    """Verify GeminiEmbeddingAdapter invokes gemini-embedding-2 with 768 dimensions."""
    recorded_calls: list[dict[str, object]] = []

    class FakeEmbeddingObj:
        def __init__(self, values: list[float]) -> None:
            self.values = values

    class FakeEmbedResponse:
        def __init__(self, count: int) -> None:
            self.embeddings = [
                FakeEmbeddingObj([0.01 * (i + 1)] * 768) for i in range(count)
            ]

    class FakeModelsResource:
        def embed_content(
            self,
            *,
            model: str,
            contents: object,
            config: object,
        ) -> FakeEmbedResponse:
            recorded_calls.append(
                {"model": model, "contents": contents, "config": config}
            )
            count = len(contents) if isinstance(contents, list) else 1
            return FakeEmbedResponse(count)

    class FakeGenaiClient:
        def __init__(self) -> None:
            self.models = FakeModelsResource()

    adapter = GeminiEmbeddingAdapter(
        client=FakeGenaiClient(),
        model_name="gemini-embedding-2",
        dimensions=768,
    )
    vec = adapter.embed_text("Sangrado uterino anormal criterios FIGO")

    assert len(vec) == 768
    assert len(recorded_calls) == 1
    assert recorded_calls[0]["model"] == "gemini-embedding-2"
    cfg = recorded_calls[0]["config"]
    assert getattr(cfg, "output_dimensionality", None) == 768


@pytest.mark.asyncio
async def test_ingest_clinical_corpus_and_stage_filtering() -> None:
    """Verify corpus ingestion chunks, embeds, and filters articles by life stage."""

    class InMemoryEducationRepo:
        def __init__(self) -> None:
            self.articles: dict[str, ClinicalArticle] = {}
            self.chunks: list[tuple[ClinicalEvidenceChunk, list[float]]] = []

        async def upsert_article_with_chunks(
            self,
            article: ClinicalArticle,
            chunks_with_embeddings: list[tuple[ClinicalEvidenceChunk, list[float]]],
        ) -> ClinicalArticle:
            self.articles[article.slug] = article
            self.chunks.extend(chunks_with_embeddings)
            return article

        async def list_articles(
            self,
            life_stage: str | None = None,
            tag: str | None = None,
            search_query: str | None = None,
        ) -> list[ClinicalArticle]:
            items = list(self.articles.values())
            if life_stage:
                items = [a for a in items if life_stage in a.target_life_stages]
            if tag:
                items = [a for a in items if tag.lower() in a.clinical_tags]
            if search_query:
                q = search_query.lower()
                items = [
                    a for a in items if q in a.title.lower() or q in a.summary.lower()
                ]
            return items

        async def get_article_by_slug(self, slug: str) -> ClinicalArticle | None:
            return self.articles.get(slug)

    repo = InMemoryEducationRepo()
    embedding_adapter = GeminiEmbeddingAdapter(
        client=None,
        model_name="gemini-embedding-2",
        dimensions=768,
    )
    chunker = SemanticMarkdownChunker()
    ingest_uc = IngestClinicalCorpusUseCase(
        repository=repo,
        chunker=chunker,
        embedding_generator=embedding_adapter,
    )

    corpus = load_curated_clinical_corpus()
    ingested_count = await ingest_uc.execute(corpus[:3])
    assert ingested_count == 3
    assert len(repo.chunks) >= 3
    assert len(repo.chunks[0][1]) == 768

    list_uc = ListCuratedArticlesUseCase(repository=repo)
    adolescence_articles = await list_uc.execute(life_stage="adolescence")
    assert all("adolescence" in a.target_life_stages for a in adolescence_articles)
