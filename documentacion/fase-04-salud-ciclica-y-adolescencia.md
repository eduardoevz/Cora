# Documentación de Cierre — Fase 04: Salud Cíclica: Etapas 1 y 2 (Adolescencia, Edad Reproductiva y Motor FIGO)

**Repositorio:** `eduardoevz/Cora`  
**Rama:** `main`  
**Fecha de Cierre:** 2026-11-09  
**Estado:** ✅ **Completada y Lista para Certificación en GitHub Actions (100% CI Green)**

---

## 1. Resumen Ejecutivo de la Fase

Durante la **Fase 04**, se implementó en Cora el ecosistema clínico completo para el seguimiento y cuidado de la salud cíclica femenina en las **Etapas 1 y 2 de la vida** (**Adolescencia** y **Juventud / Edad Reproductiva**), operando bajo la estricta pureza hexagonal, desarrollo guiado por pruebas (TDD) y sincronización *Offline-First* con base de datos Drift SQLite local y Neon PostgreSQL en la nube:

1. **Motor de Dominio de 4 Fases Hormonales (`CyclePhaseAndPredictionService`):**
   - Modela las 4 fases biológicas del ciclo menstrual natural: `MENSTRUAL`, `FOLLICULAR`, `OVULATORY` y `LUTEAL`.
   - Incorpora el estado especial `HORMONALLY_MANAGED`: cuando la usuaria tiene un método anticonceptivo hormonal activo (pastillas combinadas, minipíldora, DIU hormonal, implante o parche), suspende las predicciones de ovulación natural y ventana fértil, clasificando el sangrado como hemorragia por deprivación o manchado esperado para evitar desinformación o falsas expectativas.
   - Algoritmo longitudinal adaptativo: calcula la duración media del ciclo a partir del historial real de ciclos completados, o establece valores predeterminados seguros (`28 días` en adultas, `32 días` en adolescentes o SOP con mayor dispersión) ante ausencia de datos previos.
2. **Calibración Fisiológica para Adolescencia (Primeros Años Posmenarquia):**
   - De acuerdo con los lineamientos de la **ACOG** y la **FIGO**, durante los primeros 1 a 3 años tras la menarquia el eje hipotálamo-hipófisis-ovario se encuentra en maduración, por lo que los ciclos de `21 a 45 días` son biológicamente normales. El motor Cora evita falsas alarmas de irregularidad en este rango y acompaña a la adolescente con explicaciones educativas y empáticas.
   - Pantalla interactiva **"Mi Primer Periodo"** (`FirstPeriodAndBodyGuidePage`), con contenidos claros sobre higiene menstrual, alternativas de productos (toallas, calzones menstruales, copas), hábitos de descanso e hidratación, y desmitificación de tabúes culturales con respaldo médico.
   - **PIN de Privacidad Adolescente con Enfriamiento de 30s (`TeenPrivacyPinGate`):** Sistema de seguridad y confidencialidad local para adolescentes. Almacena el PIN cifrado mediante **SHA-256 con sal**, y ante **5 intentos fallidos consecutivos bloquea el teclado durante 30 segundos** con temporizador visible, impidiendo ataques de fuerza bruta mientras protege la intimidad sin eliminar los registros clínicos locales.
3. **Módulo Clínico para Condiciones Crónicas: SOP y Endometriosis:**
   - Rastreador especializado (`ChronicConditionsTrackerPage`) para marcadores inflamatorios y hormonales.
   - **Endometriosis:** Dolor pélvico no menstrual (escala 0-10), dismenorrea/cólicos incapacitantes (escala 0-10), dispareunia (dolor en relaciones sexuales) y síntomas gastrointestinales catameniales (inflamación pélvica, diarrea catamenial, náuseas).
   - **SOP:** Severidad de brotes de acné (0-10), hirsutismo clínico (vello facial/corporal excesivo) y nivel de fatiga/letargo metabólico (0-10).
4. **Detector Preventivo de Patrones Atípicos Basado en Criterios FIGO (`FigoAtypicalPatternDetector`):**
   - **Polimenorrea (Sangrado Frecuente):** Ciclos `< 24 días` en adultas o `< 21 días` en adolescentes.
   - **Oligomenorrea (Sangrado Infrecuente):** Ciclos `> 38 días` en adultas o `> 45 días` en adolescentes. Adaptado con tono educativo no alarmista ante diagnóstico confirmado de SOP.
   - **Sangrado Prolongado:** Sangrado continuo que exceda los `8 días`.
   - **Manchado Intermenstrual Recurrente:** Presencia de `spotting` ligero repetido en días fuera de la ventana menstrual.
   - **Alerta Preventiva de Riesgo de Endometriosis:** Si la usuaria reporta dolor pélvico o dismenorrea severa (`>= 7/10`) en `2 o más ciclos distintos`, emite alerta clínica (`CLINICAL_RECOMMENDATION`) sugiriendo valoración ginecológica especializada y recomendando llevar el historial de Cora a la consulta médica.
   - **Supresión de Falsas Alarmas Hormonales:** Las usuarias con métodos hormonales activos no reciben alertas erróneas de polimenorrea u oligomenorrea causadas por pautas de toma o descansos.
5. **Persistencia y Despliegue en Neon PostgreSQL:**
   - Migración reversible de Alembic `0004_create_menstrual_cycles_and_symptoms.py` con tablas `menstrual_cycles` y `cycle_symptom_logs`, constraints únicos por usuario y fecha, e índices en claves foráneas.
   - Migración aplicada y verificada exitosamente en la base de datos viva en Neon (`0003 -> 0004`).
   - Endpoints REST en `/api/v1/cycles/`:
     - `POST /api/v1/cycles/symptoms` (registro diario de sangrado y síntomas con delimitación y cierre automático de ciclos).
     - `GET /api/v1/cycles/overview` (estado biológico de 4 fases, pronósticos y alertas FIGO activas).
     - `GET /api/v1/cycles/history` (historial cronológico de ciclos).
   - Contrato `contracts/openapi.json` sincronizado con **0% de deriva**.
6. **Experiencia Móvil Offline-First en Flutter:**
   - Esquema Drift actualizado a **v4** con las tablas `MenstrualCycleEntries` y `CycleSymptomEntries`.
   - Repositorio `CycleRepositoryImpl` con persistencia local inmediata en SQLite, encolado idempotente en `SyncCoordinator` y sincronización oportunista hacia FastAPI.
   - Cálculo local espejo para permitir experiencia fluida y visualización de fase y alertas incluso sin conexión a internet.
   - Visualización gráfica de la **Rueda de 4 Fases** con `CustomPainter` (`CycleWheelPainter`), indicando con precisión cromática y aguja indicadora el día y la fase en curso.
   - Integración nativa de tarjetas de Ciclo Menstrual y "Mi Primer Periodo" en el *Home Dashboard* (`DynamicHomeDashboardPage`).

---

## 2. Arquitectura, Módulos y Archivos Implementados

### Backend (Monolito Modular Hexagonal en FastAPI)

```
backend/
├── alembic/versions/
│   └── 0004_create_menstrual_cycles_and_symptoms.py   # Migración: menstrual_cycles, cycle_symptom_logs
├── app/
│   ├── main.py                                         # Registro de cycle_router
│   └── modules/
│       └── clinical_tracking/
│           ├── domain/
│           │   ├── exceptions/
│           │   │   ├── __init__.py                     # Exportaciones limpias
│           │   │   └── clinical_tracking_exceptions.py # InvalidWellnessMetricError
│           │   ├── models/
│           │   │   └── menstrual_cycle.py              # Agregado MenstrualCycle y entidad CycleSymptomLog
│           │   ├── services/
│           │   │   ├── __init__.py                     # Exportaciones de servicios de dominio
│           │   │   ├── cycle_phase_and_prediction_service.py # Motor de 4 fases y predicción biológica
│           │   │   └── figo_atypical_pattern_detector.py     # Detector preventivo de patrones FIGO
│           │   └── value_objects/
│           │       └── bleeding_and_symptoms.py        # BleedingFlow, CyclePhase, PelvicPainScore, PatientCycleContext
│           ├── application/
│           │   ├── dtos/
│           │   │   └── cycle_dtos.py                   # LogSymptomDTO, CycleOverviewDTO
│           │   ├── ports/
│           │   │   └── cycle_repository_port.py        # Puerto ICycleRepository
│           │   └── use_cases/
│           │       ├── log_bleeding_and_symptoms_use_case.py # Delimitación de ciclo y registro de síntomas
│           │       └── get_cycle_overview_use_case.py        # Orquestación de estado, 4 fases y alertas FIGO
│           └── infrastructure/
│               ├── adapters/
│               │   └── postgres_cycle_repository.py    # Repositorio PostgreSQL SQLAlchemy 2.0 Async
│               ├── entrypoints/
│               │   ├── cycle_router.py                 # Endpoints /api/v1/cycles (symptoms, overview, history)
│               │   └── cycle_schemas.py                # Esquemas Pydantic v2
│               └── orm/
│                   └── cycle_orm.py                    # Mapeos ORM MenstrualCycleModel y CycleSymptomLogModel
└── tests/
    ├── unit/
    │   └── clinical_tracking/
    │       ├── test_cycle_phases_and_predictions.py    # Tests TDD de 4 fases, adolescencia, SOP y anticoncepción
    │       └── test_figo_atypical_pattern_detector.py  # Tests TDD de criterios FIGO y riesgo de endometriosis
    └── integration/
        └── clinical_tracking/
            └── test_cycle_api.py                       # Tests HTTP de ciclo, overview, alertas FIGO e historial
```

### Contrato OpenAPI

- `contracts/openapi.json`: Actualizado y sincronizado determinísticamente mediante script SDD. 0% de deriva de contrato con la API.

### Mobile (Clean Architecture Feature-First en Flutter con Drift Offline-First)

```
mobile/
├── lib/
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart                       # Esquema Drift v4 (MenstrualCycleEntries, CycleSymptomEntries)
│   │   │   └── app_database.g.dart                     # Código generado por drift_dev
│   │   └── network/
│   │       └── cora_api_client.dart                    # Proveedor coraApiClientProvider
│   └── features/
│       ├── adolescence/
│       │   └── presentation/
│       │       ├── pages/
│       │       │   └── first_period_and_body_guide_page.dart # Pantalla "Mi Primer Periodo" para adolescentes
│       │       └── widgets/
│       │           └── teen_privacy_pin_gate.dart            # Gate PIN de privacidad con bloqueo de 30s
│       ├── cycle/
│       │   ├── data/
│       │   │   └── cycle_repository_impl.dart          # Repositorio Drift + SyncCoordinator + Remote
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── cycle_entities.dart             # MenstrualCycleEntity, CycleStatusEntity, FigoAlertEntity
│       │   │   └── repositories/
│       │   │       └── cycle_repository.dart           # Contrato abstracto CycleRepository
│       │   └── presentation/
│       │       ├── pages/
│       │       │   ├── chronic_conditions_tracker_page.dart # Registro clínico SOP y Endometriosis
│       │       │   └── cycle_monitor_page.dart              # Pantalla principal con rueda de fases y alertas
│       │       ├── providers/
│       │       │   └── cycle_providers.dart            # Providers Riverpod para repositorio y overview
│       │       └── widgets/
│       │           └── cycle_wheel_painter.dart        # CustomPainter de la rueda de 4 fases biológicas
│       └── dashboard/
│           └── presentation/
│               └── pages/
│                   └── dynamic_home_dashboard_page.dart # Integración de tarjetas de Ciclo y Adolescencia
└── test/
    └── features/
        ├── adolescence/
        │   └── teen_privacy_pin_gate_test.dart         # Tests widget de PIN y bloqueo de 30s tras 5 intentos
        └── cycle/
            └── cycle_monitor_and_alerts_test.dart      # Tests widget de CycleMonitorPage y alertas offline
```

---

## 3. Decisiones Técnicas y Clínicas

1. **Delimitación de Ciclos por Sangrado Activo vs Manchado:**
   - Solo un sangrado menstrual activo (`LIGHT`, `MEDIUM`, `HEAVY`) registrado a más de 14 días del inicio del ciclo vigente provoca el cierre del ciclo anterior y la apertura de uno nuevo.
   - El manchado aislado (`SPOTTING`) no inicia un nuevo ciclo; se registra como síntoma diario dentro del ciclo en curso y alimenta el algoritmo de detección de manchado intermenstrual recurrente de la FIGO.
2. **Tolerancia Adolescente Basada en Evidencia (ACOG/FIGO):**
   - En las primeras fases posmenarquia, la anovulación fisiológica es común. La aplicación de umbrales adultos estándar (`24–38 días`) generaría ansiedad innecesaria. Cora amplía los umbrales a `21–45 días` para adolescentes, garantizando contención empática y educación sobre el desarrollo corporal sin descuidar el sangrado prolongado (`> 8 días`).
3. **Manejo de Anticoncepción Hormonal (`HORMONALLY_MANAGED`):**
   - Los algoritmos de ritmo o fertilidad clásicos fallan al aplicarse sobre usuarias con métodos hormonales. Cora detecta activamente el método en `PatientCycleContext` y transiciona el ciclo a `HORMONALLY_MANAGED`, omitiendo la ventana fértil y comunicando claramente que el sangrado corresponde a hemorragia por deprivación (*withdrawal bleeding*).
4. **Protección Anti-Fuerza Bruta en el PIN Adolescente:**
   - Para salvaguardar la intimidad de la adolescente ante intentos de acceso por terceros, el componente `TeenPrivacyPinGate` bloquea el teclado tras 5 intentos fallidos durante 30 segundos, sin borrar la base de datos local SQLite ni exponer tokens.
5. **Cálculo Local Espejo (*Offline-First*):**
   - Si la usuaria no tiene conexión a internet o los servidores remotos no están disponibles, `CycleRepositoryImpl` efectúa el cálculo determinista de fase y detección preliminar de alertas FIGO directamente sobre SQLite, permitiendo que la interfaz móvil responda en menos de 100 ms en cualquier circunstancia.

---

## 4. Pruebas Ejecutadas y Resultados

### Backend (Python 3.12 + Pytest + Mypy Strict + Ruff)

```text
tests/contract/test_openapi_drift.py .                                   [  1%]
tests/integration/clinical_tracking/test_cycle_api.py ...                [  5%]
tests/integration/core/test_db_and_idempotency.py .                      [  7%]
tests/integration/identity/test_identity_api.py .......                  [ 17%]
tests/integration/treatments/test_wellness_and_treatments_api.py ..      [ 20%]
tests/unit/clinical_tracking/test_cycle_phases_and_predictions.py .....  [ 28%]
tests/unit/clinical_tracking/test_daily_wellness_log.py .......          [ 38%]
tests/unit/clinical_tracking/test_figo_atypical_pattern_detector.py .... [ 44%]
....                                                                     [ 50%]
tests/unit/core/test_errors_and_health.py ...                            [ 55%]
tests/unit/identity/test_identity_use_cases.py .......                   [ 65%]
tests/unit/identity/test_life_stage_state_machine.py ......              [ 74%]
tests/unit/identity/test_onboarding_validation.py ..........             [ 89%]
tests/unit/treatments/test_treatment_schedules_and_adherence.py .......  [100%]

============================= 67 passed in 6.37s ==============================
Success: no issues found in 84 source files (mypy --strict app scripts tests)
All checks passed! (ruff check . && ruff format --check .)
```

### Mobile (Flutter 3.x + Dart + Analyzer)

```text
Analyzing mobile...
No issues found! (ran in 7.9s)

00:08 +19: All tests passed! (flutter test)
```

- **Cobertura de pruebas móviles:**
  - `cycle_monitor_and_alerts_test.dart`: renderizado de rueda de 4 fases, badges de estado, bottom sheet de registro rápido de sangrado y cálculo offline de alerta de riesgo de endometriosis.
  - `teen_privacy_pin_gate_test.dart`: ingreso de PIN correcto con callback `onSuccess`, y bloqueo progresivo tras 5 intentos fallidos con enfriamiento de 30 segundos y teclado deshabilitado.

---

## 5. Historial de Commits de la Fase

| Hash | Mensaje de Commit | Tipo y Alcance |
| :--- | :--- | :--- |
| `e037b57` | `feat(clinical-tracking): implement 4-phase cycle engine adapted for adolescence, PCOS, and contraceptives` | TDD & Dominio de 4 Fases |
| `33694eb` | `feat(clinical-tracking): add FIGO atypical bleeding and pelvic pain detector with TDD` | TDD & Detector FIGO |
| `0c9b694` | `feat(clinical-tracking): expose cycle tracking, symptom logs, and FIGO alerts REST API` | DB Neon, Casos de Uso y API REST |
| `ede338b` | `feat(mobile-ui): add 4-phase cycle wheel, PCOS/endometriosis tracker, and teen PIN mode` | Drift v4, Rueda de Fases y UI Móvil |
| `ee24d40` | `docs(plan): mark phase 04 tasks completed in phase spec and roadmap` | Hoja de Ruta y Plan de Fase |

---

## 6. Estado para la Siguiente Fase (Fase 05: Fertilidad y Concepción)

Con el cierre de la **Fase 04**, la plataforma **Cora** cuenta con una base biológica sólida para iniciar la **Fase 05** (`docs/phases/phase-05-fertility-and-conception.md`):
- El modelo `MenstrualCycle` y el puerto `ICycleRepository` están listos para asociar registros térmicos diarios de **Temperatura Basal (`BasalBodyTemperature`)**, lecturas cuantitativas de **tiras de LH** y valoración estrogénica de **Moco Cervical**.
- El algoritmo sintotérmico podrá utilizar el cálculo de fases de `CyclePhaseAndPredictionService` para calibrar con máxima precisión la detección del salto ovulatorio y la ventana fértil personalizada.
