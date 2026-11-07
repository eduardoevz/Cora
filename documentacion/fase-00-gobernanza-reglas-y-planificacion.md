# Fase 00 — Gobernanza, Reglas del Proyecto y Planificación Maestro por Fases

**Fecha de cierre:** 2026-11-07  
**Estado:** ✅ Completada (Sin código de aplicación; 100% gobernanza, arquitectura y planificación)

---

## 1. Resumen Ejecutivo de la Fase

En esta fase fundacional se analizaron las especificaciones funcionales ([`docs/SPECS.MD`](../docs/SPECS.MD)) y técnicas ([`docs/desarrollo.md`](../docs/desarrollo.md)) de **Cora**, se resolvieron todas las decisiones abiertas de arquitectura junto con el propietario del proyecto, se configuró el sistema nativo de reglas para Antigravity, se redactaron los **12 planes detallados de implementación** para ejecutar una fase por sesión, y se creó y publicó el repositorio público **`eduardoevz/Cora`** en GitHub con un historial limpio de commits atómicos.

---

## 2. Arquitectura, Módulos y Archivos Implementados

- **Gobernanza y Seguridad Raíz:**
  - [`.gitignore`](../.gitignore): Bloqueo preventivo de `.env*`, `secrets/`, cuentas de servicio Firebase, llaves criptográficas, artefactos de compilación Python/Flutter y bases SQLite locales.
  - [`README.md`](../README.md): Portada pública del repositorio con diagrama de arquitectura, visión de las 7 etapas biológicas y mapa de navegación documental.
  - [`AGENTS.md`](../AGENTS.md): Regla jerárquica raíz para Antigravity con fuentes de verdad, protocolo sesión-por-fase e invariantes innegociables.
- **Reglas Modulares en [`.agents/rules/`](../.agents/rules/):**
  - `01-project-workflow-and-git.md` (`always_on`): Política de Conventional Commits atómicos, seguridad en repo público y documentación obligatoria en `documentacion/` al cerrar cada fase.
  - `02-architecture-and-sdd.md` (`always_on`): Monolito Modular Hexagonal (9 módulos), Clean Architecture Feature-First en Flutter y flujo SDD OpenAPI Contract-First.
  - `03-clinical-tdd-and-safety.md` (`always_on`): TDD biomédico estricto (FIGO, ACOG, STRAW+10, EPDS, fertilidad), `DeterministicSafetyInterceptor` y protección PHI en logs.
  - `04-backend-python-fastapi.md` (`model_decision`): Estándares de FastAPI, SQLAlchemy 2.0 Async, Alembic, aislamiento multi-tenant JWT, Cloudflare R2 y WeasyPrint seguro.
  - `05-mobile-flutter-offline-first.md` (`model_decision`): Riverpod codegen, Drift + `sync_outbox` idempotente, accesibilidad WCAG AAA y Modo Discreto.
  - `06-gemini-rag-and-ai.md` (`model_decision`): SDK `google-genai >= 2.30.1`, `gemini-3.8-flash` (`store=False`), `gemini-embedding-2` en `pgvector` HNSW y citas clínicas verificables.
  - `07-testing-and-cicd.md` (`model_decision`): Pirámide de pruebas (`>= 95%` cobertura en dominio, `>= 85%` global) y pipelines GitHub Actions CI/CD.
- **Planes Ejecutables por Sesión en [`docs/phases/`](../docs/phases/):**
  - Índice maestro [`docs/phases/README.md`](../docs/phases/README.md) y los 12 documentos detallados (`phase-01-foundation-and-cicd.md` hasta `phase-12-qa-e2e-security-release.md`).

---

## 3. Decisiones Técnicas Cerradas

1. **Gestión de estado móvil unificada:** Se fijó **Riverpod** (`riverpod_annotation` + `AsyncNotifier`) por su integración directa con streams reactivos de **Drift** (*Offline-First*).
2. **Actualización del stack de IA y privacidad médica:** Se reemplazó el modelo deprecado `text-embedding-004` por **`gemini-embedding-2`** y **`gemini-3.8-flash`** sobre el SDK oficial `google-genai >= 2.30.1` sin intermediarios pesados, exigiendo **`store=False`** en todas las interacciones para evitar retención externa de datos clínicos sensibles (PHI).
3. **Expansión a 9 Contextos Acotados (Bounded Contexts):** Se ampliaron los 5 módulos iniciales a 9 (`identity`, `clinical_tracking`, `maternal_care`, `mature_health`, `treatments`, `medical_records`, `education_content`, `rag_assistant`, `partner_sharing`) para cubrir el 100% de `SPECS.MD` manteniendo alta cohesión y responsabilidad única.
4. **Estrategia CI/CD completa:** Se diseñaron workflows automatizados para Backend, Mobile, Contrato OpenAPI/Seguridad y plantillas listas para Despliegue Continuo (CD).

---

## 4. Verificación Ejecutada

- Confirmación de `0` archivos de código de aplicación (`.py`, `.dart`, `.js`, `.ts`) respetando la restricción de planificación pura en Fase 0.
- Verificación de tamaño de todas las reglas en `.agents/rules/` (`3.1 KB – 3.8 KB` por archivo, muy por debajo del tope de `24 KB` de Antigravity) y carga automática comprobada.
- Creación y verificación del repositorio remoto público `https://github.com/eduardoevz/Cora` con rama principal `main` sincronizada.

---

## 5. Secuencia de Commits Realizados

1. `05db963` — `chore(repo): initialize gitignore for python, flutter, and medical secrets`
2. `65bd7a4` — `docs(specs): add product specification and aligned technical architecture`
3. `1eebf7f` — `docs(rules): add root AGENTS.md and core Antigravity workspace rules`
4. `d2ed0ff` — `docs(rules): add stack-specific rules for FastAPI, Flutter offline-first, Gemini RAG, and CI/CD`
5. `1fabfc5` — `docs(plan): add master roadmap and phases 01-03 foundation, identity, and core modules`
6. `6a30341` — `docs(plan): add phases 04-08 specialized life-stage clinical plans`
7. `51bb62b` — `docs(plan): add phases 09-12 medical records, clinical RAG, privacy, and QA release plans`
8. `934e67c` — `docs(readme): add public repository overview, architecture diagram, and session guide`
*(Más los commits de incorporación de la regla de bitácora en `documentacion/`).*

---

## 6. Estado para la Siguiente Fase (Fase 01)

Todo está listo para ejecutar [`docs/phases/phase-01-foundation-and-cicd.md`](../docs/phases/phase-01-foundation-and-cicd.md), donde se construirá el esqueleto ejecutable de `backend/` (FastAPI + SQLAlchemy Async + `pgvector` + RFC 7807), `mobile/` (Flutter + Riverpod + Drift `SyncCoordinator`), la exportación de `contracts/openapi.json` y los workflows de GitHub Actions CI/CD, generando al finalizar `documentacion/fase-01-cimientos-y-cicd.md`.
