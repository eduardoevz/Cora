"""FastAPI router for the Curated Clinical Library (/api/v1/education)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.database import get_async_session
from app.core.errors import EntityNotFoundError
from app.core.security import CurrentUserDep
from app.modules.education_content.application.use_cases.education_use_cases import (
    GetArticleDetailUseCase,
    ListCuratedArticlesUseCase,
)
from app.modules.education_content.infrastructure.adapters import (
    gemini_embedding_adapter,
    postgres_education_repository,
)
from app.modules.education_content.infrastructure.entrypoints.schemas import (
    ClinicalArticleDetailResponse,
    ClinicalArticleListResponse,
    ClinicalArticleSummaryResponse,
)

router = APIRouter(prefix="/education", tags=["Education & Clinical Library"])


def get_education_repository(
    session: Annotated[AsyncSession, Depends(get_async_session)],
) -> postgres_education_repository.PostgresEducationRepository:
    """Build PostgresEducationRepository with GeminiEmbeddingAdapter."""
    settings = get_settings()
    embedder = gemini_embedding_adapter.GeminiEmbeddingAdapter(
        api_key=settings.gemini_api_key,
        model_name=settings.gemini_embedding_model,
        dimensions=settings.gemini_embedding_dimensions,
    )
    return postgres_education_repository.PostgresEducationRepository(
        session=session,
        embedding_generator=embedder,
    )


@router.get(
    "/articles",
    response_model=ClinicalArticleListResponse,
    summary="Listar artículos clínicos curados por etapa de vida, etiqueta o búsqueda",
)
async def list_curated_articles(
    _current_user: CurrentUserDep,
    repo: Annotated[
        postgres_education_repository.PostgresEducationRepository,
        Depends(get_education_repository),
    ],
    life_stage: Annotated[
        str | None,
        Query(description="Filtro opcional por etapa biológica de vida"),
    ] = None,
    tag: Annotated[
        str | None,
        Query(description="Filtro opcional por etiqueta clínica (ej. sop, figo)"),
    ] = None,
    q: Annotated[
        str | None,
        Query(description="Búsqueda textual en título, resumen o contenido"),
    ] = None,
) -> ClinicalArticleListResponse:
    """Return curated clinical articles backed by WHO, ACOG, FIGO, and NAMS."""
    use_case = ListCuratedArticlesUseCase(repository=repo)
    articles = await use_case.execute(
        life_stage=life_stage,
        tag=tag,
        search_query=q,
    )
    summaries = [
        ClinicalArticleSummaryResponse.from_domain(article) for article in articles
    ]
    return ClinicalArticleListResponse(items=summaries, total=len(summaries))


@router.get(
    "/articles/{slug}",
    response_model=ClinicalArticleDetailResponse,
    summary="Obtener detalle completo de un artículo clínico por su slug",
)
async def get_curated_article_detail(
    slug: str,
    _current_user: CurrentUserDep,
    repo: Annotated[
        postgres_education_repository.PostgresEducationRepository,
        Depends(get_education_repository),
    ],
) -> ClinicalArticleDetailResponse:
    """Return full clinical article Markdown and scientific source metadata."""
    use_case = GetArticleDetailUseCase(repository=repo)
    article = await use_case.execute(slug=slug)
    if article is None:
        raise EntityNotFoundError(entity="ClinicalArticle", identifier=slug)
    return ClinicalArticleDetailResponse.from_domain(article)
