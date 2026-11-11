"""Application use cases for the Education Content module."""

from app.modules.education_content.application.ports.education_ports import (
    EducationRepositoryPort,
    EmbeddingGeneratorPort,
)
from app.modules.education_content.domain.entities import (
    ClinicalArticle,
    ClinicalEvidenceChunk,
    normalize_life_stage,
)
from app.modules.education_content.domain.services.semantic_chunker import (
    SemanticMarkdownChunker,
)


class ListCuratedArticlesUseCase:
    """List clinical articles filtered by life stage, tag, or search text."""

    def __init__(self, repository: EducationRepositoryPort) -> None:
        self._repository = repository

    async def execute(
        self,
        life_stage: str | None = None,
        tag: str | None = None,
        search_query: str | None = None,
    ) -> list[ClinicalArticle]:
        normalized_stage = normalize_life_stage(life_stage) if life_stage else None
        return await self._repository.list_articles(
            life_stage=normalized_stage,
            tag=tag,
            search_query=search_query,
        )


class GetArticleDetailUseCase:
    """Retrieve a single curated clinical article by slug."""

    def __init__(self, repository: EducationRepositoryPort) -> None:
        self._repository = repository

    async def execute(self, slug: str) -> ClinicalArticle | None:
        return await self._repository.get_article_by_slug(slug)


class IngestClinicalCorpusUseCase:
    """Chunk, embed with gemini-embedding-2, and persist curated clinical articles."""

    def __init__(
        self,
        repository: EducationRepositoryPort,
        chunker: SemanticMarkdownChunker,
        embedding_generator: EmbeddingGeneratorPort,
    ) -> None:
        self._repository = repository
        self._chunker = chunker
        self._embedding_generator = embedding_generator

    async def execute(self, articles: list[ClinicalArticle]) -> int:
        ingested = 0
        for article in articles:
            chunks = self._chunker.chunk_article(article)
            texts_to_embed = [
                f"{c.article_title} — {c.section_heading}\n{c.content_text}"
                for c in chunks
            ]
            embeddings = self._embedding_generator.embed_batch(texts_to_embed)
            paired: list[tuple[ClinicalEvidenceChunk, list[float]]] = list(
                zip(chunks, embeddings, strict=True)
            )
            await self._repository.upsert_article_with_chunks(article, paired)
            ingested += 1
        return ingested
