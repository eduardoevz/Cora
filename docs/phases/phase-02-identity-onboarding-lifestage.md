# Fase 02 — Identidad, Onboarding de 3 Capas y `LifeStageStateMachine` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir el módulo hexagonal `identity` completo con validación criptográfica de Firebase JWT, el flujo empático de **Onboarding Progresivo de 3 Capas**, la máquina de estados `LifeStageStateMachine` con historial longitudinal inmutable, la **Modularidad a la Carta** y el **Home Dashboard Dinámico** en Flutter.

**Architecture:** En `backend/app/modules/identity/`, el agregado `UserProfile` encapsula las 3 capas de calibración, las preferencias de módulos visibles y `LifeStageStateMachine`, registrando cada cambio de etapa en `LifeStageTransitionHistory` sin sobrescribir datos previos. En `mobile/lib/features/onboarding/` y `dashboard/`, Riverpod escucha el perfil persistido en Drift para renderizar tarjetas adaptadas a la etapa activa y los hasta 3 objetivos priorizados.

**Tech Stack:** FastAPI, `firebase-admin` (JWT verification), SQLAlchemy 2.0 Async, Alembic, Flutter, Riverpod, Drift, `firebase_auth`.

**Spec:** `docs/SPECS.MD` (Secciones 1 y 2), `docs/desarrollo.md` (Secciones 2.1 y 4.1)

## Global Constraints

- Las 7 etapas canónicas (`LifeStage`) son: `adolescence`, `regular_adult`, `conception_search`, `pregnancy`, `postpartum`, `perimenopause`, `senior_vitality`.
- Capa 2 (Intención Principal) exige mínimo `1` y máximo `3` selecciones simultáneas (`InvalidOnboardingGoalsError` si `0` o `> 3`).
- Capa 3 (Contexto Clínico Base: anticonceptivos/hormonas y condiciones como SOP, Endometriosis, Tiroides, Resistencia a la insulina/Diabetes) es estrictamente **opcional** ("Responder después" nunca bloquea el acceso).
- Transicionar de etapa con `LifeStageStateMachine` archiva el periodo/etapa previa con marca de tiempo UTC y motivo, preservando intacto el historial longitudinal.

## Review Focus

1. **Selección de más de 3 prioridades en Capa 2 o lista vacía:** Tanto el Value Object en backend como el selector en Flutter deben impedir `0` o `>= 4` intenciones.
2. **Omisión completa de Capa 3 ("Responder después"):** El perfil debe quedar marcado como `onboarding_completed = True` y `clinical_context_completed = False`, mostrando un recordatorio no intrusivo en ajustes sin bloquear el dashboard.
3. **Transición sensible en embarazo (parto vs pérdida gestacional):** `LifeStageStateMachine` debe soportar tanto `PREGNANCY -> POSTPARTUM` como `PREGNANCY -> REGULAR_ADULT` ajustando inmediatamente el tono comunicacional y desactivando recordatorios fetales para evitar daño emocional.
4. **Suplantación de identidad entre usuarias:** Un token Firebase válido con `uid = A` jamás puede leer ni mutar el perfil de `uid = B`; todas las rutas de perfil resuelven el usuario exclusivamente desde `CurrentUserDep`.
5. **Conmutación de etapa sin conexión a internet:** Cambiar de etapa o pausar un módulo secundario en el avión debe reflejarse al instante en el *Home Dashboard* desde Drift y encolarse en `sync_outbox`.

---

### Task 1: Dominio de `identity` — `LifeStage`, Contexto de 3 Capas y `LifeStageStateMachine` (TDD)

**Files:**
- Create: `backend/app/modules/identity/domain/value_objects/life_stage.py`
- Create: `backend/app/modules/identity/domain/value_objects/onboarding_context.py`
- Create: `backend/app/modules/identity/domain/models/user_profile.py`
- Create: `backend/app/modules/identity/domain/services/life_stage_state_machine.py`
- Create: `backend/app/modules/identity/domain/exceptions/identity_exceptions.py`
- Test: `backend/tests/unit/identity/test_life_stage_state_machine.py`
- Test: `backend/tests/unit/identity/test_onboarding_validation.py`

**Interfaces:**
- Consumes: `DomainError` (`backend/app/core/errors.py`)
- Produces:
  - `LifeStage(StrEnum)`, `PrimaryIntent(StrEnum)`, `HormonalMethod(StrEnum)`, `DiagnosedCondition(StrEnum)`
  - `UserProfile` (`complete_onboarding(...)`, `switch_life_stage(target: LifeStage, reason: TransitionReason, occurred_at: datetime) -> LifeStageTransition`)
  - `LifeStageStateMachine.validate_and_compute_defaults(current: LifeStage, target: LifeStage, birth_year: int) -> StageTransitionPlan`

- [x] **Step 1: Escribir pruebas unitarias parametrizadas en `test_onboarding_validation.py` (edad/año de nacimiento válido, `1..3` intenciones, Capa 3 nula/completa) y `test_life_stage_state_machine.py` (todas las transiciones válidas, bloqueo de transiciones incoherentes sin confirmación explícita, preservación de historial y módulos por defecto por etapa)**
- [x] **Step 2: Ejecutar pytest para confirmar fallo**
  - Run: `pytest backend/tests/unit/identity -v`
  - Expected: FAIL
- [x] **Step 3: Implementar los Value Objects inmutables, excepciones semánticas, `UserProfile` y `LifeStageStateMachine` en dominio puro**
- [x] **Step 4: Verificar pase en `< 50 ms` y `mypy --strict`**
  - Run: `mypy --strict backend/app && pytest backend/tests/unit/identity -v`
  - Expected: PASS
- [x] **Step 5: Commit**
  - `git add backend/app/modules/identity/domain backend/tests/unit/identity`
  - `git commit -m "feat(identity): implement 3-layer onboarding domain models and LifeStageStateMachine with TDD"`

---

### Task 2: Middleware de Autenticación Firebase JWT y Puertos/Casos de Uso de `identity`

**Files:**
- Create: `backend/app/core/security.py`
- Create: `backend/app/modules/identity/application/ports/token_verifier_port.py`
- Create: `backend/app/modules/identity/application/ports/user_profile_repository_port.py`
- Create: `backend/app/modules/identity/application/use_cases/complete_onboarding_use_case.py`
- Create: `backend/app/modules/identity/application/use_cases/switch_life_stage_use_case.py`
- Create: `backend/app/modules/identity/application/use_cases/update_module_preferences_use_case.py`
- Create: `backend/app/modules/identity/infrastructure/adapters/firebase_token_verifier.py`
- Test: `backend/tests/unit/identity/test_identity_use_cases.py`

**Interfaces:**
- Consumes: `UserProfile`, `LifeStageStateMachine` de Task 1
- Produces:
  - `AuthenticatedUser` y dependencia `CurrentUserDep` en `backend/app/core/security.py`
  - `IUserProfileRepository` (puerto público reutilizable por otros módulos para consultar la etapa activa y condiciones base de una usuaria)

- [x] **Step 1: Escribir tests unitarios con repositorios en memoria y verificador JWT fake probando token expirado/inválido (`401`), alta idempotente en onboarding, cambio de etapa y activación/pausa de módulos secundarios**
- [x] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/unit/identity/test_identity_use_cases.py -v`
  - Expected: FAIL
- [x] **Step 3: Implementar `security.py`, `FirebaseTokenVerifier`, puertos y casos de uso**
- [x] **Step 4: Ejecutar pruebas unitarias y linter**
  - Run: `ruff check backend && mypy --strict backend/app && pytest backend/tests/unit/identity -v`
  - Expected: PASS
- [x] **Step 5: Commit**
  - `git add backend/app/core/security.py backend/app/modules/identity/application backend/app/modules/identity/infrastructure/adapters/firebase_token_verifier.py backend/tests/unit/identity/test_identity_use_cases.py`
  - `git commit -m "feat(identity): add Firebase JWT verification and onboarding/stage-switching use cases"`

---

### Task 3: Persistencia PostgreSQL (`user_profiles` + `life_stage_transitions`), Endpoints REST y Contrato OpenAPI

**Files:**
- Create: `backend/alembic/versions/0002_create_identity_tables.py`
- Create: `backend/app/modules/identity/infrastructure/orm/identity_models.py`
- Create: `backend/app/modules/identity/infrastructure/adapters/postgres_user_profile_repository.py`
- Create: `backend/app/modules/identity/infrastructure/entrypoints/router.py`
- Create: `backend/app/modules/identity/infrastructure/entrypoints/schemas.py`
- Modify: `backend/app/main.py`
- Modify: `contracts/openapi.json`
- Test: `backend/tests/integration/identity/test_identity_api.py`

**Interfaces:**
- Consumes: Casos de uso de Task 2, `IdempotencyService` de Fase 1
- Produces:
  - `GET /api/v1/identity/me`
  - `PUT /api/v1/identity/onboarding`
  - `POST /api/v1/identity/life-stage/transitions`
  - `PATCH /api/v1/identity/module-preferences`

- [x] **Step 1: Escribir tests de integración HTTP contra PostgreSQL verificando onboarding completo, onboarding omitiendo Capa 3, transición longitudinal (`GET /me` conserva historial de transiciones) y aislamiento entre dos `firebase_uid` distintos**
- [x] **Step 2: Ejecutar pytest y verificar fallo**
  - Run: `pytest backend/tests/integration/identity/test_identity_api.py -v`
  - Expected: FAIL
- [x] **Step 3: Crear migración Alembic `0002`, modelos ORM, repositorio Postgres, router FastAPI y regenerar `contracts/openapi.json`**
- [x] **Step 4: Verificar migración reversible (`upgrade` -> `downgrade` -> `upgrade`), integración y contrato OpenAPI**
  - Run: `python backend/scripts/export_openapi.py && pytest backend/tests -v`
  - Expected: PASS
- [x] **Step 5: Commit**
  - `git add backend/alembic/versions/0002_create_identity_tables.py backend/app/modules/identity/infrastructure backend/app/main.py contracts/openapi.json backend/tests/integration/identity/test_identity_api.py`
  - `git commit -m "feat(identity): add PostgreSQL persistence, REST endpoints, and OpenAPI schemas for identity"`

---

### Task 4: Flujo Móvil Flutter — Autenticación, Onboarding Progresivo de 3 Capas, *Life-Stage Switcher* y *Home Dashboard* Dinámico

**Files:**
- Create: `mobile/lib/features/onboarding/domain/entities/user_profile_entity.dart`
- Create: `mobile/lib/features/onboarding/data/local/profile_dao.dart`
- Create: `mobile/lib/features/onboarding/data/repositories/identity_repository_impl.dart`
- Create: `mobile/lib/features/onboarding/presentation/providers/identity_providers.dart`
- Create: `mobile/lib/features/onboarding/presentation/pages/onboarding_wizard_page.dart`
- Create: `mobile/lib/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart`
- Create: `mobile/lib/features/dashboard/presentation/widgets/life_stage_switcher_sheet.dart`
- Create: `mobile/lib/features/dashboard/presentation/widgets/module_preferences_page.dart`
- Modify: `mobile/lib/core/database/app_database.dart`
- Test: `mobile/test/features/onboarding/onboarding_wizard_test.dart`
- Test: `mobile/test/features/dashboard/dynamic_dashboard_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `SyncCoordinator`, `CoraApiClient` (Fase 1), endpoints `/api/v1/identity/*`
- Produces:
  - `activeUserProfileProvider` y `enabledModulesProvider` (consumidos por todas las features de Fases 3–11)
  - `OnboardingWizardPage`, `DynamicHomeDashboardPage`, `LifeStageSwitcherSheet`, `ModulePreferencesPage`

- [x] **Step 1: Escribir widget/unit tests verificando: límite máximo de 3 intenciones en Capa 2, botón "Responder después" en Capa 3, cambio reactivo de tarjetas del *Home Dashboard* al conmutar de `regular_adult` a `pregnancy` o `senior_vitality` (activando tema `highLegibility`), y ocultamiento de módulos pausados**
- [x] **Step 2: Ejecutar `flutter test` y verificar fallo**
  - Run: `cd mobile && flutter test test/features/onboarding test/features/dashboard`
  - Expected: FAIL
- [x] **Step 3: Implementar tablas Drift de perfil e historial de etapas, repositorio *Offline-First*, providers Riverpod y pantallas accesibles en español empático**
- [x] **Step 4: Ejecutar generación de código, análisis estático y toda la suite de pruebas móvil**
  - Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-infos && flutter test`
  - Expected: PASS
- [x] **Step 5: Commits finales y actualización de progreso de Fase 02**
  - `git add mobile`
  - `git commit -m "feat(mobile-ui): build 3-layer onboarding wizard, life-stage switcher, and dynamic dashboard"`
  - `git add docs/phases/phase-02-identity-onboarding-lifestage.md docs/phases/README.md`
  - `git commit -m "docs(plan): mark phase 02 tasks completed"`
