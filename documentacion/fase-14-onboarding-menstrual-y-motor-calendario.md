# Fase 14 — Onboarding con Últimos 2 Periodos, Regularidad, Duración del Ciclo y Motor de Proyección Mensual

**Fecha de cierre:** 2026-11-21  
**Estado:** ✅ Completada (CI/CD 100% en verde — `Backend CI`, `Mobile CI` y `Security & OpenAPI Contract Verification`)

---

## 1. Resumen Ejecutivo de la Fase

En la **Fase 14** dotamos a **Cora** de una calibración menstrual inicial realista desde el primer arranque (*Day-Zero Calibration*) y de un motor determinista de proyección diaria del calendario menstrual en paridad exacta entre **Python** y **Dart** (*Offline-First*):

1. **Línea Base Menstrual en Onboarding (`OnboardingContext` + Alembic `0014` + Drift `v11`):** Se extendió el contexto clínico de onboarding con `cycle_regularity` (`regular`, `irregular`, `unsure`, `not_applicable`), `typical_cycle_length_days` (`15–90`), `typical_bleeding_duration_days` (`1–15`) y soporte para sembrar hasta **2 periodos históricos iniciales** (`initial_periods`).
2. **Paso Interactivo de Onboarding (`InitialPeriodsCalendarPicker`):** Se integró el **Paso 4** en `OnboardingWizardPage` para las etapas menstruales (`adolescence`, `regular_adult`, `conception_search`, `perimenopause`), permitiendo seleccionar inicio y fin del **Último periodo** y **Periodo anterior** en un calendario táctil (`>= 48x48dp`), autocalcular la duración real del ciclo con ajuste manual (`15–90 días`), indicar regularidad y respetar sin bloqueos las etapas no menstruales (`pregnancy`, `postpartum`, `senior_vitality` quedan en 3 pasos con `cycle_regularity = not_applicable`).
3. **Motor Determinista de Proyección Mensual (`CycleCalendarProjectionService` & `CycleCalendarEngine`):** Se implementó el motor hexagonal en backend y su espejo puro en Dart eliminando definitivamente la constante fija `cycleLen = 28` en `CycleRepositoryImpl`. Proyecta cualquier mes con días registrados, periodos predichos a futuro, ventana fértil, día estimado de ovulación, manchado, síntomas y mensajes educativos en español adaptados a las **7 etapas biológicas** y métodos hormonales.
4. **Endpoints REST y Contrato SDD (`contracts/openapi.json`):** Se expusieron `POST /api/v1/cycles/initial-periods`, `GET /api/v1/cycles/calendar` y la siembra atómica opcional dentro de `PUT /api/v1/identity/onboarding`, sincronizados con `contracts/openapi.json`.

---

## 2. Arquitectura, Módulos y Archivos Implementados

### Backend (`backend/` y `contracts/`)
- **Dominio (`domain/` sin dependencias de infraestructura):**
  - `backend/app/modules/identity/domain/value_objects/onboarding_context.py`: `CycleRegularity` y validaciones de rango en `OnboardingContext` (`typical_cycle_length_days`, `typical_bleeding_duration_days`).
  - `backend/app/modules/clinical_tracking/domain/exceptions/__init__.py`: Reexportación de `ClinicalTrackingError` e `InvalidBasalTemperatureError`.
  - `backend/app/modules/clinical_tracking/domain/value_objects/bleeding_and_symptoms.py`: `CalendarDayMarker`, `FertilityProbability`, `CalendarDisplayMode`, `InitialPeriodRange`, `CalendarDayProjection`, `CalendarMonthProjection` y extensión de `PatientCycleContext`.
  - `backend/app/modules/clinical_tracking/domain/services/cycle_phase_and_prediction_service.py`: Calibración por historial + línea base (`estimate_cycle_length`, `has_uncertainty`) y manejo clínico de etapas no menstruales (`pregnancy`, `senior_vitality`, `postpartum`).
  - `backend/app/modules/clinical_tracking/domain/services/cycle_calendar_projection_service.py` y `__init__.py`: `CycleCalendarProjectionService.project_month(...)`.
- **Base de Datos y ORM:**
  - `backend/alembic/versions/0014_add_menstrual_baseline_to_profiles.py`: Migración reversible (`0013` → `0014`) en `user_profiles`.
  - `backend/app/modules/identity/infrastructure/orm/identity_models.py` y `postgres_user_profile_repository.py`: Mapeo y sincronización de los nuevos campos en `UserProfileModel`.
- **Aplicación y Endpoints REST (`application/` e `infrastructure/`):**
  - `backend/app/modules/identity/application/dtos/identity_dtos.py` y `complete_onboarding_use_case.py`.
  - `backend/app/modules/clinical_tracking/application/use_cases/seed_initial_periods_use_case.py`: Validación estricta (sin fechas futuras, sin solapamientos, distancia `15–90d`) y siembra de ciclos + registros diarios de sangrado.
  - `backend/app/modules/clinical_tracking/application/use_cases/get_cycle_calendar_use_case.py`.
  - `backend/app/modules/identity/infrastructure/entrypoints/schemas.py` y `router.py`: Soporte de línea base e `initial_periods` en `PUT /api/v1/identity/onboarding`.
  - `backend/app/modules/clinical_tracking/infrastructure/entrypoints/cycle_schemas.py` y `cycle_router.py`: `POST /api/v1/cycles/initial-periods`, `GET /api/v1/cycles/calendar` y calibración compartida vía `_build_patient_cycle_context`.
  - `contracts/openapi.json`: Contrato OpenAPI regenerado con `scripts/export_openapi.py`.

### Mobile Flutter *Offline-First* (`mobile/`)
- **Base de Datos Local Drift (`v11`):**
  - `mobile/lib/core/database/app_database.dart` y `app_database.g.dart`: Incremento a `schemaVersion = 11` con `m.addColumn` no destructivo sobre `UserProfileEntries`.
  - `mobile/lib/features/onboarding/data/local/profile_dao.dart` e `identity_repository_impl.dart`: Persistencia local + encolado `SyncOutbox` de `cycle_regularity`, `typical_cycle_length_days`, `typical_bleeding_duration_days` e `initial_periods`.
- **Dominio, Repositorios y Providers (`mobile/lib/features/cycle/`):**
  - `mobile/lib/features/onboarding/domain/entities/user_profile_entity.dart`: `CycleRegularity`, `InitialPeriodRangeEntity` y campos en `OnboardingContextEntity`.
  - `mobile/lib/features/cycle/domain/entities/cycle_entities.dart`: `CalendarDayMarker`, `FertilityProbability`, `CalendarDisplayMode`, `CalendarDayProjectionEntity`, `CalendarMonthProjectionEntity`.
  - `mobile/lib/features/cycle/domain/services/cycle_calendar_engine.dart`: Motor en Dart puro sin imports de UI/red/SQL.
  - `mobile/lib/features/cycle/domain/repositories/cycle_repository.dart`, `cycle_repository_impl.dart` y `cycle_providers.dart`: Implementación *Offline-First* de `seedInitialPeriods(...)` y `getCalendarMonth(...)`, eliminación de `const cycleLen = 28` y normalización `.toUtc()` al leer fechas Drift.
- **UI de Onboarding (`mobile/lib/features/onboarding/presentation/`):**
  - `mobile/lib/features/onboarding/presentation/widgets/initial_periods_calendar_picker.dart`: Selector calendario mensual interactivo (último y anterior periodo, validación anti-solapamiento, regularidad y stepper de duración `15–90d`) construido con `CoraTheme.tokensOf(context)` y primitivas Cora v2.
  - `mobile/lib/features/onboarding/presentation/pages/onboarding_wizard_page.dart`: Paso 4 condicional por etapa biológica y siembra inmediata en Drift SQLite.

### Pruebas (`backend/tests/` y `mobile/test/`)
- `backend/tests/unit/clinical_tracking/test_cycle_calendar_projection.py`: 5 pruebas unitarias de dominio.
- `backend/tests/integration/clinical_tracking/test_cycle_calendar_and_seed_api.py`: Pruebas de integración REST + SQLite/SQLAlchemy async.
- `mobile/test/features/cycle/cycle_calendar_engine_test.dart`: 5 pruebas unitarias de paridad clínica en Dart puro.
- `mobile/test/features/onboarding/onboarding_menstrual_baseline_test.dart`: Flujo E2E de 4 pasos en Drift, etapa embarazo con salto limpio, verificación de round-trip horario y auditoría `TextScaler.linear(2.0)` sin overflow.
- Actualización del flujo de Paso 4 para `regular_adult` en `onboarding_wizard_test.dart`, `cora_app_boot_test.dart`, `firebase_auth_flow_test.dart` e `integration_test/app_full_flow_e2e_test.dart`.

---

## 3. Decisiones Técnicas y Reglas Clínicas Aplicadas

1. **Precedencia Clínica (Historial Real > Línea Base Declarada > Heurística por Etapa):** `estimate_cycle_length` y `CycleCalendarEngine.estimateCycleLength` priorizan la mediana (o valor único) de ciclos completados entre `15` y `90` días; si aún no existen ciclos cerrados, usan `typical_cycle_length_days` capturado en onboarding; solo ante ausencia total de ambos datos recurren a `32` días (`ADOLESCENCE` o `PCOS`) o `28` días.
2. **Validación Temprana y Atomicidad de Onboarding:** En `PUT /api/v1/identity/onboarding`, los rangos `initial_periods` se validan mediante `SeedInitialPeriodsUseCase.validate_periods(...)` antes de persistir `UserProfile`, evitando perfiles creados a medias cuando se envían rangos solapados o con fechas futuras.
3. **Respeto a las 7 Etapas Biológicas y Métodos Hormonales:** En etapas `PREGNANCY`, `POSTPARTUM` (sin ciclos registrados) y `SENIOR_VITALITY` —así como bajo anticoncepción supresora de ovulación o TRH—, el motor suprime las predicciones de ovulación y ventana fértil, evitando falsas alertas en el calendario.
4. **Manejo Invariante de Zonas Horarias en Drift (`UTC Midnight`):** Drift serializa `DateTimeColumn` como timestamp Unix y al leerlo reconstruye un `DateTime` local (que en husos `UTC-6` desplazaba fechas UTC medianoche al día calendario anterior). Se aplicó `.toUtc()` consistente al mapear `startDate`, `endDate` y `logDate` desde Drift en `CycleRepositoryImpl`.

---

## 4. Pruebas Ejecutadas y Validación CI/CD

### Verificación Local Completa
- **Backend:**
  - `ruff check app scripts tests alembic` → `All checks passed!`
  - `ruff format --check app scripts tests alembic` → `267 files already formatted`
  - `mypy --strict app scripts tests` → `Success: no issues found in 252 source files`
  - `pytest tests/unit tests/integration/clinical_tracking/test_cycle_calendar_and_seed_api.py tests/integration/clinical_tracking/test_cycle_api.py tests/integration/identity tests/contract -q` → **`239 passed`**
- **Mobile Flutter:**
  - `dart format --output=none --set-exit-if-changed .` → `Formatted 129 files (0 changed)`
  - `flutter analyze --fatal-infos` → `No issues found!`
  - `flutter test` → **`+103: All tests passed!`**

### GitHub Actions CI/CD (Commit `86250b1` en `main`)
- **`Security & OpenAPI Contract Verification`** (Run [`44987412635`](https://github.com/eduardoevz/Cora/actions/runs/44987412635)): **`success`** (`16s`) — OpenAPI Drift Check & Gitleaks PHI/Secret Scan en verde.
- **`Backend CI`** (Run [`44987412591`](https://github.com/eduardoevz/Cora/actions/runs/44987412591)): **`success`** (`1m11s`) — Ruff, Mypy `--strict` y suite Pytest completa contra `pgvector` en verde.
- **`Mobile CI`** (Run [`44987412587`](https://github.com/eduardoevz/Cora/actions/runs/44987412587)): **`success`** (`2m24s`) — Integridad de `build_runner` Drift (`app_database.g.dart`), `dart format`, `flutter analyze` y los 103 tests en verde.

---

## 5. Secuencia de Commits Realizados

1. `cc3e50d` — `feat(clinical-tracking): add menstrual baseline calibration and monthly calendar projection domain service`
2. `b4be168` — `db(identity): add alembic migration 0014 and map menstrual baseline in UserProfileModel`
3. `56d9ed8` — `feat(clinical-tracking): expose initial-periods seeding and monthly calendar endpoints with OpenAPI contract`
4. `d7a062b` — `feat(mobile-sync): add Drift v11 menstrual baseline migration and offline-first CycleCalendarEngine`
5. `0714aaf` — `feat(mobile-ui): add interactive 2-period calendar baseline step to onboarding wizard`
6. `86250b1` — `docs(plan): mark tasks 1-4 completed in phase-14 plan pending CI certification`
7. *(Cierre plan)* — `docs(plan): mark phase-14 completed after green CI certification`
8. *(Cierre bitácora)* — `docs(documentacion): add phase-14 completion report in documentacion/`

---

## 6. Estado para la Siguiente Fase (Fase 15)

Quedan completamente listos para consumirse en la **Fase 15** (`docs/phases/phase-15-interactive-menstrual-calendar.md`):
- El provider Riverpod `cycleCalendarMonthProvider` y `CycleRepository.getCalendarMonth(...)` ya calculando `CalendarMonthProjectionEntity` desde Drift SQLite *Offline-First* con total paridad con `GET /api/v1/cycles/calendar`.
- Los datos iniciales reales sembrados desde onboarding (últimos 2 periodos, duración calculada del ciclo y regularidad declarada) disponibles desde el primer frame tras completar `OnboardingWizardPage`.
- Todos los tokens visuales `CoraColorTokens` y primitivas Cora v2 listas para construir la pantalla interactiva del **Calendario Menstrual** de 7 etapas en la Fase 15.
