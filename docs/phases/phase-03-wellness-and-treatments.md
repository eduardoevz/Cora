# Fase 03 — Núcleo Transversal: Bienestar/Hábitos y Gestor de Tratamientos Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir los dos primeros módulos transversales permanentes de Cora —el **Asistente de Bienestar y Hábitos** (`clinical_tracking` base) y el **Gestor de Tratamientos y Fármacos** (`treatments`)— operando 100% *Offline-First* con recordatorios locales inteligentes y cálculo clínico de adherencia.

**Architecture:** `clinical_tracking` introduce el registro diario transversal (`DailyWellnessLog`: calidad/horas de sueño, energía subjetiva, hidratación, actividad física y estados de ánimo) indexado por `(user_id, log_date)`. `treatments` modela regímenes terapéuticos (`TreatmentRegimen`: anticonceptivos combinados `21/7` o `24/4`, minipíldora continua, parches, inyectables, recambio de DIU/implante, TRH, suplementación de ácido fólico/hierro/calcio/magnesio/vitamina D y medicación crónica) junto con `DoseIntakeLog` y alertas de ventana de olvido.

**Tech Stack:** FastAPI, SQLAlchemy 2.0 Async, Alembic, Flutter, Riverpod, Drift, `flutter_local_notifications` (con textos enmascarables por privacidad).

**Spec:** `docs/SPECS.MD` (Sección 3.1: Asistente de Bienestar y Hábitos, Gestor de Tratamientos y Fármacos), `docs/desarrollo.md`

## Global Constraints

- Exactamente un `DailyWellnessLog` consolidado por `(user_id, log_date)` con actualización idempotente parcial (registrar agua al mediodía no borra las horas de sueño registradas en la mañana).
- Rangos fisiológicos validados en Value Objects: sueño `0.0–24.0 h`, calidad de sueño `1–5`, energía `1–5`, hidratación `0–10000 ml`, actividad física `0–1440 min`.
- Los recordatorios de notificaciones locales usan **texto neutro enmascarado por defecto** (*"Tienes un recordatorio de bienestar en Cora"*) salvo que la usuaria habilite explícitamente notificaciones detalladas.

## Review Focus

1. **Fusión parcial (*merge*) de registros diarios offline:** Dos ediciones offline sobre el mismo `log_date` (mañana: sueño + ánimo; noche: agua + ejercicio) deben consolidarse sin pisar campos previos.
2. **Esquemas cíclicos con días placebo/descanso (`21/7` o `24/4`) vs toma continua y recambios de largo plazo (DIU `3–10` años, implante `3` años):** El motor de programación no debe marcar falta de adherencia durante días de descanso programado.
3. **Ventana crítica de olvido en anticonceptivos orales:** Retraso `> 12h` (progestina sola) o `>= 24–48h` (combinadas) debe generar una orientación preventiva clara recomendando método de respaldo y consulta de prospecto/especialista.
4. **Cambios de zona horaria / horario de verano en recordatorios:** Los horarios de toma se almacenan como `LocalTime` (`HH:MM`) más zona IANA actual del dispositivo para evitar desajustes de una hora en viajes.
5. **Sincronización por lotes (`batch sync`):** Enviar 14 días acumulados sin conexión debe procesarse en una sola petición transaccional o lote ordenado respetando `client_mutation_id`.

---

### Task 1: Dominio de Bienestar Diario (`DailyWellnessLog`) en `clinical_tracking` (TDD)

**Files:**
- Create: `backend/app/modules/clinical_tracking/domain/value_objects/wellness_metrics.py`
- Create: `backend/app/modules/clinical_tracking/domain/models/daily_wellness_log.py`
- Create: `backend/app/modules/clinical_tracking/domain/exceptions/clinical_tracking_exceptions.py`
- Create: `backend/app/modules/clinical_tracking/application/ports/wellness_repository_port.py`
- Create: `backend/app/modules/clinical_tracking/application/use_cases/upsert_daily_wellness_use_case.py`
- Test: `backend/tests/unit/clinical_tracking/test_daily_wellness_log.py`

**Interfaces:**
- Consumes: `DomainError`
- Produces:
  - `SleepRecord`, `HydrationAmount`, `SubjectiveScale`, `MoodTag`
  - `DailyWellnessLog.merge_patch(...)`
  - `IWellnessRepository` y `UpsertDailyWellnessUseCase`

- [x] **Step 1: Escribir tests unitarios parametrizados para rangos válidos/inválidos de sueño, hidratación, energía, estados de ánimo múltiples y `merge_patch` sin pérdida de campos previos**
- [x] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/unit/clinical_tracking/test_daily_wellness_log.py -v`
  - Expected: FAIL
- [x] **Step 3: Implementar Value Objects, entidad `DailyWellnessLog`, puerto y caso de uso**
- [x] **Step 4: Verificar tests y `mypy --strict`**
  - Run: `mypy --strict backend/app && pytest backend/tests/unit/clinical_tracking/test_daily_wellness_log.py -v`
  - Expected: PASS
- [x] **Step 5: Commit**
  - `git add backend/app/modules/clinical_tracking backend/tests/unit/clinical_tracking/test_daily_wellness_log.py`
  - `git commit -m "feat(clinical-tracking): implement DailyWellnessLog domain model and merge-patch use case"`

---

### Task 2: Dominio del Gestor de Tratamientos, Adherencia y Alertas de Olvido en `treatments` (TDD)

**Files:**
- Create: `backend/app/modules/treatments/domain/value_objects/dosage_schedule.py`
- Create: `backend/app/modules/treatments/domain/models/treatment_regimen.py`
- Create: `backend/app/modules/treatments/domain/services/adherence_and_missed_dose_service.py`
- Create: `backend/app/modules/treatments/application/ports/treatment_repository_port.py`
- Create: `backend/app/modules/treatments/application/use_cases/manage_treatments_use_cases.py`
- Test: `backend/tests/unit/treatments/test_treatment_schedules_and_adherence.py`

**Interfaces:**
- Consumes: `DomainError`
- Produces:
  - `TreatmentCategory` (`CONTRACEPTIVE_ORAL_COMBINED`, `CONTRACEPTIVE_PROGESTIN_ONLY`, `PATCH`, `INJECTABLE`, `LARC_IUD_IMPLANT`, `HRT`, `SUPPLEMENT`, `CHRONIC_MEDICATION`)
  - `DosageSchedule` (`daily_fixed`, `cyclic_active_break` ej. `21/7` y `24/4`, `interval_days`, `long_acting_replacement_date`)
  - `AdherenceAndMissedDoseService.evaluate_intake(...) -> AdherenceAssessment`
  - `ITreatmentRepository` (reutilizado en Fase 9 para *Doctor-Ready PDF* y Fase 10 para contexto RAG)

- [x] **Step 1: Escribir tests TDD parametrizados cubriendo esquemas `21/7`, `24/4`, toma diaria de ácido fólico/hierro, recordatorio de recambio de DIU/implante (90 y 30 días antes de vencimiento) y detección de retraso crítico (`> 12h` minipíldora vs `>= 24h` combinada)**
- [x] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/unit/treatments/test_treatment_schedules_and_adherence.py -v`
  - Expected: FAIL
- [x] **Step 3: Implementar modelos, `DosageSchedule`, `AdherenceAndMissedDoseService`, puerto y casos de uso**
- [x] **Step 4: Verificar tests unitarios y tipado**
  - Run: `ruff check backend && mypy --strict backend/app && pytest backend/tests/unit/treatments -v`
  - Expected: PASS
- [x] **Step 5: Commit**
  - `git add backend/app/modules/treatments backend/tests/unit/treatments`
  - `git commit -m "feat(treatments): implement dosage schedules, LARC replacement alerts, and adherence engine"`

---

### Task 3: Persistencia PostgreSQL, Endpoints Batch Sync y Actualización de Contrato OpenAPI

**Files:**
- Create: `backend/alembic/versions/0003_create_wellness_and_treatments_tables.py`
- Create: `backend/app/modules/clinical_tracking/infrastructure/orm/wellness_orm.py`
- Create: `backend/app/modules/clinical_tracking/infrastructure/adapters/postgres_wellness_repository.py`
- Create: `backend/app/modules/clinical_tracking/infrastructure/entrypoints/wellness_router.py`
- Create: `backend/app/modules/treatments/infrastructure/orm/treatment_orm.py`
- Create: `backend/app/modules/treatments/infrastructure/adapters/postgres_treatment_repository.py`
- Create: `backend/app/modules/treatments/infrastructure/entrypoints/treatment_router.py`
- Modify: `backend/app/main.py`
- Modify: `contracts/openapi.json`
- Test: `backend/tests/integration/treatments/test_wellness_and_treatments_api.py`

**Interfaces:**
- Consumes: Casos de uso de Tasks 1 y 2, `CurrentUserDep`, `IdempotencyService`
- Produces:
  - `PUT /api/v1/wellness/logs/{log_date}`, `GET /api/v1/wellness/logs`
  - `POST /api/v1/treatments/regimens`, `GET /api/v1/treatments/regimens`, `POST /api/v1/treatments/intakes`, `GET /api/v1/treatments/adherence-summary`

- [x] **Step 1: Escribir tests de integración HTTP verificando upsert parcial por fecha, creación de tratamiento `21/7`, registro idempotente de tomas con `X-Client-Mutation-Id` repetido y resumen de adherencia**
- [x] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/integration/treatments/test_wellness_and_treatments_api.py -v`
  - Expected: FAIL
- [x] **Step 3: Implementar migración Alembic `0003`, modelos ORM, repositorios Postgres, routers FastAPI y exportar `contracts/openapi.json`**
- [x] **Step 4: Ejecutar suite completa backend (unit + integration + contract)**
  - Run: `python backend/scripts/export_openapi.py && pytest backend/tests -v`
  - Expected: PASS
- [x] **Step 5: Commit**
  - `git add backend/alembic/versions/0003_create_wellness_and_treatments_tables.py backend/app/modules/clinical_tracking/infrastructure backend/app/modules/treatments/infrastructure backend/app/main.py contracts/openapi.json backend/tests/integration/treatments`
  - `git commit -m "feat(backend): add wellness and treatments persistence, idempotent APIs, and OpenAPI schemas"`

---

### Task 4: Experiencia Móvil *Offline-First* — Tracker de Bienestar, Pastillero Virtual y Notificaciones Enmascaradas

**Files:**
- Create: `mobile/lib/core/notifications/discreet_notification_service.dart`
- Create: `mobile/lib/features/wellness/domain/entities/daily_wellness_entity.dart`
- Create: `mobile/lib/features/wellness/data/wellness_repository_impl.dart`
- Create: `mobile/lib/features/wellness/presentation/pages/wellness_tracker_page.dart`
- Create: `mobile/lib/features/treatments/domain/entities/treatment_entities.dart`
- Create: `mobile/lib/features/treatments/data/treatments_repository_impl.dart`
- Create: `mobile/lib/features/treatments/presentation/pages/pillbox_and_treatments_page.dart`
- Modify: `mobile/lib/core/database/app_database.dart`
- Modify: `mobile/lib/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart`
- Test: `mobile/test/features/wellness/offline_wellness_merge_test.dart`
- Test: `mobile/test/features/treatments/pillbox_and_discreet_notification_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `SyncCoordinator`, `activeUserProfileProvider`
- Produces:
  - `DiscreetNotificationService` (reutilizable por citas médicas y Modo Discreto en Fase 11)
  - Widgets de acceso rápido en `DynamicHomeDashboardPage` para hidratación/ánimo y toma del día

- [x] **Step 1: Escribir tests en Flutter verificando: consolidación offline de dos ediciones parciales del mismo día en Drift, texto enmascarado por defecto en `DiscreetNotificationService` y marcado instantáneo de dosis tomada sin red**
- [x] **Step 2: Ejecutar `flutter test` y confirmar fallo**
  - Run: `cd mobile && flutter test test/features/wellness test/features/treatments`
  - Expected: FAIL
- [x] **Step 3: Implementar tablas Drift (`daily_wellness_logs`, `treatment_regimens`, `dose_intake_logs`), `DiscreetNotificationService`, repositorios con `SyncCoordinator` y pantallas UI en Riverpod conectadas al *Home Dashboard***
- [x] **Step 4: Ejecutar `build_runner`, `flutter analyze` y `flutter test`**
  - Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-infos && flutter test`
  - Expected: PASS
- [x] **Step 5: Commits finales y actualización de Fase 03**
  - `git add mobile`
  - `git commit -m "feat(mobile-ui): add offline-first wellness tracker, virtual pillbox, and discreet reminders"`
  - `git add docs/phases/phase-03-wellness-and-treatments.md docs/phases/README.md`
  - `git commit -m "docs(plan): mark phase 03 tasks completed"`
