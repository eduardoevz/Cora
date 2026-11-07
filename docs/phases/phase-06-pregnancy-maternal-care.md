# Fase 06 — Etapa 4: Embarazo y Seguimiento Materno-Fetal (`maternal_care`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Crear el módulo hexagonal `maternal_care` para acompañar el **Embarazo** semana a semana (`4–42` semanas): hitos anatómicos fetales, monitor materno de presión arterial, curva de peso y glucosa con detección preventiva **ACOG** (preeclampsia y diabetes gestacional), contador de contracciones, monitor de patadas y plan de parto con agenda prenatal.

**Architecture:** `maternal_care` constituye un contexto acotado independiente de `clinical_tracking` para mantener separadas las reglas obstétricas de las reglas menstruales. El agregado `PregnancyEpisode` calcula la edad gestacional (`weeks + days`) por fecha de última menstruación (FUM) o ecografía del primer trimestre, mientras `MaternalRiskEvaluator` aplica criterios deterministas ACOG.

**Tech Stack:** Python 3.12+, FastAPI, SQLAlchemy 2.0 Async, Flutter, Riverpod, Drift, cronómetros locales persistentes para contracciones y movimientos fetales.

**Spec:** `docs/SPECS.MD` (Sección 3.2 Etapa 4: Embarazo), `docs/desarrollo.md` (Secciones 3.2 y 3.3), `.agents/rules/03-clinical-tdd-and-safety.md`

## Global Constraints

- `BloodPressure(systolic_mmhg: int, diastolic_mmhg: int)` valida invariante estricta `systolic_mmhg > diastolic_mmhg`, `systolic` en `60–260` y `diastolic` en `30–160`.
- Reglas preventivas **ACOG** obligatorias en `MaternalRiskEvaluator`:
  - `systolic >= 160` o `diastolic >= 110`, o `>= 140/90` acompañada de síntomas neurológicos/visuales/epigastralgia -> **Urgencia obstétrica inmediata (`URGENT_EMERGENCY`)**.
  - `140 <= systolic < 160` o `90 <= diastolic < 110` sin síntomas de severidad -> **Alerta prioritaria de valoración obstétrica (`PRIORITY_CONSULT`)** sugiriendo repetir toma en reposo y contactar a su obstetra.
  - Glucemia capilar gestacional fuera de meta orientativa (`ayunas >= 95 mg/dL`, `1h posprandial >= 140 mg/dL`, `2h posprandial >= 120 mg/dL`) repetida -> **Sugerencia preventiva de revisión metabólica / descarte de diabetes gestacional**.
- El contador de contracciones evalúa el patrón orientativo `5-1-1` (contracciones cada `<= 5` min, de `>= 60` s de duración, sostenidas durante `>= 1` h en embarazo a término `>= 37` semanas; si es `< 37` semanas, alerta precoz ante contracciones regulares por riesgo de amenaza de parto pretérmino).

## Review Focus

1. **Contracciones regulares antes de la semana 37 vs a término:** El umbral de aviso en `< 37` semanas debe ser mucho más sensible (`>= 4` contracciones en `20` min o `>= 8` en `60` min) que la regla `5-1-1` a término.
2. **Disminución de movimientos fetales en tercer trimestre (`>= 28` semanas):** Si la sesión del monitor de patadas no alcanza `10` movimientos en `120` minutos, emitir directiva clara de acudir a valoración fetal sin esperar al día siguiente.
3. **Recalibración de fecha probable de parto (FPP) por ecografía:** Si el especialista ajusta la FPP por biometría del primer trimestre, el episodio actualiza la edad gestacional conservando trazabilidad de la FUM original.
4. **Persistencia de cronómetro de contracciones si el sistema operativo cierra la app:** Guardar `started_at` UTC en Drift para que al reabrir la app el cronómetro siga exacto sin perder la contracción en curso.
5. **Invariante `BloodPressure` invertida en entrada rápida del usuario (`80/120`):** Rechazar con mensaje claro pidiendo verificar el orden Sistólica / Diastólica.

---

### Task 1: Dominio Obstétrico — `PregnancyEpisode`, `BloodPressure`, `MaternalRiskEvaluator` (ACOG), Contracciones y Patadas (TDD)

**Files:**
- Create: `backend/app/modules/maternal_care/domain/value_objects/maternal_vitals.py`
- Create: `backend/app/modules/maternal_care/domain/models/pregnancy_episode.py`
- Create: `backend/app/modules/maternal_care/domain/services/maternal_risk_evaluator.py`
- Create: `backend/app/modules/maternal_care/domain/services/contraction_and_kick_analyzer.py`
- Create: `backend/app/modules/maternal_care/domain/services/fetal_weekly_milestones_catalog.py`
- Test: `backend/tests/unit/maternal_care/test_acog_maternal_risk_evaluator.py`
- Test: `backend/tests/unit/maternal_care/test_contractions_and_kicks.py`

**Interfaces:**
- Consumes: `DomainError`
- Produces:
  - `BloodPressure`, `CapillaryGlucoseReading`, `GestationalAge(weeks: int, days: int)`
  - `PregnancyEpisode`, `BirthPlanPreference`, `PrenatalAppointment`
  - `MaternalRiskEvaluator.evaluate_vitals(...) -> list[MaternalClinicalAlert]`
  - `ContractionAndKickAnalyzer`

- [ ] **Step 1: Escribir tests TDD parametrizados cubriendo: invariantes de `BloodPressure`, umbrales ACOG (`138/88` normal, `142/92` consulta prioritaria, `145/95` + escotomas urgencia inmediata, `162/112` urgencia inmediata), glucemia en ayunas/posprandial, regla `5-1-1` (`>= 37w`) vs pretérmino (`< 37w`) y conteo Cardiff de patadas (`< 10` en `2h`)**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/unit/maternal_care -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar los Value Objects, `PregnancyEpisode`, catálogo de hitos fetales (`4–42` semanas), `MaternalRiskEvaluator` y `ContractionAndKickAnalyzer`**
- [ ] **Step 4: Verificar pase en `< 50 ms` y `mypy --strict`**
  - Run: `mypy --strict backend/app && pytest backend/tests/unit/maternal_care -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/app/modules/maternal_care/domain backend/tests/unit/maternal_care`
  - `git commit -m "feat(maternal-care): implement ACOG preeclampsia/GDM risk evaluator, contractions, and fetal tracking domain"`

---

### Task 2: Casos de Uso, Persistencia PostgreSQL y API REST de Embarazo

**Files:**
- Create: `backend/alembic/versions/0006_create_pregnancy_maternal_care_tables.py`
- Create: `backend/app/modules/maternal_care/application/ports/pregnancy_repository_port.py`
- Create: `backend/app/modules/maternal_care/application/use_cases/pregnancy_use_cases.py`
- Create: `backend/app/modules/maternal_care/infrastructure/orm/pregnancy_orm.py`
- Create: `backend/app/modules/maternal_care/infrastructure/adapters/postgres_pregnancy_repository.py`
- Create: `backend/app/modules/maternal_care/infrastructure/entrypoints/pregnancy_router.py`
- Modify: `backend/app/main.py`
- Modify: `contracts/openapi.json`
- Test: `backend/tests/integration/maternal_care/test_pregnancy_api.py`

**Interfaces:**
- Consumes: `IUserProfileRepository` (sincronizando transición a `PREGNANCY` si aplica), modelos de Task 1
- Produces:
  - `IPregnancyRepository` (reutilizado en Fase 7 para transición a posparto, Fase 9 PDF y Fase 11 *Partner View*)
  - `POST /api/v1/pregnancy/episodes`, `GET /api/v1/pregnancy/active`, `POST /api/v1/pregnancy/vitals`, `POST /api/v1/pregnancy/contractions/sessions`, `POST /api/v1/pregnancy/kick-sessions`, `PUT /api/v1/pregnancy/birth-plan`

- [ ] **Step 1: Escribir tests de integración HTTP probando alta de embarazo, consulta de hito fetal semanal, disparo de alerta urgente ante PA `165/110`, guardado de sesión de patadas y plan de parto**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/integration/maternal_care/test_pregnancy_api.py -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar migración `0006`, ORM, repositorio Postgres, casos de uso, router y actualizar `contracts/openapi.json`**
- [ ] **Step 4: Verificar suite completa backend**
  - Run: `python backend/scripts/export_openapi.py && pytest backend/tests -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/alembic/versions/0006_create_pregnancy_maternal_care_tables.py backend/app/modules/maternal_care backend/app/main.py contracts/openapi.json backend/tests/integration/maternal_care/test_pregnancy_api.py`
  - `git commit -m "feat(maternal-care): add pregnancy persistence, ACOG vitals API, and birth plan endpoints"`

---

### Task 3: Módulo Móvil Flutter de Embarazo — Semana a Semana, Monitor Materno, Cronómetro de Contracciones y Contador de Patadas

**Files:**
- Create: `mobile/lib/features/pregnancy/domain/entities/pregnancy_entities.dart`
- Create: `mobile/lib/features/pregnancy/data/pregnancy_repository_impl.dart`
- Create: `mobile/lib/features/pregnancy/presentation/pages/pregnancy_weekly_hub_page.dart`
- Create: `mobile/lib/features/pregnancy/presentation/pages/maternal_vitals_page.dart`
- Create: `mobile/lib/features/pregnancy/presentation/pages/contraction_and_kick_timers_page.dart`
- Create: `mobile/lib/features/pregnancy/presentation/pages/birth_plan_and_appointments_page.dart`
- Modify: `mobile/lib/core/database/app_database.dart`
- Modify: `mobile/lib/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart`
- Test: `mobile/test/features/pregnancy/maternal_vitals_and_timers_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `SyncCoordinator`, `activeUserProfileProvider`
- Produces: Flujo móvil completo *Offline-First* de Etapa 4

- [ ] **Step 1: Escribir tests en Flutter verificando: alerta inmediata offline si la usuaria ingresa `160/110` sin esperar al servidor, restauración exacta de una contracción en curso desde `started_at` en Drift, y plan de parto editable offline**
- [ ] **Step 2: Ejecutar `flutter test` y confirmar fallo**
  - Run: `cd mobile && flutter test test/features/pregnancy`
  - Expected: FAIL
- [ ] **Step 3: Implementar tablas Drift de gestación, evaluación local espejo de signos de alarma obstétrica, cronómetros resilientes y pantallas de embarazo integradas al *Home Dashboard***
- [ ] **Step 4: Ejecutar `build_runner`, `flutter analyze` y `flutter test`**
  - Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-infos && flutter test`
  - Expected: PASS
- [ ] **Step 5: Commits finales y cierre de Fase 06**
  - `git add mobile`
  - `git commit -m "feat(mobile-ui): build weekly fetal tracker, offline ACOG vitals alerts, and contraction/kick timers"`
  - `git add docs/phases/phase-06-pregnancy-maternal-care.md docs/phases/README.md`
  - `git commit -m "docs(plan): mark phase 06 tasks completed"`
