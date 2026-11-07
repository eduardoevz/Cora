# Fase 04 — Salud Cíclica: Etapas 1 y 2 (Adolescencia, Edad Reproductiva y Motor FIGO) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar en `clinical_tracking` el motor predictivo y descriptivo de 4 fases hormonales para **Juventud y Edad Reproductiva**, la calibración especial para **Adolescencia** (con PIN independiente y tolerancia posmenarquia), las herramientas para **SOP y Endometriosis**, y el **Detector Preventivo de Patrones Atípicos (FIGO)**.

**Architecture:** En `backend/app/modules/clinical_tracking/`, `MenstrualCycle` y `CyclePredictionEngine` calculan fases (`MENSTRUAL`, `FOLLICULAR`, `OVULATORY`, `LUTEAL`) ponderando el contexto clínico de `identity` (`LifeStage`, método hormonal activo y condiciones diagnosticadas). `FigoPatternDetector` evalúa series longitudinales sin generar falsas alarmas ante variabilidad fisiológica adolescente o amenorrea inducida por DIU hormonal/implante.

**Tech Stack:** Python 3.12+, FastAPI, SQLAlchemy 2.0 Async, Flutter, Riverpod, Drift, `flutter_secure_storage` (PIN adolescente), gráficas `CustomPainter` / `fl_chart`.

**Spec:** `docs/SPECS.MD` (Sección 3.2 Etapas 1 y 2; Sección 4 Detección Preventiva de Patrones Atípicos), `.agents/rules/03-clinical-tdd-and-safety.md`

## Global Constraints

- Criterios FIGO adultos estándar: ciclo normal `24–38` días, polimenorrea `< 24` días, oligomenorrea `> 38` días, duración normal `<= 8` días, variación normal `< 7–9` días según edad.
- En etapa `adolescence` (especialmente en los primeros `1–3` años desde `menarche_date`), el rango fisiológico aceptado se amplía a `21–45` días antes de sugerir valoración por irregularidad, manteniendo alerta si el sangrado supera `8` días o es hemodinámicamente abundante.
- Si la usuaria utiliza anticoncepción hormonal continua, implante subdérmico o DIU hormonal, el motor **desactiva predicciones de ovulación natural** y adapta los mensajes de sangrado por deprivación o *spotting* esperado.
- El **PIN de Modo Privacidad Segura** en Adolescencia se almacena como hash con sal en `flutter_secure_storage`, nunca en texto plano ni sincronizado sin cifrar.

## Review Focus

1. **Falsas alarmas FIGO en usuarias con SOP, DIU hormonal o menarquia reciente:** El detector debe recibir explícitamente `PatientCycleContext(life_stage, hormonal_method, conditions, years_since_menarche)`.
2. **Distinción entre *spotting* intermenstrual aislado y inicio real de nuevo ciclo:** Solo el flujo menstrual (`LIGHT`, `MEDIUM`, `HEAVY`) inicia un nuevo `MenstrualCycle`; el manchado aislado (`SPOTTING`) en fase lútea/ovulatoria se registra dentro del ciclo vigente y alimenta la evaluación de sangrado intermenstrual.
3. **Dolor pélvico incapacitante recurrente (sospecha preventiva de endometriosis / dismenorrea secundaria):** Si `pelvic_pain_score >= 7/10` con interferencia en actividades diarias se repite en `>= 2` ciclos, emitir alerta preventiva empática sugiriendo consulta ginecológica.
4. **Primer ciclo (*Mi Primer Periodo*) sin historial previo:** El motor debe funcionar con `0` o `1` ciclo registrado ofreciendo rangos orientativos educativos sin errores de división por cero.
5. **Bloqueo por PIN independiente en Adolescencia:** Tras `5` intentos fallidos de PIN rápido, aplicar enfriamiento temporal local (`30s`) sin borrar los datos locales.

---

### Task 1: Motor de Dominio `MenstrualCycle`, 4 Fases Hormonales y Adaptación Adolescencia/SOP/Anticoncepción (TDD)

**Files:**
- Create: `backend/app/modules/clinical_tracking/domain/value_objects/bleeding_and_symptoms.py`
- Create: `backend/app/modules/clinical_tracking/domain/models/menstrual_cycle.py`
- Create: `backend/app/modules/clinical_tracking/domain/services/cycle_phase_and_prediction_service.py`
- Test: `backend/tests/unit/clinical_tracking/test_cycle_phases_and_predictions.py`

**Interfaces:**
- Consumes: `LifeStage`, `HormonalMethod`, `DiagnosedCondition` (`identity` value objects)
- Produces:
  - `CyclePhase(StrEnum)` (`MENSTRUAL`, `FOLLICULAR`, `OVULATORY`, `LUTEAL`, `HORMONALLY_MANAGED`)
  - `MenstrualCycle`, `CycleSymptomLog` (acné, dismenorrea `0–10`, dolor pélvico crónico, dispareunia, síntomas GI/fatiga para SOP/Endometriosis)
  - `CyclePhaseAndPredictionService.compute_status(cycles: list[MenstrualCycle], context: PatientCycleContext, reference_date: date) -> CycleStatusSnapshot`

- [ ] **Step 1: Escribir batería parametrizada de tests unitarios: usuaria regular de `28` días (4 fases exactas), adolescente con `0` y `2` ciclos irregulares (`39` días sin falsa patología), usuaria con pastillas combinadas (`HORMONALLY_MANAGED`) y usuaria con SOP (`42` días con ventana de incertidumbre ampliada)**
- [ ] **Step 2: Ejecutar pytest y verificar fallo**
  - Run: `pytest backend/tests/unit/clinical_tracking/test_cycle_phases_and_predictions.py -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar `MenstrualCycle`, `BleedingIntensity`, `CycleSymptomLog` y `CyclePhaseAndPredictionService`**
- [ ] **Step 4: Verificar pase en `< 50 ms` y `mypy --strict`**
  - Run: `mypy --strict backend/app && pytest backend/tests/unit/clinical_tracking/test_cycle_phases_and_predictions.py -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/app/modules/clinical_tracking/domain backend/tests/unit/clinical_tracking/test_cycle_phases_and_predictions.py`
  - `git commit -m "feat(clinical-tracking): implement 4-phase cycle engine adapted for adolescence, PCOS, and contraceptives"`

---

### Task 2: Detector Preventivo de Patrones Atípicos Basado en Criterios FIGO (TDD)

**Files:**
- Create: `backend/app/modules/clinical_tracking/domain/services/figo_atypical_pattern_detector.py`
- Test: `backend/tests/unit/clinical_tracking/test_figo_atypical_pattern_detector.py`

**Interfaces:**
- Consumes: `MenstrualCycle`, `CycleSymptomLog`, `PatientCycleContext`
- Produces:
  - `ClinicalPatternAlert` (`code`, `severity: INFO | PREVENTIVE_CONSULT | URGENT`, `title_es`, `empathetic_summary_es`, `clinical_rationale`)
  - `FigoAtypicalPatternDetector.analyze(cycles: list[MenstrualCycle], logs: list[CycleSymptomLog], context: PatientCycleContext) -> list[ClinicalPatternAlert]`

- [ ] **Step 1: Escribir tests unitarios parametrizados para polimenorrea (`< 24d`), oligomenorrea (`> 38d` en adulta vs tolerancia `<= 45d` en adolescente), sangrado prolongado (`> 8d`), sangrado intermenstrual repetido y dolor pélvico incapacitante recurrente, validando que el lenguaje generado sea no alarmista**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/unit/clinical_tracking/test_figo_atypical_pattern_detector.py -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar `FigoAtypicalPatternDetector`**
- [ ] **Step 4: Ejecutar tests unitarios y linter**
  - Run: `ruff check backend && mypy --strict backend/app && pytest backend/tests/unit/clinical_tracking -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/app/modules/clinical_tracking/domain/services/figo_atypical_pattern_detector.py backend/tests/unit/clinical_tracking/test_figo_atypical_pattern_detector.py`
  - `git commit -m "feat(clinical-tracking): add FIGO atypical bleeding and pelvic pain detector with TDD"`

---

### Task 3: Casos de Uso, Persistencia PostgreSQL y Endpoints REST de Ciclos y Síntomas

**Files:**
- Create: `backend/alembic/versions/0004_create_menstrual_cycles_and_symptoms.py`
- Create: `backend/app/modules/clinical_tracking/application/ports/cycle_repository_port.py`
- Create: `backend/app/modules/clinical_tracking/application/use_cases/log_bleeding_and_symptoms_use_case.py`
- Create: `backend/app/modules/clinical_tracking/application/use_cases/get_cycle_overview_use_case.py`
- Create: `backend/app/modules/clinical_tracking/infrastructure/orm/cycle_orm.py`
- Create: `backend/app/modules/clinical_tracking/infrastructure/adapters/postgres_cycle_repository.py`
- Create: `backend/app/modules/clinical_tracking/infrastructure/entrypoints/cycle_router.py`
- Modify: `backend/app/main.py`
- Modify: `contracts/openapi.json`
- Test: `backend/tests/integration/clinical_tracking/test_cycle_api.py`

**Interfaces:**
- Consumes: `IUserProfileRepository` (Fase 2), motores de Tasks 1 y 2
- Produces:
  - `ICycleRepository` (reutilizado en Fases 5, 9 y 10)
  - `POST /api/v1/cycles/bleeding-events`, `PUT /api/v1/cycles/symptom-logs/{log_date}`, `GET /api/v1/cycles/overview`

- [ ] **Step 1: Escribir tests de integración HTTP probando apertura automática de nuevo ciclo ante sangrado menstrual, conservación de ciclo ante *spotting* aislado y generación de alertas FIGO en `GET /api/v1/cycles/overview`**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/integration/clinical_tracking/test_cycle_api.py -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar migración `0004`, ORM, repositorio, casos de uso, router y actualizar `contracts/openapi.json`**
- [ ] **Step 4: Verificar toda la suite backend**
  - Run: `python backend/scripts/export_openapi.py && pytest backend/tests -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/alembic/versions/0004_create_menstrual_cycles_and_symptoms.py backend/app/modules/clinical_tracking backend/app/main.py contracts/openapi.json backend/tests/integration/clinical_tracking`
  - `git commit -m "feat(clinical-tracking): expose cycle tracking, symptom logs, and FIGO alerts REST API"`

---

### Task 4: Módulos Móviles Flutter — Rueda de 4 Fases, Panel SOP/Endometriosis, "Mi Primer Periodo" y PIN Adolescente

**Files:**
- Create: `mobile/lib/features/cycle/domain/entities/cycle_overview_entity.dart`
- Create: `mobile/lib/features/cycle/data/cycle_repository_impl.dart`
- Create: `mobile/lib/features/cycle/presentation/pages/cycle_monitor_page.dart`
- Create: `mobile/lib/features/cycle/presentation/pages/chronic_conditions_tracker_page.dart`
- Create: `mobile/lib/features/adolescence/presentation/pages/first_period_and_body_guide_page.dart`
- Create: `mobile/lib/features/adolescence/presentation/widgets/teen_privacy_pin_gate.dart`
- Modify: `mobile/lib/core/database/app_database.dart`
- Modify: `mobile/lib/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart`
- Test: `mobile/test/features/cycle/cycle_monitor_and_alerts_test.dart`
- Test: `mobile/test/features/adolescence/teen_privacy_pin_gate_test.dart`

**Interfaces:**
- Consumes: `activeUserProfileProvider`, `AppDatabase`, `SyncCoordinator`
- Produces: Experiencia móvil completa para Etapas 1 y 2 integrada al *Home Dashboard*

- [ ] **Step 1: Escribir tests en Flutter verificando: renderizado diferencial entre etapa `adolescence` ("Mi Primer Periodo" + bloqueo `TeenPrivacyPinGate` con enfriamiento tras 5 fallos) y `regular_adult` (4 fases + tarjetas SOP/Endometriosis + banners preventivos FIGO)**
- [ ] **Step 2: Ejecutar `flutter test` y verificar fallo**
  - Run: `cd mobile && flutter test test/features/cycle test/features/adolescence`
  - Expected: FAIL
- [ ] **Step 3: Implementar tablas Drift de ciclos/síntomas, cálculo local *Offline-First* espejo para respuesta inmediata sin red, gráficas de fases y pantallas de Adolescencia y Condiciones Crónicas**
- [ ] **Step 4: Ejecutar `build_runner`, `flutter analyze` y `flutter test`**
  - Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-infos && flutter test`
  - Expected: PASS
- [ ] **Step 5: Commits finales y cierre de Fase 04**
  - `git add mobile`
  - `git commit -m "feat(mobile-ui): add 4-phase cycle wheel, PCOS/endometriosis tracker, and teen PIN mode"`
  - `git add docs/phases/phase-04-cycle-reproductive-adolescence.md docs/phases/README.md`
  - `git commit -m "docs(plan): mark phase 04 tasks completed"`
