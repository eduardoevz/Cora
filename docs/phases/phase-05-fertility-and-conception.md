# Fase 05 — Etapa 3: Búsqueda de Concepción y Fertilidad Avanzada Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir el subdominio de **Fertilidad y Búsqueda de Concepción** dentro de `clinical_tracking` y su interfaz gráfica interactiva en Flutter: registro biomédico de temperatura basal (`BasalBodyTemperature`), moco cervical, pruebas de LH, algoritmo sintotérmico de ventana fértil, checklist preconcepcional y consolidación clínica para especialistas en fertilidad.

**Architecture:** Se amplía `clinical_tracking` con Value Objects biométricos validados (`BasalBodyTemperature`, `CervicalMucusObservation`, `LhTestResult`) y el servicio determinista `SymptothermalFertilityService`, que cruza el historial menstrual (Fase 4) con biomarcadores diarios para distinguir ventana fértil prospectiva de ovulación retrospectivamente confirmada.

**Tech Stack:** Python 3.12+, FastAPI, SQLAlchemy 2.0 Async, Flutter, Riverpod, Drift, gráficas térmicas bifásicas interactivas.

**Spec:** `docs/SPECS.MD` (Sección 3.2 Etapa 3: Búsqueda de Concepción), `docs/desarrollo.md` (Sección 3.2 y 3.3)

## Global Constraints

- `BasalBodyTemperature` exige dos decimales de precisión y rango fisiológico estricto `35.00 °C – 42.00 °C`; mediciones marcadas con fiebre, privación severa de sueño (`< 3h`) o consumo de alcohol se etiquetan como `disturbed = True` y se excluyen del cálculo automático de salto térmico.
- La confirmación retrospectiva de ovulación requiere regla sintotérmica (`3` temperaturas válidas consecutivas al menos `0.20 °C` la tercera por encima de la línea base de las `6` previas, reforzada por pico de moco fértil o LH positivo).
- Orientación preventiva de fertilidad por edad cronológica: sugerir valoración especializada preconcepcional/fertilidad tras `12` meses de búsqueda activa en `< 35` años o `6` meses en `>= 35` años (en tono empático e informativo).

## Review Focus

1. **Fiebre confundida con ovulación:** Una temperatura de `38.10 °C` o marcada con `disturbed = True` nunca debe disparar confirmación falsa de fase lútea.
2. **Ciclos con múltiples picos de LH en SOP:** En usuarias con SOP (Capa 3), un test de LH positivo sugiere ventana fértil tentativa pero solo el salto sostenido de `BasalBodyTemperature` confirma que la ovulación ocurrió.
3. **Unidades Celsius vs Fahrenheit en entrada móvil:** El backend almacena canónicamente grados Celsius (`Decimal(4,2)`) y ofrece conversión exacta sin pérdida de redondeo si el cliente muestra `°F`.
4. **Checklist preconcepcional interactivo:** Verificar adherencia a suplementación de ácido fólico (`>= 400 mcg`) conectando con el puerto `ITreatmentRepository` de Fase 3 si ya existe régimen activo.
5. **Gráfica térmica con huecos de días no registrados:** La curva en Flutter debe dibujar segmentos discontinuos en días faltantes sin interpolar temperaturas ficticias.

---

### Task 1: Value Objects Biomédicos y Algoritmo Sintotérmico `SymptothermalFertilityService` (TDD)

**Files:**
- Create: `backend/app/modules/clinical_tracking/domain/value_objects/fertility_biomarkers.py`
- Create: `backend/app/modules/clinical_tracking/domain/models/preconception_checklist.py`
- Create: `backend/app/modules/clinical_tracking/domain/services/symptothermal_fertility_service.py`
- Test: `backend/tests/unit/clinical_tracking/test_symptothermal_fertility_service.py`

**Interfaces:**
- Consumes: `MenstrualCycle`, `PatientCycleContext` (Fase 4)
- Produces:
  - `BasalBodyTemperature(celsius: Decimal, measured_at_time: time, disturbed: bool)`
  - `CervicalMucusType` (`DRY`, `STICKY`, `CREAMY`, `WATERY`, `EGG_WHITE`)
  - `LhStripResult` (`NEGATIVE`, `HIGH`, `PEAK`)
  - `FertilityWindowAssessment` (`status: LOW | HIGH | PEAK_FERTILITY | OVULATION_CONFIRMED`, `coverline_celsius: Decimal | None`, `estimated_ovulation_date: date | None`)

- [ ] **Step 1: Escribir tests TDD parametrizados: validación de rangos `35.00–42.00 °C`, detección exacta de línea base (*coverline*) y regla `3 sobre 6`, exclusión de mediciones con `disturbed=True`, caso de doble pico LH en SOP sin ascenso térmico, y recomendación por tiempo de búsqueda según edad (`< 35` vs `>= 35`)**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/unit/clinical_tracking/test_symptothermal_fertility_service.py -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar `fertility_biomarkers.py`, `preconception_checklist.py` y `SymptothermalFertilityService`**
- [ ] **Step 4: Verificar pase en `< 50 ms` y `mypy --strict`**
  - Run: `mypy --strict backend/app && pytest backend/tests/unit/clinical_tracking/test_symptothermal_fertility_service.py -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/app/modules/clinical_tracking/domain backend/tests/unit/clinical_tracking/test_symptothermal_fertility_service.py`
  - `git commit -m "feat(clinical-tracking): implement BBT value object and symptothermal fertility engine with TDD"`

---

### Task 2: Persistencia, Casos de Uso, Consolidado para Especialista y Endpoints REST de Fertilidad

**Files:**
- Create: `backend/alembic/versions/0005_create_fertility_logs_and_preconception.py`
- Create: `backend/app/modules/clinical_tracking/application/ports/fertility_repository_port.py`
- Create: `backend/app/modules/clinical_tracking/application/use_cases/fertility_tracking_use_cases.py`
- Create: `backend/app/modules/clinical_tracking/infrastructure/orm/fertility_orm.py`
- Create: `backend/app/modules/clinical_tracking/infrastructure/adapters/postgres_fertility_repository.py`
- Create: `backend/app/modules/clinical_tracking/infrastructure/entrypoints/fertility_router.py`
- Modify: `backend/app/main.py`
- Modify: `contracts/openapi.json`
- Test: `backend/tests/integration/clinical_tracking/test_fertility_api.py`

**Interfaces:**
- Consumes: `ICycleRepository`, `IUserProfileRepository`, `ITreatmentRepository`
- Produces:
  - `IFertilityRepository` (reutilizado en Fase 9 para *Doctor-Ready PDF* y Fase 11 para compartir ventana fértil en *Partner View*)
  - `PUT /api/v1/fertility/logs/{log_date}`, `GET /api/v1/fertility/chart`, `GET /api/v1/fertility/preconception-checklist`, `PATCH /api/v1/fertility/preconception-checklist`

- [ ] **Step 1: Escribir tests de integración verificando ingesta de curva de 16 días de TBC + LH + moco, respuesta de `coverline_celsius` en `/api/v1/fertility/chart` y actualización del checklist preconcepcional**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/integration/clinical_tracking/test_fertility_api.py -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar migración `0005`, ORM, repositorio, casos de uso, router y actualizar `contracts/openapi.json`**
- [ ] **Step 4: Verificar toda la suite backend**
  - Run: `python backend/scripts/export_openapi.py && pytest backend/tests -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/alembic/versions/0005_create_fertility_logs_and_preconception.py backend/app/modules/clinical_tracking backend/app/main.py contracts/openapi.json backend/tests/integration/clinical_tracking/test_fertility_api.py`
  - `git commit -m "feat(clinical-tracking): add fertility biomarkers persistence, chart API, and preconception endpoints"`

---

### Task 3: Interfaz Móvil Flutter — Curva Térmica Bifásica Interactiva, Registro LH/Moco y Checklist Preconcepcional

**Files:**
- Create: `mobile/lib/features/fertility/domain/entities/fertility_chart_entity.dart`
- Create: `mobile/lib/features/fertility/data/fertility_repository_impl.dart`
- Create: `mobile/lib/features/fertility/presentation/widgets/bbt_biphasic_chart_widget.dart`
- Create: `mobile/lib/features/fertility/presentation/pages/conception_hub_page.dart`
- Create: `mobile/lib/features/fertility/presentation/pages/preconception_checklist_page.dart`
- Modify: `mobile/lib/core/database/app_database.dart`
- Modify: `mobile/lib/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart`
- Test: `mobile/test/features/fertility/bbt_chart_and_conception_hub_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `SyncCoordinator`, `activeUserProfileProvider`
- Produces: Módulo móvil completo de Etapa 3 activado en `conception_search`

- [ ] **Step 1: Escribir widget/unit tests verificando validación local `35.00–42.00 °C`, renderizado de huecos discontinuos en `BbtBiphasicChartWidget`, línea *coverline* y guardado *Offline-First* de LH + moco cervical**
- [ ] **Step 2: Ejecutar `flutter test` y confirmar fallo**
  - Run: `cd mobile && flutter test test/features/fertility`
  - Expected: FAIL
- [ ] **Step 3: Implementar tablas Drift de fertilidad, repositorio *Offline-First*, gráfica interactiva accesible y pantallas de concepción/checklist**
- [ ] **Step 4: Ejecutar `build_runner`, `flutter analyze` y `flutter test`**
  - Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-infos && flutter test`
  - Expected: PASS
- [ ] **Step 5: Commits finales y cierre de Fase 05**
  - `git add mobile`
  - `git commit -m "feat(mobile-ui): add interactive BBT biphasic chart, LH/mucus logger, and preconception checklist"`
  - `git add docs/phases/phase-05-fertility-and-conception.md docs/phases/README.md`
  - `git commit -m "docs(plan): mark phase 05 tasks completed"`
