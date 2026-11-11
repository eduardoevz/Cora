"""Application ports for the Education Content bounded context."""

from typing import Protocol

from app.modules.education_content.domain.entities import (
    ClinicalArticle,
    ClinicalEvidenceChunk,
)


class EmbeddingGeneratorPort(Protocol):
    """Port for generating vector embeddings (768 dimensions)."""

    def embed_text(self, text: str) -> list[float]:
        """Generate a 768-dim vector for a single string."""
        ...

    def embed_batch(self, texts: list[str]) -> list[list[float]]:
        """Generate 768-dim vectors for a batch of strings."""
        ...


class EducationRepositoryPort(Protocol):
    """Port for persisting and querying clinical articles and vector chunks."""

    async def upsert_article_with_chunks(
        self,
        article: ClinicalArticle,
        chunks_with_embeddings: list[tuple[ClinicalEvidenceChunk, list[float]]],
    ) -> ClinicalArticle:
        """Persist or update a clinical article along with its embedded chunks."""
        ...

    async def list_articles(
        self,
        life_stage: str | None = None,
        tag: str | None = None,
        search_query: str | None = None,
    ) -> list[ClinicalArticle]:
        """List curated clinical articles with optional filtering."""
        ...

    async def get_article_by_slug(self, slug: str) -> ClinicalArticle | None:
        """Retrieve a single clinical article by its slug."""
        ...


class EvidenceRetrievalPort(Protocol):
    """Public cross-module port consumed by rag_assistant for Top-K retrieval."""

    async def retrieve_top_k_chunks(
        self,
        query_text: str,
        life_stage: str | None = None,
        top_k: int = 5,
    ) -> list[ClinicalEvidenceChunk]:
        """Retrieve top-K semantic chunks prioritized for the active life stage."""
        ...
