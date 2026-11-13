# Bitácora de Implementación — Paso 3: Automatización de la Ingesta del Corpus Clínico RAG en PostgreSQL (Neon)

**Fecha de ejecución:** 2026-11-13  
**Estado:** ✅ Completado

---

## 1. Resumen de lo Implementado

En este tercer paso operativo se automatizó la ingesta y vectorización semántica de la biblioteca clínica curada de **Cora** para alimentar el motor de búsqueda vectorial (`pgvector`) y el asistente clínico RAG:

1. **Script de Ingesta Automatizada (`backend/scripts/ingest_clinical_library.py`):**
   - Incorpora el **corpus clínico canónico** de 6 artículos exhaustivos basados en evidencia internacional que cubren las 7 etapas biológicas:
     - `guia-figo-sangrado-y-ciclo-menstrual`: Parámetros FIGO de frecuencia (24-38 días), duración (<= 8 días), polimenorrea, oligomenorrea y consideraciones de adolescencia/SOP.
     - `criterios-acog-hipertension-gestacional-preeclampsia`: Criterios ACOG para hipertensión gestacional (>= 140/90 mmHg) y banderas rojas de severidad (>= 160/110 mmHg, escotomas, cefalea intratable, epigastralgia).
     - `transicion-menopausica-criterios-straw10`: Fases de la perimenopausia temprana/tardía, amenorrea de 60 días, sofocos, salud ósea y bienestar urogenital.
     - `escala-edimburgo-epds-salud-mental-perinatal`: Tamizaje de depresión posparto EPDS (0-30 puntos), umbral de corte (>= 10-13) y protocolo incondicional de crisis para el Ítem 10 (> 0).
     - `calendario-vacunacion-preventiva-salud-femenina`: Inmunización preventiva (VPH, dTpa entre semanas 27-36 de gestación, influenza y vacunas de adultez mayor).
     - `biomarcadores-fertilidad-metodo-sintotermico`: Reconocimiento de fertilidad, temperatura basal corporal (BBT), moco cervical fértil, pico de LH y regla de las 3 sobre 6.
   - **Segmentación Semántica:** Emplea `SemanticMarkdownChunker` para dividir los artículos preservando títulos de sección, generando **21 chunks clínicos** de alta densidad informativa.
   - **Embeddings Vectoriales:** Se conecta a `gemini-embedding-2` generando vectores de 768 dimensiones e indexándolos en `clinical_evidence_chunks` con índice HNSW en Neon PostgreSQL.
   - **Modos de Operación:**
     - `--dry-run`: Valida el chunking y formato sin realizar escrituras ni consumir cuota de API.
     - `--skip-embed`: Permite pruebas de integración con vectores sintéticos (`[0.0] * 768`).
2. **Suite de Pruebas de Integración (`backend/tests/integration/test_clinical_ingestion_script.py`):**
   - Valida la integridad estructural de los 6 artículos canónicos (títulos, slugs, fuentes científicas, URLs HTTPS, tags y etapas).
   - Verifica el funcionamiento del modo `--dry-run` asegurando la generación de al menos 12 chunks.
   - Prueba de extremo a extremo de la persistencia relacional y vectorial en base de datos.

---

## 2. Archivos Creados
- `backend/scripts/ingest_clinical_library.py`
- `backend/tests/integration/test_clinical_ingestion_script.py`

---

## 3. Resultados de Pruebas y Linters
- `uv run python scripts/ingest_clinical_library.py --dry-run`: **Total chunks generated: 21 (PASS)**
- `uv run pytest tests/integration/test_clinical_ingestion_script.py`: **3 passed in 2.60s**
- `uv run ruff check scripts/ingest_clinical_library.py tests/integration/test_clinical_ingestion_script.py`: **All checks passed!**
- `uv run mypy --strict scripts/ingest_clinical_library.py tests/integration/test_clinical_ingestion_script.py`: **Success: no issues found in 2 source files**
