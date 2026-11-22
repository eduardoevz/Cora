# Fase 14 — Onboarding con Últimos 2 Periodos, Regularidad, Duración del Ciclo y Motor de Proyección Mensual

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Capturar la línea base menstrual real durante el onboarding (inicio y fin de los últimos 2 periodos mediante calendario interactivo, regularidad y duración habitual del ciclo, adaptada a la etapa de vida), persistirla de manera atómica en Backend (`identity` + `clinical_tracking`) y en Mobile (*Offline-First* Drift SQLite), y construir un motor determinista de proyección diaria del calendario menstrual (`CycleCalendarProjectionService` en Python y `CycleCalendarEngine` en Dart) con paridad total y contrato OpenAPI sincronizado.

**Architecture:** `OnboardingContext` se enriquece con `cycle_regularity`, `typical_cycle_length_days` y `typical_bleeding_duration_days` (Alembic `0014` y migración Drift). Al finalizar `PUT /api/v1/identity/onboarding` (o `POST /api/v1/cycles/initial-periods`), `clinical_tracking` siembra los últimos 2 `MenstrualCycle` con sus días de sangrado y calcula la duración real del ciclo. `CycleCalendarProjectionService` proyecta cada día de cualquier mes con fase, marcadores (`RECORDED_PERIOD`, `PREDICTED_PERIOD`, `FERTILE_WINDOW`, `PREDICTED_OVULATION`, `SPOTTING`), probabilidad fértil y textos educativos en español adaptados a las 7 etapas biológicas.

**Tech Stack:** Python 3.12+, FastAPI, SQLAlchemy 2.0 Async, Alembic, Flutter, Riverpod, Drift SQLite, SDD (`contracts/openapi.json`).

**Spec:** `docs/SPECS.MD`, `docs/DESIGN.md`, `.agents/rules/02-architecture-and-sdd.md`, `.agents/rules/03-clinical-tdd-and-safety.md`, `.agents/rules/05-mobile-flutter-offline-first.md`.

## Global Constraints

- Pureza hexagonal: `CycleCalendarProjectionService` y `CycleCalendarEngine` no importan FastAPI, SQLAlchemy, Dio ni Flutter UI.
- Reglas clínicas obligatorias:
  - Si se registran 2 periodos (`P1` anterior y `P2` último), `P1.start_date < P2.start_date`, `P1.end_date < P2.start_date` (sin solapamientos), y la duración calculada inicial es `(P2.start_date - P1.start_date).days`.
  - Si `cycle_regularity == IRREGULAR`, `life_stage == ADOLESCENCE` o `has_pcos`, activar `has_extended_uncertainty = True` y mostrar advertencia educativa no determinista.
  - Si `is_hormonally_suppressed` (anticoncepción hormonal combinada/DIU hormonal/implante) o etapas `PREGNANCY`, `POSTPARTUM`, `SENIOR_VITALITY`: suprimir predicciones de ovulación natural y adaptar el calendario a la etapa biológica correspondiente.
- Compatibilidad hacia atrás en DB (Neon PostgreSQL y Drift local): todas las columnas nuevas son nulables o tienen valores por defecto seguros.

---

### Task 1: Dominio Backend `OnboardingContext` Menstrual + `CycleCalendarProjectionService` (TDD)

**Files:**
- Modify: `backend/app/modules/identity/domain/value_objects/onboarding_context.py`
- Modify: `backend/app/modules/clinical_tracking/domain/value_objects/bleeding_and_symptoms.py`
- Modify: `backend/app/modules/clinical_tracking/domain/services/cycle_phase_and_prediction_service.py`
- Create: `backend/app/modules/clinical_tracking/domain/services/cycle_calendar_projection_service.py`
- Test: `backend/tests/unit/clinical_tracking/test_cycle_calendar_projection.py`

- [x] **Step 1: Escribir tests unitarios parametrizados para `CycleRegularity`, calibración por duración declarada (`24–38d`, regular vs irregular, adolescencia `21–45d`, SOP, método hormonal) y proyección mensual completa (`RECORDED_PERIOD`, `PREDICTED_PERIOD`, `FERTILE_WINDOW`, `PREDICTED_OVULATION`, meses futuros y adaptación de las 7 etapas)**
- [x] **Step 2: Ejecutar pytest y confirmar fallo (Red)**
- [x] **Step 3: Implementar cambios de dominio puro y `CycleCalendarProjectionService`**
- [x] **Step 4: Verificar `ruff`, `mypy --strict app scripts tests` y pytest en `< 50 ms` (Green)**
- [x] **Step 5: Commit**
  - `git commit -m "feat(clinical-tracking): add menstrual baseline calibration and monthly calendar projection domain service"`

---

### Task 2: Migración Alembic `0014`, Siembra de 2 Periodos Iniciales y Endpoints REST + OpenAPI (TDD)

**Files:**
- Create: `backend/alembic/versions/0014_add_menstrual_baseline_to_profiles.py`
- Modify: `backend/app/modules/identity/infrastructure/orm/identity_models.py`
- Modify: `backend/app/modules/identity/infrastructure/entrypoints/schemas.py`
- Modify: `backend/app/modules/identity/infrastructure/entrypoints/router.py`
- Create: `backend/app/modules/clinical_tracking/application/use_cases/seed_initial_periods_use_case.py`
- Create: `backend/app/modules/clinical_tracking/application/use_cases/get_cycle_calendar_use_case.py`
- Modify: `backend/app/modules/clinical_tracking/infrastructure/entrypoints/cycle_schemas.py`
- Modify: `backend/app/modules/clinical_tracking/infrastructure/entrypoints/cycle_router.py`
- Modify: `contracts/openapi.json`
- Test: `backend/tests/integration/clinical_tracking/test_cycle_calendar_and_seed_api.py`

- [x] **Step 1: Crear migración Alembic reversible `0014` y mapear campos en `UserProfileModel`**
- [x] **Step 2: Implementar `SeedInitialPeriodsUseCase`, `GetCycleCalendarUseCase`, endpoint `GET /api/v1/cycles/calendar` y `POST /api/v1/cycles/initial-periods`, además de soporte de `initial_periods` en `PUT /api/v1/identity/onboarding`**
- [x] **Step 3: Exportar y verificar contrato SDD (`contracts/openapi.json`)**
- [x] **Step 4: Escribir y ejecutar tests de integración y contrato en verde**
- [x] **Step 5: Commits atómicos (`db(identity): ...` y `feat(clinical-tracking): ...`)**

---

### Task 3: Drift SQLite Schema + Motor `CycleCalendarEngine` Offline-First en Dart (TDD)

**Files:**
- Modify: `mobile/lib/core/database/app_database.dart`
- Modify: `mobile/lib/core/database/app_database.g.dart`
- Modify: `mobile/lib/features/onboarding/domain/entities/user_profile_entity.dart`
- Modify: `mobile/lib/features/onboarding/data/local/profile_dao.dart`
- Modify: `mobile/lib/features/onboarding/data/repositories/identity_repository_impl.dart`
- Create: `mobile/lib/features/cycle/domain/services/cycle_calendar_engine.dart`
- Modify: `mobile/lib/features/cycle/domain/entities/cycle_entities.dart`
- Modify: `mobile/lib/features/cycle/domain/repositories/cycle_repository.dart`
- Modify: `mobile/lib/features/cycle/data/cycle_repository_impl.dart`
- Test: `mobile/test/features/cycle/cycle_calendar_engine_test.dart`

- [x] **Step 1: Escribir tests unitarios en Dart puro para `CycleCalendarEngine` (mismos casos clínicos que Python: 2 periodos iniciales, ciclo 26/28/33 días, regular vs irregular, adolescencia, SOP, hormonal, embarazo, posparto, perimenopausia STRAW+10, plenitud sénior)**
- [x] **Step 2: Implementar migración segura en `AppDatabase` (`build_runner`), `CycleCalendarEngine` y `CycleRepositoryImpl.seedInitialPeriods()` eliminando el `const cycleLen = 28` fijo**
- [x] **Step 3: Verificar `dart format`, `flutter analyze --fatal-infos` y `flutter test` en verde**
- [x] **Step 4: Commit**
  - `git commit -m "feat(mobile-sync): add Drift v11 menstrual baseline migration and offline-first CycleCalendarEngine"`

---

### Task 4: Paso Interactivo de Onboarding para Últimos 2 Periodos, Regularidad y Duración (TDD)

**Files:**
- Create: `mobile/lib/features/onboarding/presentation/widgets/initial_periods_calendar_picker.dart`
- Modify: `mobile/lib/features/onboarding/presentation/pages/onboarding_wizard_page.dart`
- Test: `mobile/test/features/onboarding/onboarding_menstrual_baseline_test.dart`

- [x] **Step 1: Escribir widget tests verificando selección interactiva de Periodo 1 y Periodo 2 (inicio y fin), cálculo automático de duración del ciclo, selector Regular/Irregular, salto respetuoso en Embarazo/Plenitud Sénior y siembra automática en Drift al completar**
- [x] **Step 2: Implementar `InitialPeriodsCalendarPicker` e integrarlo en `OnboardingWizardPage` siguiendo `docs/DESIGN.md`**
- [x] **Step 3: Actualizar tests existentes de onboarding si es necesario y verificar `flutter test` completo en verde**
- [x] **Step 4: Commit**
  - `git commit -m "feat(mobile-ui): add interactive 2-period calendar baseline step to onboarding wizard"`

---

### Task 5: Cierre de Fase 14, Documentación y Verificación de CI en Verde

**Files:**
- Modify: `docs/phases/phase-14-onboarding-menstrual-baseline-and-engine.md`
- Modify: `docs/phases/README.md`
- Create: `documentacion/fase-14-onboarding-menstrual-y-motor-calendario.md`
- Modify: `documentacion/README.md`

- [ ] **Step 1: Actualizar checkboxes y `docs/phases/README.md`**
- [ ] **Step 2: Push a `origin/main` y verificar `Backend CI`, `Mobile CI` y `Security & OpenAPI Contract Verification` en verde (`success`)**
- [ ] **Step 3: Crear reporte en `documentacion/fase-14-onboarding-menstrual-y-motor-calendario.md`, actualizar índice, commit, push y re-verificar CI**
