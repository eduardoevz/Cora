# Documentación de Cierre — Fase 03: Núcleo Transversal: Bienestar Diario y Gestor de Tratamientos

**Repositorio:** `eduardoevz/Cora`  
**Rama:** `main`  
**Fecha de Cierre:** 2026-11-07  
**Estado:** ✅ **Completada y Verificada en GitHub Actions (100% CI Green)**

---

## 1. Resumen Ejecutivo de la Fase

Durante la **Fase 03**, se construyeron los dos módulos transversales permanentes de **Cora**, diseñados para acompañar a la usuaria a lo largo de cualquiera de sus 7 etapas biológicas: el **Asistente de Bienestar y Hábitos** (`clinical_tracking` base) y el **Gestor de Tratamientos y Fármacos** (`treatments`), operando bajo el paradigma *Offline-First* estricto y alineados con las guías de seguridad clínica y privacidad de datos sensibles:

1. **Bienestar y Hábitos Diarios (`DailyWellnessLog`):** Registro diario transversal consolidado por `(user_id, log_date)` con algoritmo de **fusión parcial idempotente (*merge-patch*)**. Permite a la usuaria registrar métricas de sueño (horas y calidad) y estado de ánimo en la mañana, e hidratación, ejercicio o notas personales en la noche, sin que ninguna edición parcial sobreescriba los datos registrados previamente.
2. **Value Objects Biomédicos con Validación Fisiológica:** Rango estricto en horas de sueño (`0.0–24.0 h`), escalas Likert subjetivas de calidad de sueño y energía vital (`1–5`), hidratación (`0–10000 ml`), minutos de ejercicio (`0–1440 min`) y etiquetas de ánimo y estado somático categorizadas (`MoodTag`: *calm, energetic, happy, anxious, exhausted, crampy, bloated, stressed*).
3. **Gestor de Tratamientos y Esquemas Cíclicos (`TreatmentRegimen`):** Modelado de regímenes terapéuticos cubriendo anticonceptivos orales combinados (esquemas con descanso programado `21/7` y `24/4`), minipíldora continua de solo progestina, parches transdérmicos, inyectables, suplementación (ácido fólico, hierro, calcio, magnesio, vitamina D), medicación crónica y métodos de largo plazo (LARC: DIU e implantes).
4. **Motor Clínico de Adherencia y Ventana Crítica de Olvido:** Servicio de dominio determinista (`AdherenceAndMissedDoseService`):
   - En regímenes `21/7` y `24/4`, los días en periodo de descanso/placebo no se penalizan como dosis olvidadas.
   - En anticonceptivos orales de solo progestina (minipíldora), un retraso en la toma `> 12 horas` activa de inmediato alerta preventiva indicando toma urgente y necesidad de método de barrera de respaldo por 48 horas.
   - En anticonceptivos orales combinados, la omisión `>= 24 horas` activa orientación clínica clara recomendando método de respaldo por 7 días ante dos o más olvidos.
   - En tratamientos LARC (DIU/implante), se generan alertas anticipadas de recambio a los 90 días (advertencia) y 30 días (urgente).
5. **Persistencia y Despliegue en Neon PostgreSQL:** Migración reversible de Alembic `0003_create_wellness_and_treatments_tables.py`, modelos ORM con índices optimizados y constraints únicos, endpoints REST con deduplicación idempotente (`IdempotencyStore` con `client_mutation_id` / `X-Client-Mutation-Id`), y actualización sin deriva del contrato `contracts/openapi.json`. Migración aplicada y verificada exitosamente en la base de datos viva en Neon.
6. **Experiencia Móvil Flutter Offline-First:** Actualización del esquema Drift a v3 (`DailyWellnessEntries`, `TreatmentRegimenEntries`, `DoseIntakeEntries`), `WellnessRepositoryImpl` y `TreatmentsRepositoryImpl` coordinados con `SyncCoordinator`, servicio de notificaciones con texto enmascarado por defecto (`DiscreetNotificationService`: *"Tienes un recordatorio de bienestar en Cora"*), pantallas interactivas `WellnessTrackerPage` y `PillboxAndTreatmentsPage`, integradas directamente al *Home Dashboard*.

---

## 2. Arquitectura, Módulos y Archivos Implementados

### Backend (Monolito Modular Hexagonal en FastAPI)

```
backend/
├── alembic/versions/
│   └── 0003_create_wellness_and_treatments_tables.py   # Migración: daily_wellness_logs, treatment_regimens, dose_intake_logs
├── app/
│   ├── main.py                                         # Registro de wellness_router y treatment_router
│   └── modules/
│       ├── clinical_tracking/
│       │   ├── domain/
│       │   │   ├── exceptions/clinical_tracking_exceptions.py # InvalidWellnessMetricError
│       │   │   ├── models/daily_wellness_log.py        # Entidad DailyWellnessLog con algoritmo merge_patch(...)
│       │   │   └── value_objects/wellness_metrics.py   # SleepHours, SleepQuality, EnergyLevel, HydrationMl, MoodTag
│       │   ├── application/
│       │   │   ├── dtos/wellness_dtos.py               # UpsertWellnessDTO, WellnessLogDTO
│       │   │   ├── ports/wellness_repository_port.py   # Puerto IWellnessRepository
│       │   │   └── use_cases/upsert_daily_wellness_use_case.py # Caso de uso de merge e inserción diaria
│       │   └── infrastructure/
│       │       ├── adapters/postgres_wellness_repository.py    # Repositorio PostgreSQL SQLAlchemy 2.0 Async
│       │       ├── entrypoints/
│       │       │   ├── wellness_router.py              # Endpoints /api/v1/wellness/logs (PUT /logs/{date}, GET)
│       │       │   └── wellness_schemas.py             # Esquemas Pydantic v2 RFC 7807
│       │       └── orm/wellness_orm.py                 # Mapeo ORM DailyWellnessLogModel
│       └── treatments/
│           ├── domain/
│           │   ├── exceptions/treatment_exceptions.py  # TreatmentRegimenNotFoundError, InvalidScheduleConfigurationError
│           │   ├── models/treatment_regimen.py         # Agregado TreatmentRegimen y entidad DoseIntakeLog
│           │   ├── services/adherence_and_missed_dose_service.py # Motor clínico 21/7, 24/4, LARC alerts y retrasos
│           │   └── value_objects/dosage_schedule.py    # TreatmentCategory, ScheduleType, DosageSchedule
│           ├── application/
│           │   ├── dtos/treatment_dtos.py              # CreateTreatmentRegimenDTO, LogDoseIntakeDTO
│           │   ├── ports/treatment_repository_port.py  # Puerto ITreatmentRepository
│           │   └── use_cases/manage_treatments_use_cases.py # CreateTreatmentRegimen, LogDoseIntake, GetAdherence
│           └── infrastructure/
│               ├── adapters/postgres_treatment_repository.py # Repositorio PostgreSQL SQLAlchemy 2.0 Async
│               ├── entrypoints/
│               │   ├── treatment_router.py             # Endpoints /api/v1/treatments (regimens, intakes, adherence)
│               │   └── treatment_schemas.py            # Esquemas Pydantic v2
│               └── orm/treatment_orm.py                # Mapeos ORM TreatmentRegimenModel y DoseIntakeLogModel
└── tests/
    ├── unit/
    │   ├── clinical_tracking/test_daily_wellness_log.py # Tests TDD de rangos, VOs y merge_patch
    │   └── treatments/test_treatment_schedules_and_adherence.py # Tests TDD de adherencia 21/7, 24/4, LARC y olvidos
    └── integration/
        └── treatments/test_wellness_and_treatments_api.py # Tests HTTP con auth Bearer e idempotencia
```

### Contrato OpenAPI

- `contracts/openapi.json`: Actualizado y sincronizado determinísticamente mediante script SDD.

### Mobile (Clean Architecture Feature-First en Flutter)

```
mobile/
├── lib/
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart                       # Esquema Drift v3 (DailyWellness, TreatmentRegimen, DoseIntake)
│   │   │   └── app_database.g.dart                     # Código generado por drift_dev
│   │   └── notifications/
│   │       └── discreet_notification_service.dart      # Notificaciones con enmascaramiento neutro por defecto
│   └── features/
│       ├── dashboard/presentation/pages/dynamic_home_dashboard_page.dart # Accesos rápidos a bienestar y pastillero
│       ├── treatments/
│       │   ├── data/treatments_repository_impl.dart    # Repositorio Drift + SyncCoordinator
│       │   ├── domain/entities/treatment_entities.dart # TreatmentRegimenEntity, DoseIntakeEntity
│       │   └── presentation/
│       │       ├── pages/pillbox_and_treatments_page.dart # Pastillero virtual, tomas de hoy, conmutador discreto
│       │       └── providers/treatment_providers.dart  # Providers Riverpod de regímenes y repositorio
│       └── wellness/
│           ├── data/wellness_repository_impl.dart      # Repositorio Drift + fusión local merge-patch
│           ├── domain/entities/daily_wellness_entity.dart # DailyWellnessEntity
│           └── presentation/
│               ├── pages/wellness_tracker_page.dart    # Pantalla de registro: sueño, calidad, agua, energía, ánimo
│               └── providers/wellness_providers.dart   # Providers Riverpod
└── test/
    └── features/
        ├── treatments/
        │   ├── pillbox_and_discreet_notification_test.dart # Test de enmascaramiento y persistencia offline
        │   └── pillbox_and_treatments_page_test.dart       # Test de widgets de pastillero y tomas
        └── wellness/
            ├── offline_wellness_merge_test.dart            # Test de fusión parcial sin pérdida de datos
            └── wellness_tracker_page_test.dart             # Test de widgets del tracker de bienestar
```

---

## 3. Decisiones Técnicas y Reglas Clínicas Aplicadas

1. **Fusión Parcial Determinista (*Merge-Patch*):** En aplicaciones de salud y hábitos diarios, las usuarias interactúan en múltiples momentos del día. Un `PUT /logs/{date}` que requiriera todos los campos pisaría datos matutinos con `null` al registrar agua al mediodía. El algoritmo de dominio `DailyWellnessLog.merge_patch(...)` y su contraparte local en Drift garantizan que sólo se actualicen los campos explícitamente suministrados.
2. **Esquemas Cíclicos sin Falsa Falta de Adherencia (`21/7` y `24/4`):** El servicio `AdherenceAndMissedDoseService` calcula matemáticamente los días transcurridos desde `startDate`. Si la usuaria se encuentra en los días de descanso programado (días 22–28 en un ciclo de 28 días), el sistema no marca omisión ni decrementa el porcentaje de adherencia.
3. **Diferenciación Clínica de Olvido en Anticonceptivos:**
   - *Minipíldora (Solo progestina):* Vida media corta. Un retraso `> 12 horas` compromete la eficacia anticonceptiva de inmediato; se activa indicación explícita de preservativo por 48 horas.
   - *Píldoras combinadas (Estrógeno + Progestina):* Margen de seguridad más amplio. El umbral crítico de alerta se establece en `>= 24 horas`.
4. **Alerta Preventiva de LARC:** DIUs e implantes tienen vigencias de 3 a 10 años, lo que propicia olvidos catastróficos. La evaluación a 90 días permite agendar la cita médica preventiva con holgura; a 30 días o menos se clasifica como prioritaria.
5. **Modo Discreto y Privacidad en Pantalla de Bloqueo:** En salud femenina (especialmente anticoncepción, fertilidad o salud mental), las notificaciones visibles en la pantalla de bloqueo pueden comprometer la intimidad o seguridad de la usuaria. Por regla obligatoria, el título y cuerpo predeterminados son neutros (*"Cora"*, *"Tienes un recordatorio de bienestar en Cora"*), revelando detalles clínicos únicamente si la usuaria deshabilita el modo discreto.

---

## 4. Pruebas Ejecutadas y Validación CI/CD

### Backend (`pytest`, `mypy --strict`, `ruff`)

- **Linters y Formateo:** `ruff check .` (0 advertencias), `ruff format --check .` (0 archivos modificados).
- **Tipado Estricto:** `mypy --strict app scripts tests` (0 errores en 67 archivos fuente).
- **Contrato OpenAPI:** `test_runtime_openapi_matches_committed_contract` (0% de deriva de esquema en `contracts/openapi.json`).
- **Pruebas Unitarias e Integración:** **51 tests ejecutados y pasando (100% PASS)**:
  - `tests/unit/clinical_tracking/test_daily_wellness_log.py` (7 tests)
  - `tests/unit/treatments/test_treatment_schedules_and_adherence.py` (7 tests)
  - `tests/integration/treatments/test_wellness_and_treatments_api.py` (2 tests de flujo completo)
  - Suites previas de `identity`, `core` y contratos (35 tests).

### Mobile (`flutter test`, `flutter analyze`)

- **Análisis Estático:** `flutter analyze --fatal-infos` (0 errores, 0 advertencias, 0 infos).
- **Pruebas Unitarias y Widgets:** **15 tests ejecutados y pasando (100% PASS)**:
  - `test/features/wellness/offline_wellness_merge_test.dart` (Fusión offline de ediciones parciales sin red)
  - `test/features/wellness/wellness_tracker_page_test.dart` (Widgets, sliders y guardado reactivo)
  - `test/features/treatments/pillbox_and_discreet_notification_test.dart` (Enmascaramiento discreto y tomas offline)
  - `test/features/treatments/pillbox_and_treatments_page_test.dart` (Widgets de pastillero y conmutador discreto)
  - Suites previas de `sync_outbox`, `accessibility` y `onboarding` (11 tests).

### Base de Datos en Producción (Neon PostgreSQL)

- Migración `0003_create_wellness_and_treatments_tables.py` aplicada de forma exitosa mediante `alembic upgrade head`.

---

## 5. Secuencia de Commits Realizados

1. `feat(clinical-tracking): implement DailyWellnessLog domain model and merge-patch use case` (`fa56977`)
2. `feat(treatments): implement dosage schedules, LARC replacement alerts, and adherence engine` (`3f22d3d`)
3. `feat(backend): add wellness and treatments persistence, idempotent APIs, and OpenAPI schemas` (`07d5355`)
4. `feat(mobile-ui): add offline-first wellness tracker, virtual pillbox, and discreet reminders` (`8e7b62b`)
5. `docs(plan): mark phase 03 tasks completed in phase spec and roadmap` (`78230f5`)
6. `docs(documentacion): add phase-03 completion report in documentacion/` *(este commit)*

---

## 6. Estado para la Siguiente Fase (Fase 04)

Con el núcleo transversal completado, la base queda lista para la **Fase 04 — Etapas 1 y 2: Salud Ginecológica, Ciclo Menstrual de 4 Fases y Modo Adolescencia**:
- El agregador `DailyWellnessLog` y el gestor `TreatmentRegimen` alimentarán el contexto diario del ciclo menstrual.
- El pastillero virtual coordinará los esquemas anticonceptivos con la predicción de hemorragia por deprivación (*withdrawal bleeding*).
- El sistema de notificaciones discretas protegerá la privacidad de las adolescentes en la Etapa 1.
