---
trigger: model_decision
description: Activar al escribir pruebas unitarias, de integracion, de contrato o E2E, o al crear y modificar workflows de GitHub Actions en .github/workflows/ y configuraciones Docker.
---

# Regla 07 — Estrategia de Pruebas Multicapa y CI/CD en GitHub Actions

## 1. Pirámide de Pruebas y Umbrales de Cobertura

Ninguna funcionalidad se considera terminada sin pruebas automatizadas ejecutadas y verificadas:

| Nivel | Ubicación | Aislamiento y Velocidad | Cobertura / Criterio de Éxito |
| :--- | :--- | :--- | :--- |
| **1. Unit Domain (TDD)** | `backend/tests/unit/` y `mobile/test/features/*/domain/` | Cero red, cero DB real, cero disco (`< 50 ms` por test) | **>= 95%** en capas `domain/` y **100%** en interceptores de seguridad y escalas clínicas (FIGO, ACOG, EPDS). |
| **2. Integration Backend** | `backend/tests/integration/` | Contenedor real `pgvector/pgvector:pg16` + migraciones Alembic + mocks deterministas de Firebase/R2/Gemini | **>= 85%** global en backend; verifica aislamiento por `user_id` y búsqueda vectorial HNSW real. |
| **3. Contract Tests (SDD)** | `backend/tests/contract/` | Exporta `openapi.json` desde FastAPI y lo compara con el contrato versionado + cliente Dart | **0 diferencias** sin actualizar; bloquea PRs con rupturas silenciosas entre API y app móvil. |
| **4. Mobile Data & Widget** | `mobile/test/` | Drift en memoria (`NativeDatabase.memory()`) + overrides de providers Riverpod | Prueba colas `sync_outbox`, estados vacíos/error/carga, accesibilidad (`textScaler: 2.0`) y flujos de UI. |
| **5. End-to-End (E2E)** | `mobile/integration_test/` | App Flutter completa contra backend en Docker Compose | Recorridos críticos: Onboarding → Registro Offline → Sincronización → Alerta Clínica → PDF / Chat RAG. |

## 2. Arquitectura de Pipelines CI/CD en GitHub Actions (`.github/workflows/`)

Los workflows deben ser rápidos, reproducibles, con permisos mínimos (`permissions: contents: read`) y ejecutarse automáticamente en `push` a `main` y en todo `pull_request`:

1. **`ci-backend.yml`** (disparado ante cambios en `backend/**` o `.github/workflows/**`):
   - Configura Python `3.12` + caché de `uv`/`pip`.
   - Ejecuta `ruff check`, `ruff format --check` y `mypy --strict`.
   - Ejecuta `pytest tests/unit` (fallo rápido).
   - Levanta un `service container` con `pgvector/pgvector:pg16`, corre `alembic upgrade head` y ejecuta `pytest tests/integration tests/contract --cov=app --cov-fail-under=85`.
   - Valida el build multi-stage de `backend/Dockerfile`.
2. **`ci-mobile.yml`** (disparado ante cambios en `mobile/**` o `.github/workflows/**`):
   - Configura Flutter canal `stable` con caché de Pub/Gradle.
   - Verifica código generado (`dart run build_runner build --delete-conflicting-outputs` sin cambios sucios), ejecuta `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos` y `flutter test --coverage`.
   - Compila artefacto de validación `flutter build apk --debug`.
3. **`security-and-contracts.yml`**:
   - Escaneo de secretos accidentales y auditoría de dependencias (`pip-audit` / `osv-scanner`) para proteger el repositorio público `eduardoevz/Cora`.
4. **`cd-release-template.yml`** (`workflow_dispatch` y tags `v*.*.*`):
   - Publica imagen Docker firmada en `ghcr.io/eduardoevz/cora-backend` y deja preparado el job parametrizado de despliegue continuo (ej. Google Cloud Run / Render) activable únicamente cuando existan los `GitHub Secrets` de entorno productivo, junto con la generación de `app-release.aab` para Android.

---

## 3. Protocolo Obligatorio de Verificación de CI en Cierre de Fase

**Regla de oro:** *Una fase no está terminada hasta que GitHub Actions certifique el árbol en verde.*

1. **Inspección en Vivo:** Tras realizar el push final de la fase a `eduardoevz/Cora`, ejecutar de inmediato:
   ```bash
   gh run list --limit 5
   gh run watch <run_id>
   ```
2. **Criterio de Aprobación Innegociable:**
   - La fase **SOLO** puede darse por cerrada si todos los workflows disparados (`Backend CI`, `Mobile CI`, `Security & OpenAPI`) culminan con estado `success`.
3. **Resolución Obligatoria ante Fallos (`failure`):**
   - El agente tiene estrictamente prohibido despedirse o declarar la fase completada si el CI falla.
   - Debe extraer los logs del fallo con:
     ```bash
     gh run view <run_id> --log-failed
     ```
   - Corregir el código o configuración, verificar en local con los linters/tests, hacer commit atómico (`fix(...)`) y nuevo `git push`.
   - Repetir la verificación con `gh run list` hasta que todos los flujos queden en verde (`success`).
