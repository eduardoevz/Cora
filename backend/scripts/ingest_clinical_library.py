# ruff: noqa: E501
"""Automated ingestion script for Cora's curated clinical evidence library into pgvector."""

from __future__ import annotations

import argparse
import asyncio
import sys
from datetime import UTC, datetime
from uuid import uuid4

from app.core.config import get_settings
from app.modules.education_content.application.use_cases.education_use_cases import (
    IngestClinicalCorpusUseCase,
)
from app.modules.education_content.domain.entities import ClinicalArticle
from app.modules.education_content.domain.services.semantic_chunker import (
    SemanticMarkdownChunker,
)
from app.modules.education_content.infrastructure.adapters.gemini_embedding_adapter import (
    GeminiEmbeddingAdapter,
)
from app.modules.education_content.infrastructure.adapters.postgres_education_repository import (
    PostgresEducationRepository,
)


def get_canonical_clinical_corpus() -> list[ClinicalArticle]:
    """Return the curated evidence-based clinical articles covering Cora's 7 life stages."""
    now = datetime.now(UTC)

    return [
        ClinicalArticle(
            id=uuid4(),
            slug="guia-figo-sangrado-y-ciclo-menstrual",
            title="Criterios FIGO para el Sangrado Uterino y la Regularidad del Ciclo Menstrual",
            summary=(
                "Parámetros clínicos internacionales de la FIGO para clasificar la duración, "
                "frecuencia y regularidad del ciclo menstrual femenino, identificando patrones típicos "
                "y banderas rojas que requieren evaluación ginecológica."
            ),
            body_markdown="""# Criterios FIGO de Regularidad Menstrual

La Federación Internacional de Ginecología y Obstetricia (FIGO) establece los límites fisiológicos del ciclo menstrual en mujeres adultas en edad reproductiva:

## Parámetros Normales del Ciclo
- **Frecuencia del ciclo:** Entre 24 y 38 días calendario consecutivos.
- **Duración del sangrado:** Menor o igual a 8 días de sangrado continuo o intermitente.
- **Variación normal entre ciclos:** Menor a 7 a 9 días de diferencia entre el ciclo más corto y el más largo en un período de 12 meses.

## Patrones Atípicos y Clasificación Clínica
- **Polimenorrea (Ciclos Frecuentes):** Intervalos menores a 24 días entre inicios menstruales.
- **Oligomenorrea (Ciclos Infrecuentes):** Intervalos mayores a 38 días consecutivos.
- **Sangrado Prolongado:** Sangrado que excede los 8 días de duración.
- **Sangrado Intermenstrual:** Manchado o sangrado activo entre períodos menstruales esperados.

## Consideraciones Clínicas Especiales
En la adolescencia temprana (primeros 2 a 3 años posmenarquia), la inmadurez fisiológica del eje hipotálamo-hipófisis-ovario hace normales variaciones de entre 21 y 45 días.
Ante condiciones crónicas como el Síndrome de Ovario Poliquístico (SOP) o la Endometriosis, el seguimiento longitudinal permite correlacionar el dolor pélvico incapacitante y la anovulación sin emitir juicios diagnósticos prematuros.
""",
            target_life_stages=["adolescence", "regular_adult"],
            clinical_tags=[
                "ciclo_menstrual",
                "figo",
                "sangrado_uterino",
                "sop",
                "ginecologia",
            ],
            scientific_source="FIGO Menstrual Disorders Committee (2018/2022 Guidelines)",
            source_url="https://www.figo.org/guidelines-menstrual-disorders",
            reviewed_by="Comité Clínico de Ginecología Cora",
            reading_time_minutes=4,
            published_at=now,
        ),
        ClinicalArticle(
            id=uuid4(),
            slug="criterios-acog-hipertension-gestacional-preeclampsia",
            title="Criterios ACOG para Trastornos Hipertensivos del Embarazo y Preeclampsia",
            summary=(
                "Recomendaciones del Colegio Americano de Obstetras y Ginecólogos (ACOG) para la "
                "detección temprana de hipertensión gestacional, signos de gravedad y prevención de preeclampsia."
            ),
            body_markdown="""# Detección y Manejo Preventivo de la Preeclampsia (ACOG)

Los trastornos hipertensivos del embarazo representan una de las principales causas de morbimortalidad materna y fetal a nivel global.

## Definición y Umbrales Tensionales
- **Presión Arterial Normal en Embarazo:** Sistólica menor a 120 mmHg y diastólica menor a 80 mmHg.
- **Hipertensión Gestacional:** Presión arterial sistólica mayor o igual a 140 mmHg y/o diastólica mayor o igual a 90 mmHg, registrada en dos ocasiones separadas por al menos 4 horas después de la semana 20 de gestación en una mujer previamente normotensa.
- **Hipertensión Severa:** Presión sistólica mayor o igual a 160 mmHg y/o diastólica mayor o igual a 110 mmHg. Requiere confirmación en minutos y manejo médico urgente.

## Banderas Rojas y Criterios de Severidad
La presencia de hipertensión arterial asociada a cualquiera de los siguientes síntomas constituye una emergencia obstétrica:
- Cefalea intensa y persistente que no cede con analgésicos habituales.
- Alteraciones visuales (visión borrosa, escotomas o fosfenos / destellos de luz).
- Epigastralgia severa o dolor agudo e irradiado en hipocondrio derecho.
- Edema súbito y marcado en rostro y manos.

Toda alerta obstétrica en Cora prioriza la derivación inmediata a urgencias hospitalarias.
""",
            target_life_stages=["pregnancy"],
            clinical_tags=[
                "embarazo",
                "preeclampsia",
                "acog",
                "presion_arterial",
                "obstetricia",
            ],
            scientific_source="ACOG Practice Bulletin No. 222: Gestational Hypertension and Preeclampsia",
            source_url="https://www.acog.org/clinical/clinical-guidance/practice-bulletin/articles/2020/06/gestational-hypertension-and-preeclampsia",
            reviewed_by="Comité Clínico de Obstetricia Cora",
            reading_time_minutes=5,
            published_at=now,
        ),
        ClinicalArticle(
            id=uuid4(),
            slug="transicion-menopausica-criterios-straw10",
            title="Transición a la Menopausia y Criterios de Estadificación STRAW+10",
            summary=(
                "Marco científico estandarizado de la arquitectura del envejecimiento reproductivo (STRAW+10), "
                "síntomas vasomotores y cuidado integral de la salud ósea y metabólica."
            ),
            body_markdown="""# Clasificación STRAW+10 del Envejecimiento Reproductivo

El taller *Stages of Reproductive Aging Workshop + 10* (STRAW+10) es el estándar de oro para categorizar las fases de transición hormonal en la mujer:

## Fases de la Transición
1. **Perimenopausia Temprana (Etapa -2):** Variabilidad persistente en la duración de los ciclos menstruales (diferencia mayor o igual a 7 días entre ciclos consecutivos).
2. **Perimenopausia Tardía (Etapa -1):** Intervalo de amenorrea mayor o igual a 60 días continuos. Marcada fluctuación de los niveles de estradiol y elevación de FSH.
3. **Menopausia Establecida (Etapa +1a):** Cese definitivo de las menstruaciones confirmado tras 12 meses consecutivos de amenorrea espontánea sin causas patológicas ni farmacológicas.

## Síndromes y Manejo Clínico Preventivo
- **Síntomas Vasomotores:** Sofocos o bochornos y sudoraciones nocturnas debido a la inestabilidad del centro termorregulador hipotalámico.
- **Salud Ósea y Prevención de Osteopenia/Osteoporosis:** Monitorización de densitometría ósea y consumo adecuado de calcio y vitamina D.
- **Salud Urogenital:** Manejo del síndrome genitourinario de la menopausia para prevenir atrofia vulvovaginal e incontinencia de esfuerzo.
""",
            target_life_stages=["perimenopause", "senior_vitality"],
            clinical_tags=[
                "menopausia",
                "perimenopausia",
                "straw10",
                "sofocos",
                "salud_osea",
            ],
            scientific_source="STRAW+10 Collaborative Group / The North American Menopause Society",
            source_url="https://www.menopause.org/for-professionals/straw-10",
            reviewed_by="Comité Clínico de Endocrinología y Ginecología Cora",
            reading_time_minutes=5,
            published_at=now,
        ),
        ClinicalArticle(
            id=uuid4(),
            slug="escala-edimburgo-epds-salud-mental-perinatal",
            title="Detección de Depresión Perinatal y Escala de Edimburgo (EPDS)",
            summary=(
                "Protocolo clínico de tamizaje de salud mental en el posparto utilizando la Escala de Depresión "
                "Postnatal de Edimburgo (EPDS), puntos de corte clínico y protocolo de contención inmediata."
            ),
            body_markdown="""# Tamizaje de Salud Mental en el Posparto con EPDS

La depresión perinatal y posparto afecta aproximadamente a una de cada siete madres, requiriendo un enfoque proactivo, empático y libre de estigmas.

## Estructura de la Escala EPDS
La Escala de Edimburgo consta de 10 ítems autoadministrados que evalúan el estado de ánimo, la ansiedad, la culpa y la anhedonia durante los últimos 7 días, con un puntaje total de 0 a 30 puntos.

## Interpretación de Resultados Clínicos
- **0 a 9 puntos:** Síntomas depresivos poco probables. Continuar con apoyo perinatal y educación comunitaria habitual.
- **10 a 12 puntos:** Riesgo de sintomatología depresiva leve a moderada. Se recomienda seguimiento estrecho y valoración por el equipo de salud primaria.
- **13 o más puntos:** Alta probabilidad de episodio depresivo mayor. Requiere evaluación médica y psicológica formal prioritaria.

## Protocolo Crítico: Ítem 10 (Pensamientos de Autolesión)
**Invariante de Seguridad:** Si la respuesta al Ítem 10 ("La idea de hacerme daño se me ha ocurrido") es mayor a 0 (incluso con puntaje total menor a 10), el sistema activa de forma inmediata y automática una pantalla de contención y enlaces directos a líneas nacionales de crisis y auxilio psicológico 24/7.
""",
            target_life_stages=["postpartum"],
            clinical_tags=[
                "posparto",
                "salud_mental",
                "epds",
                "depresion_posparto",
                "puerperio",
            ],
            scientific_source="Cox, J.L., Holden, J.M., and Sagovsky, R. (British Journal of Psychiatry)",
            source_url="https://www.psychiatry.org/patients-families/postpartum-depression",
            reviewed_by="Comité Clínico de Salud Mental Perinatal Cora",
            reading_time_minutes=4,
            published_at=now,
        ),
        ClinicalArticle(
            id=uuid4(),
            slug="calendario-vacunacion-preventiva-salud-femenina",
            title="Calendario de Vacunación Preventiva en la Mujer a lo Largo de la Vida",
            summary=(
                "Esquema de inmunización recomendado por la OMS y los CDC para la mujer en edad reproductiva, "
                "gestación y adultez mayor, previniendo cáncer de cuello uterino e infecciones graves."
            ),
            body_markdown="""# Inmunización Preventiva en la Salud Femenina

La vacunación a lo largo de las distintas etapas de la vida previene complicaciones obstétricas e infecciosas graves:

## Vacunación contra el Virus del Papiloma Humano (VPH)
- Recomendada preferentemente entre los 9 y 14 años (esquema de una o dos dosis según guías locales).
- Disponible y eficaz hasta los 26 a 45 años para prevenir lesiones precancerosas de cérvix, vulva y vagina causadas por serotipos oncogénicos (16, 18, entre otros).

## Vacunas Durante el Embarazo
- **dTpa (Difteria, Tétanos y Tos Ferina Acelular):** Debe administrarse en cada embarazo entre las semanas 27 y 36 de gestación para transferir anticuerpos protectores transplacentarios al recién nacido contra la tos ferina.
- **Influenza Estacional:** Altamente recomendada durante cualquier trimestre del embarazo durante la temporada de virus respiratorios.

## Vacunación en la Adultez Mayor
- Vacuna contra el virus del herpes zóster (culebrilla).
- Vacuna antineumocócica conjugada para prevención de neumonías y bacteriemias en mayores de 60 años.
""",
            target_life_stages=[
                "adolescence",
                "regular_adult",
                "pregnancy",
                "senior_vitality",
            ],
            clinical_tags=[
                "vacunacion",
                "vph",
                "dtpa",
                "inmunizacion",
                "medicina_preventiva",
            ],
            scientific_source="World Health Organization (WHO) / Centers for Disease Control and Prevention (CDC)",
            source_url="https://www.cdc.gov/vaccines/schedules/hcp/imz/adult.html",
            reviewed_by="Comité Clínico de Medicina Preventiva Cora",
            reading_time_minutes=4,
            published_at=now,
        ),
        ClinicalArticle(
            id=uuid4(),
            slug="biomarcadores-fertilidad-metodo-sintotermico",
            title="Biomarcadores de Fertilidad y Algoritmo Sintotérmico",
            summary=(
                "Fundamento fisiológico de la ventana fértil femenina: correlación entre temperatura basal, "
                "moco cervical tipo clara de huevo, pico de hormona luteinizante (LH) y regla de 3 sobre 6."
            ),
            body_markdown="""# Fundamentos Fisiológicos del Método Sintotérmico

El reconocimiento de la fertilidad se basa en la monitorización de biomarcadores que responden a las fluctuaciones hormonales de estrógeno y progesterona:

## Biomarcadores Principales
1. **Temperatura Basal Corporal (BBT):** Temperatura tomada inmediatamente al despertar tras al menos 3 a 5 horas de sueño continuo. La progesterona postovulatoria produce un incremento térmico de entre 0.2 °C y 0.5 °C.
2. **Moco Cervical:** Bajo el influjo estrogénico preovulatorio, el moco se torna transparente, elástico, lubricado y fluido (consistencia de clara de huevo), facilitando el paso y supervivencia de los espermatozoides.
3. **Tiras Reactivas de Hormona Luteinizante (LH):** El pico de LH precede a la ovulación en un rango de 24 a 36 horas.

## Regla de las Tres sobre Seis (3 sobre 6)
Para confirmar objetivamente la ocurrencia de la ovulación, se requiere que la temperatura basal se mantenga durante tres días consecutivos por encima de la línea base establecida por las seis mediciones previas a la subida térmica.
Esta información complementa la planificación reproductiva o la observación ginecológica sin sustituir la consulta con especialistas en reproducción.
""",
            target_life_stages=["conception_search", "regular_adult"],
            clinical_tags=[
                "fertilidad",
                "temperatura_basal",
                "moco_cervical",
                "sintotermico",
                "lh",
            ],
            scientific_source="Sensiplan / American College of Obstetricians and Gynecologists (ACOG)",
            source_url="https://www.acog.org/womens-health/faqs/fertility-awareness-based-methods-of-family-planning",
            reviewed_by="Comité Clínico de Fertilidad Cora",
            reading_time_minutes=4,
            published_at=now,
        ),
    ]


async def run_ingestion(
    dry_run: bool = False,
    skip_embed: bool = False,
    db_url: str | None = None,
    api_key: str | None = None,
) -> int:
    """Execute corpus ingestion into PostgreSQL pgvector."""
    settings = get_settings()
    target_db_url = db_url or settings.database_url
    target_api_key = api_key or settings.gemini_api_key

    articles = get_canonical_clinical_corpus()
    chunker = SemanticMarkdownChunker(target_words=300, max_words=450)

    print(f"📚 [INGEST] Processing {len(articles)} canonical clinical articles...")

    total_chunks = 0
    for article in articles:
        chunks = chunker.chunk_article(article)
        total_chunks += len(chunks)
        print(
            f"   📄 '{article.title[:50]}...' -> {len(chunks)} chunks "
            f"(etapas: {', '.join(article.target_life_stages)})"
        )

    print(f"\n📊 Total chunks generated: {total_chunks}")

    if dry_run:
        print(
            "✅ [DRY RUN SUCCESS] Chunking and metadata validated. No database writes performed."
        )
        return total_chunks

    print(
        "\n🚀 [INGESTION] Connecting to PostgreSQL and embedding with Gemini Embedding 2..."
    )
    from sqlalchemy.ext.asyncio import (
        AsyncSession,
        async_sessionmaker,
        create_async_engine,
    )

    engine = create_async_engine(target_db_url, echo=False)
    session_factory = async_sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )

    class MockEmbeddingAdapter:
        def embed_batch(self, texts: list[str]) -> list[list[float]]:
            return [[0.0] * 768 for _ in texts]

        def embed_text(self, text: str) -> list[float]:
            return [0.0] * 768

    embedder: GeminiEmbeddingAdapter | MockEmbeddingAdapter
    if skip_embed or not target_api_key:
        print(
            "⚠️ [EMBEDDING] Using mock 768d embeddings (--skip-embed or no GEMINI_API_KEY)."
        )
        embedder = MockEmbeddingAdapter()
    else:
        print(
            "🧠 [EMBEDDING] Initializing GeminiEmbeddingAdapter (gemini-embedding-2, 768d)..."
        )
        embedder = GeminiEmbeddingAdapter(
            api_key=target_api_key,
            model_name=settings.gemini_embedding_model,
            dimensions=settings.gemini_embedding_dimensions,
        )

    async with session_factory() as session:
        repo = PostgresEducationRepository(
            session=session, embedding_generator=embedder
        )
        use_case = IngestClinicalCorpusUseCase(
            repository=repo,
            chunker=chunker,
            embedding_generator=embedder,
        )
        ingested_count = await use_case.execute(articles)
        await session.commit()

    await engine.dispose()
    print(
        f"🎉 Successfully ingested and indexed {ingested_count} clinical articles with {total_chunks} chunks!"
    )
    return ingested_count


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Ingest curated clinical evidence into PostgreSQL pgvector for Cora."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Run chunking and validation without writing to database or calling APIs.",
    )
    parser.add_argument(
        "--skip-embed",
        action="store_true",
        help="Use zero vectors (768d) instead of calling the live Gemini Embedding API.",
    )
    parser.add_argument(
        "--db-url",
        help="Optional database URL override (default: reads from settings).",
    )
    parser.add_argument(
        "--api-key",
        help="Optional Gemini API key override (default: reads from settings).",
    )
    args = parser.parse_args()

    count = asyncio.run(
        run_ingestion(
            dry_run=args.dry_run,
            skip_embed=args.skip_embed,
            db_url=args.db_url,
            api_key=args.api_key,
        )
    )
    sys.exit(0 if count > 0 else 1)


if __name__ == "__main__":
    main()
