# Documentación de Fase 01 — Cimientos del Monorepo, Infraestructura Base y CI/CD

- **Fase:** 01
- **Nombre:** Cimientos del Monorepo, Infraestructura Base y CI/CD
- **Estado:** ✅ Completada
- **Fecha:** 2026-11-07
- **Repositorio:** [eduardoevz/Cora](https://github.com/eduardoevz/Cora)
- **Rama:** `main`

---

## 1. Resumen Ejecutivo de la Fase

La **Fase 01** materializó la infraestructura base ejecutable y los cimientos de ingeniería para **Cora**, tanto en backend como en frontend móvil, garantizando desde el primer commit un entorno altamente tipado, desacoplado y seguro:

1. **Backend Asíncrono Modular:** Inicialización de `FastAPI` con `Python 3.12+`, tipado estricto bajo `mypy --strict`, linter de alta velocidad `ruff`, configuración centralizada basada en `pydantic-settings` y formateador universal de errores biomédicos bajo el estándar **RFC 7807 (`ProblemDetails`)**.
2. **Infraestructura de Datos e Idempotencia:** Configuración de `PostgreSQL 16` con soporte vectorial nativo (`pgvector`), migración inicial de base de datos con `Alembic` reversible, y motor determinista de almacenamiento de idempotencia (`IdempotencyStore`) para prevenir la duplicación de mutaciones clínicas móviles ante interrupciones de red (`client_mutation_id`).
3. **Spec-Driven Development (SDD Contract-First):** Implementación del generador y exportador de contratos OpenAPI determinista (`backend/scripts/export_openapi.py`), versionado en `contracts/openapi.json`, junto con su prueba automatizada de detección de deriva (`test_openapi_drift.py`) que previene asimetrías entre backend y clientes móviles.
4. **Cliente Móvil Flutter *Offline-First*:** Inicialización del proyecto móvil con Flutter 3.x / Dart 3.x, base de datos local SQLite reactiva mediante **Drift**, orquestador de sincronización encolada (`SyncCoordinator`), cliente de red tipado sobre `Dio` con inyección obligatoria de cabeceras de idempotencia y decodificación de RFC 7807, y sistema de temas con soporte nativo de **Alta Legibilidad (WCAG AAA)** probado bajo escalado de accesibilidad `2.0x`.
5. **Automatización y Calidad Continua (CI/CD):** Creación de 4 flujos en GitHub Actions (`ci-backend.yml`, `ci-mobile.yml`, `security-and-contracts.yml`, `cd-release-template.yml`) asegurando análisis estático, pruebas unitarias y de integración sobre servicios vivos de `pgvector`, verificación de deriva OpenAPI, escaneo de secretos y empaquetado Docker.

---

## 2. Arquitectura, Módulos y Archivos Implementados

### Backend (`backend/`)
- `pyproject.toml`: Configuración de dependencias modernas (`fastapi`, `pydantic`, `pydantic-settings`, `sqlalchemy[asyncio]`, `asyncpg`, `pgvector`, `alembic`, `pytest`, `pytest-cov`, `mypy`, `ruff`).
- `Dockerfile`: Construcción multi-stage ligera en Python 3.12 con usuario sin privilegios `cora`, dependencias de renderizado Cairo/Pango listas para WeasyPrint.
- `docker-compose.yml`: Servicio de base de datos local `postgres` con imagen `pgvector/pgvector:pg16` y healthcheck integrado.
- `app/core/config.py`: Agregado inmutable de configuración `Settings` con validación estricta de entorno (`development`, `testing`, `production`) y URLs seguras.
- `app/core/errors.py`: Jerarquía de excepciones de dominio (`DomainError`, `EntityNotFoundError`, `ConflictError`, `ValidationError`) serializadas automáticamente como `application/problem+json` (RFC 7807).
- `app/core/database.py`: Motor `create_async_engine` de SQLAlchemy 2.0, `async_sessionmaker` y generador asíncrono de sesiones `get_async_session()`.
- `app/core/idempotency.py`: Modelo ORM `IdempotentMutation` mapeado con índice único compuesto `(user_id, client_mutation_id)` y servicio `IdempotencyStore` con estados de procesamiento (`pending`, `completed`, `failed`).
- `app/main.py`: Fábrica de aplicación `create_app()` con middleware CORS, manejadores de excepción RFC 7807 y endpoint de verificación `/api/v1/health`.
- `alembic.ini` y `alembic/versions/0001_enable_pgvector_and_idempotency.py`: Migración fundacional que habilita la extensión `vector` e inicializa la tabla de mutaciones idempotentes.
- `scripts/export_openapi.py`: Script CLI determinista que extrae el esquema OpenAPI de FastAPI, ordena claves alfabéticamente y verifica o sobrescribe el contrato.
- `tests/unit/core/test_errors_and_health.py`: Pruebas unitarias de healthcheck y serialización RFC 7807.
- `tests/integration/core/test_db_and_idempotency.py`: Pruebas de integración del ciclo de vida de transacciones asíncronas y deduplicación de mutaciones.
- `tests/contract/test_openapi_drift.py`: Prueba de contrato que verifica igualdad estricta con `contracts/openapi.json`.

### Contratos (`contracts/`)
- `contracts/openapi.json`: Contrato REST determinista exportado y versionado como única fuente de verdad para clientes externos.

### Móvil (`mobile/`)
- `pubspec.yaml` y `pubspec.lock`: Configuración de dependencias (`flutter_riverpod`, `drift`, `sqlite3_flutter_libs`, `dio`, `uuid`).
- `analysis_options.yaml`: Reglas de análisis estático estrictas de Flutter sin tolerar advertencias ni infos (`--fatal-infos`).
- `lib/core/database/app_database.dart` y `app_database.g.dart`: Base de datos SQLite local generada por Drift con la tabla `SyncOutboxEntries` (`clientMutationId`, `entityType`, `entityId`, `operation`, `payloadJson`, `status`, `attemptCount`, `createdAt`).
- `lib/core/sync/sync_coordinator.dart`: Servicio *Offline-First* que encola mutaciones localmente de forma inmediata y las despacha ordenadamente contra el backend con gestión de reintentos y marcado `synced`/`failed`.
- `lib/core/network/cora_api_client.dart`: Cliente HTTP sobre `Dio` que intercepta peticiones inyectando `X-Client-Mutation-Id` y mapea respuestas de error RFC 7807 a `ProblemDetailsException`.
- `lib/core/theme/cora_theme.dart`: Paleta cromática biomédica (`coraRose`, `coraPlum`, `coraSage`, `coraSlate`) con dos variantes: estándar y `highLegibility` con contraste WCAG AAA superior a 7:1.
- `lib/main.dart`: Raíz `CoraApp` envuelta en `ProviderScope` de Riverpod.
- `test/core/sync_outbox_test.dart`: Pruebas unitarias sobre SQLite en memoria que verifican encolado, deduplicación y cambio de estado ante éxito o fallas transitorias de red.
- `test/core/theme_accessibility_test.dart`: Pruebas de widgets que verifican el contraste tipográfico y la ausencia de desbordamientos visuales (*overflows*) bajo escalado `2.0x`.

### Integración y Despliegue Continuo (`.github/workflows/`)
- `.github/workflows/ci-backend.yml`: Pipeline para backend (Ruff check/format, Mypy strict, Pytest con cobertura >= 80% sobre contenedor vivo `pgvector:pg16`).
- `.github/workflows/ci-mobile.yml`: Pipeline para móvil (Flutter stable, comprobación de generación de Drift, `flutter analyze --fatal-infos`, `flutter test --coverage`).
- `.github/workflows/security-and-contracts.yml`: Verificación de deriva de OpenAPI y escaneo exhaustivo de secretos con Gitleaks.
- `.github/workflows/cd-release-template.yml`: Flujo de empaquetado de contenedores Docker reproducible para lanzamientos y tags de versión.

---

## 3. Decisiones Técnicas y Reglas Clínicas Aplicadas

1. **Idempotencia Biomédica Estricta (`client_mutation_id`):** En aplicaciones de salud y fertilidad donde una usuaria registra medicamentos, dosis o contracciones con conectividad intermitente, reenviar una petición POST/PUT jamás debe generar registros duplicados ni cálculos erróneos. El par `(user_id, client_mutation_id)` se valida a nivel de base de datos relacional y se almacena el payload de respuesta procesado.
2. **Estándar RFC 7807 (`ProblemDetails`):** Los errores de validación de signos vitales (presión arterial fuera de límites fisiológicos, fechas de amenorrea incompatibles) requieren que el cliente móvil interprete con precisión la causa exacta sin ambigüedad. Usar `application/problem+json` estandariza el manejo de errores en todas las capas.
3. **Drift SQLite Reactivo frente a Caché Clásica:** Se seleccionó Drift en lugar de soluciones NoSQL porque Drift proporciona integridad referencial estricta, consultas tipadas en tiempo de compilación y soporte transparente de migraciones para la futura carpeta médica y esquemas de las 7 etapas biológicas.
4. **Accesibilidad para Todas las Etapas de Vida (WCAG AAA):** Desde la juventud hasta la etapa de plenitud (Fase 8), la accesibilidad visual es crítica. Se diseñó el tema `highLegibility` con ratios de contraste >= 7:1 y se validó en test automatizado que la interfaz soporte escalado `2.0x` sin roturas de layout.
5. **Spec-Driven Development (SDD):** El backend es el emisor autoritativo del contrato. El test `test_openapi_drift.py` garantiza en local y en CI que ningún desarrollador o agente modifique una firma de API sin actualizar conscientemente el artefacto `contracts/openapi.json`.

---

## 4. Pruebas Ejecutadas y Validación CI/CD

### Backend
```text
tests/contract/test_openapi_drift.py .                                   [ 20%]
tests/integration/core/test_db_and_idempotency.py .                      [ 40%]
tests/unit/core/test_errors_and_health.py ...                            [100%]

Name                      Stmts   Miss  Cover   Missing
-------------------------------------------------------
app/__init__.py               1      0   100%
app/core/__init__.py          0      0   100%
app/core/config.py           25      0   100%
app/core/database.py         22     11    50%
app/core/errors.py           38      6    84%
app/core/idempotency.py      36      0   100%
app/main.py                  22      0   100%
-------------------------------------------------------
TOTAL                       144     17    88%
5 passed in 3.90s
```
- **Ruff check:** `All checks passed!`
- **Ruff format --check:** `8 files already formatted.`
- **Mypy strict:** `Success: no issues found in 8 source files`

### Mobile
```text
00:00 +0: C:/Cora/mobile/test/core/sync_outbox_test.dart: SyncCoordinator enqueues mutation into Drift outbox in pending status
00:00 +1: C:/Cora/mobile/test/core/sync_outbox_test.dart: SyncCoordinator marks mutation as synced upon successful push
00:00 +2: C:/Cora/mobile/test/core/sync_outbox_test.dart: SyncCoordinator increments attempt count and marks failed on error
00:00 +3: C:/Cora/mobile/test/core/theme_accessibility_test.dart: CoraTheme provides standard and highLegibility themes
00:00 +4: C:/Cora/mobile/test/core/theme_accessibility_test.dart: Shell UI renders cleanly without overflow under 2.0x accessibility text scaling
00:02 +5: All tests passed!
```
- **Flutter analyze --fatal-infos:** `No issues found! (ran in 10.0s)`
- **Drift build_runner:** `Built with build_runner/aot; wrote 16 outputs.`

---

## 5. Secuencia de Commits Realizados

| Hash | Mensaje de Commit Convencional | Descripción del Cambio |
| :--- | :--- | :--- |
| `8da8b87` | `feat(core): bootstrap FastAPI app with strict typing and RFC 7807 error handling` | Estructura inicial de FastAPI, tipado estricto, configuración y middleware RFC 7807 con tests unitarios. |
| `6a64c15` | `db(core): configure async SQLAlchemy, pgvector migration, Docker, and idempotency store` | Docker Compose con `pgvector:pg16`, Dockerfile multi-stage, migración Alembic 0001 e `IdempotencyStore`. |
| `64155c7` | `feat(core): add OpenAPI contract exporter and schema drift contract test` | Script `export_openapi.py`, exportación de `contracts/openapi.json` y test contra deriva de esquema. |
| `2910531` | `feat(mobile-core): initialize Flutter app with Riverpod, Drift sync outbox, and accessible themes` | Inicialización de app Flutter, Riverpod, Drift SQLite con outbox de sincronización y temas WCAG AAA. |
| `7466514` | `ci: add backend, mobile, OpenAPI contract, security, and release CD workflows` | Creación de 4 flujos en GitHub Actions (`ci-backend`, `ci-mobile`, `security-and-contracts`, `cd-release-template`). |
| `79ac9d5` | `docs(plan): mark phase 01 tasks completed` | Actualización de casillas de verificación en `phase-01-foundation-and-cicd.md` y roadmap general. |
| *Actual* | `docs(documentacion): add phase-01 completion report in documentacion/` | Bitácora oficial de cierre de la Fase 01 en `documentacion/` y actualización del índice principal. |

---

## 6. Estado para la Siguiente Fase (Fase 02)

Con la **Fase 01** completamente aprobada y verificada:
- **Base de Datos y Modelos:** La base PostgreSQL con extensión `vector` está lista para recibir las tablas del módulo `identity` (`users`, `user_profiles`, `life_stages`).
- **Autenticación:** El middleware y el inyector de dependencias de FastAPI están listos para recibir el validador de tokens Firebase JWT en `app/modules/identity/`.
- **Móvil:** La base Drift local cuenta con el patrón outbox funcional para almacenar el perfil de usuario y estado biológico antes de sincronizar con el backend.
- **Siguiente sesión:** Ejecución de la **Fase 02** siguiendo [`docs/phases/phase-02-identity-onboarding-lifestage.md`](../docs/phases/phase-02-identity-onboarding-lifestage.md).
