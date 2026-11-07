# Fase 01 — Cimientos del Monorepo, Infraestructura Base y CI/CD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Levantar la estructura ejecutable del monorepo (`backend/` FastAPI asíncrono + `mobile/` Flutter con Riverpod y Drift *Offline-First*), el entorno Docker local con `pgvector`, la generación de contratos OpenAPI (SDD) y los pipelines completos de CI/CD en GitHub Actions.

**Architecture:** Se establece el núcleo compartido libre de lógica de negocio (`app/core/` en backend y `lib/core/` en móvil): gestión de configuración tipada, sesiones asíncronas SQLAlchemy 2.0 + Alembic con extensión `vector`, manejo uniforme de errores RFC 7807, registro de idempotencia (`client_mutation_id`), base local SQLite en Drift con cola `sync_outbox` y sistema de temas base + alta legibilidad.

**Tech Stack:** Python 3.12+, FastAPI, Pydantic v2, SQLAlchemy 2.0 (`asyncpg`), Alembic, PostgreSQL 16 + `pgvector`, Docker, Flutter 3.x, Dart 3.x, `flutter_riverpod`, `drift`, `dio`, GitHub Actions.

**Spec:** `docs/SPECS.MD`, `docs/desarrollo.md`, `.agents/rules/02-architecture-and-sdd.md`, `.agents/rules/07-testing-and-cicd.md`

## Global Constraints

- Cero credenciales reales en el repositorio; crear únicamente `.env.example` con marcadores seguros.
- `ruff check`, `ruff format --check` y `mypy --strict` obligatorios desde el primer commit de Python.
- `flutter analyze --fatal-infos` y `flutter test` obligatorios desde el primer commit de Flutter.
- Todo error HTTP en FastAPI se serializa como `application/problem+json` (RFC 7807).
- `contracts/openapi.json` se versiona en el repositorio y falla en CI si diverge de `app.main:app`.

## Review Focus

1. **Arranque sin variables opcionales de terceros en tests locales:** `Settings` debe validar tipos estrictamente pero permitir perfiles `ENVIRONMENT=test` sin requerir conexión viva a Cloudflare R2 ni Gemini API.
2. ** Extensión `pgvector` ausente en base limpia:** La migración inicial `0001_initial_extensions_and_idempotency.py` debe ejecutar `CREATE EXTENSION IF NOT EXISTS vector;` antes de cualquier tabla vectorial futura.
3. **Duplicación de mutaciones ante corte de red móvil:** `IdempotencyStore` en backend y `SyncOutboxDao` en Drift deben deduplicar por `(user_id, client_mutation_id)`.
4. **Deriva silenciosa de contrato OpenAPI:** El script `scripts/export_openapi.py` y su test de contrato deben detectar cualquier cambio de esquema en FastAPI no exportado a `contracts/openapi.json`.
5. **Desbordamiento visual en escalado de accesibilidad (`2.0x`):** El shell inicial de Flutter (`CoraApp`) debe probarse con `TextScaler.linear(2.0)` tanto en tema estándar como en tema `highLegibility`.

---

### Task 1: Inicialización del Backend FastAPI, Tipado Estricto y Manejo de Errores RFC 7807

**Files:**
- Create: `backend/pyproject.toml`
- Create: `backend/.env.example`
- Create: `backend/app/__init__.py`
- Create: `backend/app/core/__init__.py`
- Create: `backend/app/core/config.py`
- Create: `backend/app/core/errors.py`
- Create: `backend/app/main.py`
- Test: `backend/tests/unit/core/test_errors_and_health.py`

**Interfaces:**
- Consumes: Variables de entorno del sistema / `.env`
- Produces:
  - `Settings` y `get_settings() -> Settings` en `backend/app/core/config.py`
  - `DomainError(code: str, title: str, detail: str, status_code: int = 400)` y `ProblemDetails` en `backend/app/core/errors.py`
  - `create_app() -> FastAPI` y `GET /api/v1/health` en `backend/app/main.py`

- [ ] **Step 1: Escribir tests unitarios fallidos para `/api/v1/health`, carga de `Settings` en modo `test` y serialización RFC 7807**
  - Incluir test que dispare `DomainError("invalid_vital_range", ...)` y verifique `Content-Type: application/problem+json` con campos `type`, `title`, `status`, `detail`, `code`.
- [ ] **Step 2: Ejecutar pytest para confirmar el fallo inicial**
  - Run: `pytest backend/tests/unit/core/test_errors_and_health.py -v`
  - Expected: FAIL (`ModuleNotFoundError: No module named 'app'`)
- [ ] **Step 3: Implementar `pyproject.toml` (FastAPI, Pydantic Settings, SQLAlchemy Async, Ruff, Mypy, Pytest), `config.py`, `errors.py` y `main.py`**
- [ ] **Step 4: Verificar tests, linter y tipado estricto**
  - Run: `ruff check backend && mypy --strict backend/app && pytest backend/tests/unit/core/test_errors_and_health.py -v`
  - Expected: PASS (`0` errores)
- [ ] **Step 5: Commit**
  - `git add backend/pyproject.toml backend/.env.example backend/app backend/tests/unit/core/test_errors_and_health.py`
  - `git commit -m "feat(core): bootstrap FastAPI app with strict typing and RFC 7807 error handling"`

---

### Task 2: Infraestructura PostgreSQL Async + `pgvector`, Alembic y Tabla de Idempotencia

**Files:**
- Create: `docker-compose.yml`
- Create: `backend/Dockerfile`
- Create: `backend/alembic.ini`
- Create: `backend/alembic/env.py`
- Create: `backend/alembic/versions/0001_enable_pgvector_and_idempotency.py`
- Create: `backend/app/core/database.py`
- Create: `backend/app/core/idempotency.py`
- Test: `backend/tests/integration/core/test_db_and_idempotency.py`

**Interfaces:**
- Consumes: `Settings.database_url` de Task 1
- Produces:
  - `Base`, `get_async_session() -> AsyncIterator[AsyncSession]` en `backend/app/core/database.py`
  - `IdempotencyService.check_or_record(session, user_id: UUID, client_mutation_id: UUID, ...) -> CachedMutationResponse | None` en `backend/app/core/idempotency.py`

- [ ] **Step 1: Escribir tests de integración fallidos verificando extensión `vector` activa y deduplicación por `(user_id, client_mutation_id)`**
- [ ] **Step 2: Ejecutar test de integración para verificar fallo**
  - Run: `pytest backend/tests/integration/core/test_db_and_idempotency.py -v`
  - Expected: FAIL (`ImportError` / tabla inexistente)
- [ ] **Step 3: Implementar `docker-compose.yml` (`pgvector/pgvector:pg16`), `Dockerfile` multi-stage (incluyendo librerías Pango/Cairo listas para WeasyPrint), `database.py`, `idempotency.py` y migración Alembic `0001` reversible (`upgrade` y `downgrade`)**
- [ ] **Step 4: Levantar Postgres con `pgvector`, correr migración y verificar tests**
  - Run: `alembic -c backend/alembic.ini upgrade head && pytest backend/tests/integration/core/test_db_and_idempotency.py -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add docker-compose.yml backend/Dockerfile backend/alembic.ini backend/alembic backend/app/core/database.py backend/app/core/idempotency.py backend/tests/integration/core/test_db_and_idempotency.py`
  - `git commit -m "db(core): configure async SQLAlchemy, pgvector migration, Docker, and idempotency store"`

---

### Task 3: Contrato SDD (`openapi.json`) y Test Automático contra Deriva de Esquema

**Files:**
- Create: `backend/scripts/export_openapi.py`
- Create: `contracts/openapi.json`
- Test: `backend/tests/contract/test_openapi_drift.py`

**Interfaces:**
- Consumes: `create_app()` de `backend/app/main.py`
- Produces: `contracts/openapi.json` determinista (keys ordenadas) consumido por `mobile/` y validado en CI

- [ ] **Step 1: Escribir `test_openapi_drift.py` comparando `create_app().openapi()` con `contracts/openapi.json`**
- [ ] **Step 2: Ejecutar test y confirmar que falla porque `contracts/openapi.json` aún no existe**
  - Run: `pytest backend/tests/contract/test_openapi_drift.py -v`
  - Expected: FAIL (`FileNotFoundError`)
- [ ] **Step 3: Implementar `export_openapi.py`, generar `contracts/openapi.json` y re-ejecutar el test**
- [ ] **Step 4: Verificar pase del test de contrato**
  - Run: `python backend/scripts/export_openapi.py && pytest backend/tests/contract/test_openapi_drift.py -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/scripts/export_openapi.py contracts/openapi.json backend/tests/contract/test_openapi_drift.py`
  - `git commit -m "feat(core): add OpenAPI contract exporter and schema drift contract test"`

---

### Task 4: Aplicación Móvil Flutter Base, Drift SQLite, `SyncCoordinator` Offline-First y Sistema de Temas

**Files:**
- Create: `mobile/pubspec.yaml`
- Create: `mobile/analysis_options.yaml`
- Create: `mobile/lib/main.dart`
- Create: `mobile/lib/core/database/app_database.dart`
- Create: `mobile/lib/core/sync/sync_coordinator.dart`
- Create: `mobile/lib/core/network/cora_api_client.dart`
- Create: `mobile/lib/core/theme/cora_theme.dart`
- Test: `mobile/test/core/sync_outbox_test.dart`
- Test: `mobile/test/core/theme_accessibility_test.dart`

**Interfaces:**
- Consumes: `contracts/openapi.json`
- Produces:
  - `AppDatabase` (Drift) con tabla `SyncOutboxEntries` (`clientMutationId`, `entityType`, `entityId`, `operation`, `payloadJson`, `status`, `attemptCount`, `createdAt`)
  - `SyncCoordinator` (`enqueueMutation(...)`, `flushPendingMutations()`)
  - `CoraTheme.standard()` y `CoraTheme.highLegibility()` (contraste WCAG AAA >= 7:1)

- [ ] **Step 1: Crear `pubspec.yaml` y escribir tests fallidos en `sync_outbox_test.dart` (encolado FIFO en memoria, reintento con backoff y marcado `synced`) y `theme_accessibility_test.dart` (renderizado con `TextScaler.linear(2.0)` sin overflow)**
- [ ] **Step 2: Ejecutar `flutter test` y verificar fallo inicial**
  - Run: `cd mobile && flutter test`
  - Expected: FAIL
- [ ] **Step 3: Implementar `AppDatabase` con Drift, `SyncCoordinator`, `CoraApiClient` (Dio con inyección de `X-Client-Mutation-Id` y parseo RFC 7807), `CoraTheme` y shell `CoraApp` con `ProviderScope` de Riverpod**
- [ ] **Step 4: Generar código (`build_runner`), analizar y ejecutar tests**
  - Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-infos && flutter test`
  - Expected: PASS (`0` issues, todos los tests en verde)
- [ ] **Step 5: Commit**
  - `git add mobile`
  - `git commit -m "feat(mobile-core): initialize Flutter app with Riverpod, Drift sync outbox, and accessible themes"`

---

### Task 5: Pipelines Completos de CI/CD en GitHub Actions

**Files:**
- Create: `.github/workflows/ci-backend.yml`
- Create: `.github/workflows/ci-mobile.yml`
- Create: `.github/workflows/security-and-contracts.yml`
- Create: `.github/workflows/cd-release-template.yml`
- Modify: `docs/phases/phase-01-foundation-and-cicd.md`
- Modify: `docs/phases/README.md`

**Interfaces:**
- Consumes: Estructura completa de Tasks 1–4
- Produces: Validación continua automática en GitHub para `eduardoevz/Cora`

- [ ] **Step 1: Implementar `ci-backend.yml` (Python 3.12, `ruff`, `mypy --strict`, `pytest` unit + integration sobre servicio `pgvector/pgvector:pg16` + build de `backend/Dockerfile`)**
- [ ] **Step 2: Implementar `ci-mobile.yml` (Flutter stable, verificación `build_runner`, `dart format`, `flutter analyze --fatal-infos`, `flutter test --coverage` y `flutter build apk --debug`)**
- [ ] **Step 3: Implementar `security-and-contracts.yml` (validación `export_openapi.py` sin diff + auditoría de dependencias/secretos) y `cd-release-template.yml` (publicación en GHCR + plantilla parametrizada de despliegue en tags `v*.*.*`)**
- [ ] **Step 4: Validar sintaxis YAML y correr toda la suite local antes de empujar**
  - Run: `ruff check backend && mypy --strict backend/app && pytest backend/tests -v && cd mobile && flutter analyze --fatal-infos && flutter test`
  - Expected: PASS
- [ ] **Step 5: Commits finales de la fase y actualización del roadmap**
  - `git add .github/workflows`
  - `git commit -m "ci: add backend, mobile, OpenAPI contract, security, and release CD workflows"`
  - `git add docs/phases/phase-01-foundation-and-cicd.md docs/phases/README.md`
  - `git commit -m "docs(plan): mark phase 01 tasks completed"`
