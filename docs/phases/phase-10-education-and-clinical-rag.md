# Fase 10 — Biblioteca Clínica Basada en Evidencia y Asistente RAG (`education_content` + `rag_assistant`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir el **Espacio de Aprendizaje Clínico Curado** (`education_content`) y el **Asistente Conversacional Inteligente con Memoria Contextual RAG** (`rag_assistant`), integrando `DeterministicSafetyInterceptor`, búsqueda vectorial HNSW en Neon `pgvector` con **`gemini-embedding-2`** y respuestas con citas médicas verificables mediante **`gemini-3.8-flash` (`store=False`)**.

**Architecture:** `education_content` gestiona artículos revisados clínicamente por etapa de vida con metadatos bibliográficos (OMS, ACOG, FIGO, NAMS) y los fragmenta e indexa en `pgvector` (`vector(768)` con índice HNSW coseno). `rag_assistant` ejecuta un pipeline estricto de 4 pasos: 1) `DeterministicSafetyInterceptor`, 2) recopilación anonimizada del resumen longitudinal de la usuaria autenticada + búsqueda semántica Top-K en `pgvector`, 3) inferencia en `google-genai` con `store=False`, y 4) entrega con citas clicables en Flutter.

**Tech Stack:** Python 3.12+, FastAPI, `google-genai >= 2.30.1`, SQLAlchemy 2.0 Async, `pgvector` (HNSW), Flutter, Riverpod, Drift.

**Spec:** `docs/SPECS.MD` (Sección 3.1 Espacio de Aprendizaje; Sección 4 Asistente Conversacional RAG), `docs/desarrollo.md` (Sección 4.3), `.agents/rules/06-gemini-rag-and-ai.md`

## Global Constraints

- **SDK y Modelos Fijos:** `google-genai >= 2.30.1` usando exclusivamente `gemini-3.8-flash` y `gemini-embedding-2` (`output_dimensionality=768`). Prohibido `google-generativeai` o `text-embedding-004`.
- **Privacidad PHI Inquebrantable:** `client.interactions.create(..., store=False)` obligatorio en toda llamada; jamás incluir `first_name`, `last_name` ni `email` de la usuaria en el prompt enviado a Gemini.
- **Prioridad absoluta del `DeterministicSafetyInterceptor`:** Si el mensaje del usuario contiene banderas rojas obstétricas, ginecológicas, cardiovasculares o de autolesión, el sistema responde en `< 5 ms` con la directiva de urgencias y **realiza `0` llamadas al cliente de Gemini**.
- Toda respuesta informativa del asistente debe incluir al menos una cita bibliográfica verificada del corpus (`citations`) o declarar explícitamente que no cuenta con evidencia suficiente en las guías validadas de Cora.

## Review Focus

1. **Evasión de palabras clave simples en emergencias médicas:** `DeterministicSafetyInterceptor` debe cubrir variantes coloquiales y sin tildes en español (*"estoy sangrando muchisimo"*, *"veo luces y me duele la cabeza embarazada"*, *"no siento moverse a mi bebe"*, *"no quiero seguir viviendo"*).
2. **Fuga accidental de datos entre usuarias en contexto RAG:** El ensamblador de memoria personal (`UserClinicalMemoryAssembler`) construye el resumen en tiempo de consulta filtrando estrictamente por `auth_user.user_id`; nunca almacena datos privados de usuarias en la tabla compartida de embeddings de literatura médica.
3. **Verificación unitaria de `store=False`:** Un test en `test_gemini_clinical_adapter.py` debe inspeccionar los `kwargs` pasados a `client.interactions.create` y fallar si `store` no es explícitamente `False`.
4. **Consultas temporales personales (*"¿En qué días de mi ciclo me suele dar migraña?"*):** `UserClinicalMemoryAssembler` debe pre-calcular correlaciones estadísticas deterministas (ej. día del ciclo y fase donde ocurrieron síntomas recurrentes en los últimos 6 meses) para que el LLM explique datos exactos en lugar de adivinar.
5. **Lectura offline de la Biblioteca Clínica en Flutter:** Los artículos descargados o marcados como favoritos por etapa se cachean en Drift para lectura sin conexión.

---

### Task 1: Módulo `education_content` — Corpus Clínico Curado, Chunking e Índice HNSW en `pgvector`

**Files:**
- Create: `backend/alembic/versions/0010_create_education_and_pgvector_hnsw_tables.py`
- Create: `backend/app/modules/education_content/domain/models/clinical_article.py`
- Create: `backend/app/modules/education_content/application/ports/embedding_generator_port.py`
- Create: `backend/app/modules/education_content/application/ports/education_repository_port.py`
- Create: `backend/app/modules/education_content/application/use_cases/ingest_and_query_articles_use_cases.py`
- Create: `backend/app/modules/education_content/infrastructure/adapters/gemini_embedding_adapter.py`
- Create: `backend/app/modules/education_content/infrastructure/adapters/postgres_education_vector_repository.py`
- Create: `backend/app/modules/education_content/infrastructure/entrypoints/education_router.py`
- Create: `backend/app/modules/education_content/seed/curated_clinical_corpus.json`
- Test: `backend/tests/integration/education_content/test_pgvector_hnsw_retrieval.py`

**Interfaces:**
- Consumes: `google.genai.Client.models.embed_content` (`gemini-embedding-2`, `768` dims)
- Produces:
  - `IEducationVectorRepository.search_verified_chunks(query_embedding: list[float], life_stage: LifeStage | None, limit: int = 5) -> list[VerifiedEvidenceChunk]`
  - `GET /api/v1/education/articles`, `GET /api/v1/education/articles/{slug}`

- [ ] **Step 1: Consultar con MCP `gemini_search_docs` los parámetros exactos de `client.models.embed_content` para `gemini-embedding-2` y escribir tests fallidos de ingesta/búsqueda por similitud coseno en PostgreSQL `pgvector` filtrando por `LifeStage`**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/integration/education_content/test_pgvector_hnsw_retrieval.py -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar migración `0010` con índice `USING hnsw (embedding vector_cosine_ops)`, `GeminiEmbeddingAdapter`, corpus semilla inicial revisado para las 7 etapas (ACOG, OMS, FIGO, NAMS) y endpoints de biblioteca**
- [ ] **Step 4: Verificar migración, búsqueda vectorial real y `mypy --strict`**
  - Run: `mypy --strict backend/app && pytest backend/tests/integration/education_content/test_pgvector_hnsw_retrieval.py -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/alembic/versions/0010_create_education_and_pgvector_hnsw_tables.py backend/app/modules/education_content backend/tests/integration/education_content`
  - `git commit -m "feat(education): add curated clinical library and pgvector HNSW search with gemini-embedding-2"`

---

### Task 2: `DeterministicSafetyInterceptor` y `UserClinicalMemoryAssembler` en `rag_assistant` (TDD)

**Files:**
- Create: `backend/app/modules/rag_assistant/domain/models/rag_conversation.py`
- Create: `backend/app/modules/rag_assistant/domain/services/deterministic_safety_interceptor.py`
- Create: `backend/app/modules/rag_assistant/domain/services/user_clinical_memory_assembler.py`
- Test: `backend/tests/unit/rag_assistant/test_deterministic_safety_interceptor.py`
- Test: `backend/tests/unit/rag_assistant/test_user_clinical_memory_assembler.py`

**Interfaces:**
- Consumes: Resúmenes de `identity`, `clinical_tracking`, `maternal_care`, `mature_health`, `treatments`
- Produces:
  - `SafetyTriageDecision` (`is_emergency: bool`, `category: str | None`, `directive_markdown_es: str | None`)
  - `DeterministicSafetyInterceptor.inspect(user_query: str, active_stage: LifeStage) -> SafetyTriageDecision`
  - `AnonymizedUserClinicalContext` (correlaciones exactas día-de-ciclo/síntoma, sin nombre ni correo)

- [ ] **Step 1: Escribir batería TDD con `>= 25` casos de banderas rojas (hemorragia severa, dolor pélvico agudo, cefalea+fosfenos en embarazo, ausencia de movimientos fetales, fiebre puerperal, dolor torácico, autolesión, con/sin acentos y modismos) más consultas benignas que NO deben ser bloqueadas, y tests de correlación de migraña/síntomas y anonimización PII en `UserClinicalMemoryAssembler`**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/unit/rag_assistant -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar `DeterministicSafetyInterceptor` y `UserClinicalMemoryAssembler`**
- [ ] **Step 4: Verificar ejecución en `< 20 ms` y `100%` de cobertura en el interceptor**
  - Run: `pytest backend/tests/unit/rag_assistant --cov=backend/app/modules/rag_assistant/domain/services/deterministic_safety_interceptor --cov-fail-under=100 -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/app/modules/rag_assistant/domain backend/tests/unit/rag_assistant`
  - `git commit -m "feat(rag-assistant): implement deterministic emergency safety interceptor and PII-free clinical memory assembler"`

---

### Task 3: `GeminiClinicalAssistantAdapter` (`gemini-3.8-flash`, `store=False`), Casos de Uso y API REST del Asistente

**Files:**
- Create: `backend/alembic/versions/0011_create_rag_conversations_tables.py`
- Create: `backend/app/modules/rag_assistant/application/ports/clinical_llm_port.py`
- Create: `backend/app/modules/rag_assistant/application/use_cases/ask_clinical_assistant_use_case.py`
- Create: `backend/app/modules/rag_assistant/infrastructure/adapters/gemini_clinical_assistant_adapter.py`
- Create: `backend/app/modules/rag_assistant/infrastructure/orm/rag_conversation_orm.py`
- Create: `backend/app/modules/rag_assistant/infrastructure/adapters/postgres_rag_conversation_repository.py`
- Create: `backend/app/modules/rag_assistant/infrastructure/entrypoints/rag_router.py`
- Modify: `backend/app/main.py`
- Modify: `contracts/openapi.json`
- Test: `backend/tests/unit/rag_assistant/test_gemini_clinical_adapter.py`
- Test: `backend/tests/integration/rag_assistant/test_rag_assistant_api.py`

**Interfaces:**
- Consumes: `DeterministicSafetyInterceptor`, `UserClinicalMemoryAssembler`, `IEducationVectorRepository`, `google.genai.Client.interactions.create`
- Produces:
  - `POST /api/v1/assistant/messages`, `GET /api/v1/assistant/conversations`, `DELETE /api/v1/assistant/conversations/{conversation_id}`

- [ ] **Step 1: Consultar con MCP `gemini_search_docs` la firma exacta de `client.interactions.create` + salida estructurada y escribir tests verificando: `store=False` estricto, `0` llamadas a Gemini cuando el interceptor detecta emergencia, e inclusión obligatoria de `citations` en consultas normales**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/unit/rag_assistant/test_gemini_clinical_adapter.py backend/tests/integration/rag_assistant/test_rag_assistant_api.py -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar `GeminiClinicalAssistantAdapter`, persistencia de hilos en PostgreSQL, caso de uso `AskClinicalAssistantUseCase`, router FastAPI y exportar `contracts/openapi.json`**
- [ ] **Step 4: Verificar toda la suite backend**
  - Run: `python backend/scripts/export_openapi.py && pytest backend/tests -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/alembic/versions/0011_create_rag_conversations_tables.py backend/app/modules/rag_assistant backend/app/main.py contracts/openapi.json backend/tests/unit/rag_assistant/test_gemini_clinical_adapter.py backend/tests/integration/rag_assistant/test_rag_assistant_api.py`
  - `git commit -m "feat(rag-assistant): integrate gemini-3.8-flash with store=False, grounded citations, and conversation API"`

---

### Task 4: Experiencia Móvil Flutter — Biblioteca Educativa Offline y Chat Clínico con Tarjetas de Evidencia y Urgencia

**Files:**
- Create: `mobile/lib/features/education/data/education_repository_impl.dart`
- Create: `mobile/lib/features/education/presentation/pages/clinical_library_page.dart`
- Create: `mobile/lib/features/assistant/domain/entities/assistant_message_entity.dart`
- Create: `mobile/lib/features/assistant/data/assistant_repository_impl.dart`
- Create: `mobile/lib/features/assistant/presentation/pages/cora_assistant_chat_page.dart`
- Create: `mobile/lib/features/assistant/presentation/widgets/citation_chips_and_emergency_banner.dart`
- Modify: `mobile/lib/core/database/app_database.dart`
- Modify: `mobile/lib/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart`
- Test: `mobile/test/features/assistant/assistant_chat_and_citations_test.dart`
- Test: `mobile/test/features/education/offline_library_test.dart`

**Interfaces:**
- Consumes: `/api/v1/education/*`, `/api/v1/assistant/*`, `AppDatabase`
- Produces: Módulos móviles de Espacio de Aprendizaje y Asistente Conversacional Cora

- [ ] **Step 1: Escribir tests en Flutter verificando: lectura offline de artículos cacheados por etapa, renderizado destacado de `EmergencyDirectiveBanner` cuando `isEmergency == true`, y despliegue de fuentes clínicas al tocar chips de citas (ACOG/OMS/FIGO)**
- [ ] **Step 2: Ejecutar `flutter test` y confirmar fallo**
  - Run: `cd mobile && flutter test test/features/assistant test/features/education`
  - Expected: FAIL
- [ ] **Step 3: Implementar caché Drift de artículos e historial de chat, repositorios y pantallas UI en Riverpod**
- [ ] **Step 4: Ejecutar `build_runner`, `flutter analyze` y `flutter test`**
  - Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-infos && flutter test`
  - Expected: PASS
- [ ] **Step 5: Commits finales y cierre de Fase 10**
  - `git add mobile`
  - `git commit -m "feat(mobile-ui): add offline clinical library and RAG assistant chat with verified citations"`
  - `git add docs/phases/phase-10-education-and-clinical-rag.md docs/phases/README.md`
  - `git commit -m "docs(plan): mark phase 10 tasks completed"`
