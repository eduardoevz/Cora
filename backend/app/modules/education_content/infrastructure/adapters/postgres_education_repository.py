"""PostgreSQL + pgvector (and SQLite test-compatible) repository for Education."""

import math
from datetime import UTC, datetime

from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.education_content.application.ports.education_ports import (
    EmbeddingGeneratorPort,
)
from app.modules.education_content.application.use_cases.education_use_cases import (
    IngestClinicalCorpusUseCase,
)
from app.modules.education_content.domain.entities import (
    ClinicalArticle,
    ClinicalEvidenceChunk,
    normalize_life_stage,
)
from app.modules.education_content.domain.services.semantic_chunker import (
    SemanticMarkdownChunker,
)
from app.modules.education_content.infrastructure.orm.models import (
    ClinicalArticleORM,
    ClinicalEvidenceChunkORM,
)
from app.modules.education_content.infrastructure.seeds.corpus_loader import (
    load_curated_clinical_corpus,
)


class PostgresEducationRepository:
    """Repository and EvidenceRetrievalPort implementation using SQLAlchemy 2.0."""

    def __init__(
        self,
        session: AsyncSession,
        embedding_generator: EmbeddingGeneratorPort,
    ) -> None:
        self._session = session
        self._embedding_generator = embedding_generator

    async def ensure_seeded(self) -> None:
        """Auto-seed curated clinical corpus if clinical_articles table is empty."""
        count_stmt = select(func.count()).select_from(ClinicalArticleORM)
        total = (await self._session.execute(count_stmt)).scalar_one()
        if total == 0:
            corpus = load_curated_clinical_corpus()
            ingester = IngestClinicalCorpusUseCase(
                repository=self,
                chunker=SemanticMarkdownChunker(),
                embedding_generator=self._embedding_generator,
            )
            await ingester.execute(corpus)
            await self._session.commit()

    async def upsert_article_with_chunks(
        self,
        article: ClinicalArticle,
        chunks_with_embeddings: list[tuple[ClinicalEvidenceChunk, list[float]]],
    ) -> ClinicalArticle:
        """Insert or update a clinical article and replace its vector chunks."""
        existing_stmt = select(ClinicalArticleORM).where(
            ClinicalArticleORM.slug == article.slug
        )
        existing = (await self._session.execute(existing_stmt)).scalar_one_or_none()

        if existing is None:
            row = ClinicalArticleORM(
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
            self._session.add(row)
            await self._session.flush()
            article_id = row.id
        else:
            existing.title = article.title
            existing.summary = article.summary
            existing.body_markdown = article.body_markdown
            existing.target_life_stages = article.target_life_stages
            existing.clinical_tags = article.clinical_tags
            existing.scientific_source = article.scientific_source
            existing.source_url = article.source_url
            existing.reviewed_by = article.reviewed_by
            existing.reading_time_minutes = article.reading_time_minutes
            article_id = existing.id
            await self._session.execute(
                delete(ClinicalEvidenceChunkORM).where(
                    ClinicalEvidenceChunkORM.article_id == article_id
                )
            )

        now = datetime.now(UTC)
        for chunk, vector in chunks_with_embeddings:
            chunk_row = ClinicalEvidenceChunkORM(
                id=chunk.id,
                article_id=article_id,
                chunk_index=chunk.chunk_index,
                section_heading=chunk.section_heading,
                content_text=chunk.content_text,
                token_count=chunk.token_count,
                target_life_stages=chunk.target_life_stages,
                scientific_source=chunk.scientific_source,
                embedding=vector,
                created_at=now,
            )
            self._session.add(chunk_row)

        await self._session.flush()
        return article

    async def list_articles(
        self,
        life_stage: str | None = None,
        tag: str | None = None,
        search_query: str | None = None,
    ) -> list[ClinicalArticle]:
        """List curated clinical articles filtered by stage, tag, or query."""
        await self.ensure_seeded()

        stmt = select(ClinicalArticleORM).order_by(ClinicalArticleORM.slug.asc())
        rows = (await self._session.execute(stmt)).scalars().all()
        articles = [r.to_domain() for r in rows]

        if life_stage:
            norm_stage = normalize_life_stage(life_stage)
            articles = [a for a in articles if norm_stage in a.target_life_stages]
        if tag:
            norm_tag = tag.strip().lower()
            articles = [
                a
                for a in articles
                if any(norm_tag in t.lower() for t in a.clinical_tags)
            ]
        if search_query:
            q = search_query.strip().lower()
            articles = [
                a
                for a in articles
                if q in a.title.lower()
                or q in a.summary.lower()
                or q in a.body_markdown.lower()
            ]
        return articles

    async def get_article_by_slug(self, slug: str) -> ClinicalArticle | None:
        """Retrieve a single clinical article by slug."""
        await self.ensure_seeded()
        stmt = select(ClinicalArticleORM).where(ClinicalArticleORM.slug == slug)
        row = (await self._session.execute(stmt)).scalar_one_or_none()
        return row.to_domain() if row else None

    async def retrieve_top_k_chunks(
        self,
        query_text: str,
        life_stage: str | None = None,
        top_k: int = 5,
    ) -> list[ClinicalEvidenceChunk]:
        """Retrieve Top-K clinical evidence chunks using cosine similarity."""
        await self.ensure_seeded()
        query_vec = self._embedding_generator.embed_text(query_text)
        norm_stage = normalize_life_stage(life_stage) if life_stage else None

        bind = self._session.get_bind()
        dialect_name = bind.dialect.name if bind is not None else "sqlite"

        if dialect_name == "postgresql":
            distance_expr = ClinicalEvidenceChunkORM.embedding.cosine_distance(
                query_vec
            )
            stmt = (
                select(
                    ClinicalEvidenceChunkORM,
                    ClinicalArticleORM.title,
                    ClinicalArticleORM.slug,
                    ClinicalArticleORM.source_url,
                    distance_expr.label("distance"),
                )
                .join(
                    ClinicalArticleORM,
                    ClinicalEvidenceChunkORM.article_id == ClinicalArticleORM.id,
                )
                .order_by(distance_expr.asc())
                .limit(top_k * 3)
            )
            result_rows = (await self._session.execute(stmt)).all()
            scored: list[tuple[float, ClinicalEvidenceChunk]] = []
            for chunk_row, title, slug, url, dist in result_rows:
                sim = max(0.0, 1.0 - float(dist or 0.0))
                stage_boost = (
                    0.15
                    if norm_stage and norm_stage in (chunk_row.target_life_stages or [])
                    else 0.0
                )
                final_score = round(min(1.0, sim + stage_boost), 4)
                scored.append(
                    (
                        final_score,
                        chunk_row.to_domain(
                            article_title=title,
                            article_slug=slug,
                            source_url=url,
                            similarity_score=final_score,
                        ),
                    )
                )
            scored.sort(key=lambda item: item[0], reverse=True)
            return [item[1] for item in scored[:top_k]]

        # SQLite fallback for in-memory integration tests
        stmt_all = select(
            ClinicalEvidenceChunkORM,
            ClinicalArticleORM.title,
            ClinicalArticleORM.slug,
            ClinicalArticleORM.source_url,
        ).join(
            ClinicalArticleORM,
            ClinicalEvidenceChunkORM.article_id == ClinicalArticleORM.id,
        )
        rows = (await self._session.execute(stmt_all)).all()
        scored_sqlite: list[tuple[float, ClinicalEvidenceChunk]] = []
        for chunk_row, title, slug, url in rows:
            emb = list(chunk_row.embedding or [])
            sim = self._cosine_similarity(query_vec, emb)
            stage_boost = (
                0.15
                if norm_stage and norm_stage in (chunk_row.target_life_stages or [])
                else 0.0
            )
            final_score = round(min(1.0, max(0.0, sim) + stage_boost), 4)
            scored_sqlite.append(
                (
                    final_score,
                    chunk_row.to_domain(
                        article_title=title,
                        article_slug=slug,
                        source_url=url,
                        similarity_score=final_score,
                    ),
                )
            )
        scored_sqlite.sort(key=lambda item: item[0], reverse=True)
        return [item[1] for item in scored_sqlite[:top_k]]

    @staticmethod
    def _cosine_similarity(vec_a: list[float], vec_b: list[float]) -> float:
        if not vec_a or not vec_b or len(vec_a) != len(vec_b):
            return 0.0
        dot = sum(a * b for a, b in zip(vec_a, vec_b, strict=False))
        norm_a = math.sqrt(sum(a * a for a in vec_a)) or 1.0
        norm_b = math.sqrt(sum(b * b for b in vec_b)) or 1.0
        return dot / (norm_a * norm_b)
