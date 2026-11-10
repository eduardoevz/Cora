# Documentación de Cierre — Fase 06: Etapa 4: Embarazo y Seguimiento Materno-Fetal

**Repositorio:** `eduardoevz/Cora`  
**Rama:** `main`  
**Fecha de Cierre:** 2026-11-10  
**Estado:** ✅ **Completada y Verificada (100% CI Green en GitHub Actions)**

---

## 1. Resumen Ejecutivo de la Fase

Durante la **Fase 06**, se construyó el bounded context hexagonal **`maternal_care`** para acompañar la **Etapa 4 de la vida: Embarazo** (semanas 4 a 42 de gestación). Este módulo opera de forma autónoma e independiente de `clinical_tracking` para separar limpiamente las reglas ginecológicas y menstruales de la fisiología obstétrica y el bienestar materno-fetal:

1. **Entidades y Value Objects de Dominio Obstétrico Puro:**
   - `BloodPressure`: modelado inmutable (`@dataclass(frozen=True)`) con validación de rangos fisiológicos estrictos ($60 - 260\,\text{mmHg}$ sistólica, $30 - 160\,\text{mmHg}$ diastólica) y la invariante innegociable de que la presión sistólica debe ser estrictamente mayor que la diastólica (`systolic_mmhg > diastolic_mmhg`). Ante inversiones accidentales en la entrada rápida del usuario (ej. $80/120\,\text{mmHg}$), el sistema rechaza la medición con una excepción clínica estructurada `InvalidBloodPressureError`.
   - `CapillaryGlucoseReading`: registro de glucemia capilar discriminada por momento de la toma (`fasting`, `postprandial_1h`, `postprandial_2h`, `bedtime`).
   - `MaternalWeightReading`: seguimiento del incremento ponderal gestacional.
   - `MaternalSymptom`: catálogo estandarizado de síntomas de alarma (cefalea persistente que no cede, escotomas o visión borrosa, dolor en epigastrio/hipocondrio derecho, edema súbito fascial o en manos, sangrado vaginal, pérdida de líquido amniótico).
   - `PregnancyEpisode`: cálculo de edad gestacional exacta (`GestationalAge(weeks, days)`), trimestre ($1^\circ$, $2^\circ$ o $3^\circ$) y fecha probable de parto (FPP) mediante la Regla de Naegele (+280 días desde la FUM), permitiendo la recalibración biométrica por ecografía del primer trimestre conservando la trazabilidad de la FUM original.

2. **Evaluador de Riesgo Materno ACOG (`MaternalRiskEvaluator`):**
   - **Crisis Hipertensiva / Sospecha de Preeclampsia Severa (`URGENT_EMERGENCY`):** Presión sistólica $\ge 160\,\text{mmHg}$ o diastólica $\ge 110\,\text{mmHg}$, o cifras $\ge 140/90\,\text{mmHg}$ acompañadas de cualquier síntoma de alarma neurológico, visual o epigástrico. Genera indicación inmediata e inequívoca de acudir de urgencia a valoración obstétrica.
   - **Hipertensión Gestacional en Consulta Prioritaria (`PRIORITY_CONSULT`):** Presión entre $140 - 159\,\text{mmHg}$ sistólica o $90 - 109\,\text{mmHg}$ diastólica sin síntomas de severidad. Recomienda reposo 15 minutos en decúbito lateral izquierdo y contacto prioritario con el obstetra.
   - **Detección Preventiva de Diabetes Gestacional:** Alertas preventivas ante glucemias fuera de meta orientativa ACOG ($\ge 95\,\text{mg/dL}$ en ayunas, $\ge 140\,\text{mg/dL}$ a 1 hora posprandial, $\ge 120\,\text{mg/dL}$ a 2 horas).

3. **Analizador de Contracciones y Movimientos Fetales (`ContractionAndKickAnalyzer`):**
   - **Regla 5-1-1 a Término ($\ge 37$ semanas):** Contracciones cada $\le 5$ minutos, de $\ge 60$ segundos de duración, sostenidas durante $\ge 1$ hora $\to$ alerta de trabajo de parto activo para traslado al centro obstétrico.
   - **Alerta Pretérmino Sensible ($< 37$ semanas):** Detección de dinámicas regulares tempranas ($\ge 4$ contracciones en 20 minutos o $\ge 8$ en 60 minutos) $\to$ alerta de urgencia inmediata por riesgo de amenaza de parto pretérmino.
   - **Protocolo de Cardiff ("Count-to-10"):** Meta de 10 patadas o movimientos en $\le 120$ minutos (patrón tranquilizador). Si tras 120 minutos se registran $< 10$ movimientos $\to$ alerta urgente con recomendaciones de estimulación y concurrencia hospitalaria para monitoreo fetal no estresante (RCTG).

4. **Plan de Parto y Citas Prenatales:**
   - Preferencias estructuradas en 4 pilares: Acompañamiento, Alivio del dolor, Entorno/Expulsivo y Primeras horas posparto (*Golden Hour*, contacto piel con piel ininterrumpido, inicio precoz de lactancia y pinzamiento tardío del cordón).
   - Agenda prenatal con fecha, profesional/clínica, semana gestacional, temario a discutir y notas.

5. **Persistencia y Migración en Neon PostgreSQL:**
   - Migración reversible de Alembic `0006_create_pregnancy_maternal_care_tables.py` ejecutada en Neon DB (`0005 -> 0006 (head)`).
   - Tablas creadas: `pregnancy_episodes`, `maternal_vitals`, `contraction_sessions`, `kick_sessions`, `birth_plans`, `prenatal_appointments`.

6. **Experiencia Móvil Offline-First en Flutter:**
   - Esquema Drift actualizado a **versión 6** con 6 tablas locales equivalentes.
   - `MaternalOfflineEvaluator`: motor determinista espejo en Dart que evalúa signos vitales, contracciones y patadas localmente en el dispositivo sin esperar conexión de red.
   - `PregnancyWeeklyHubPage`: resumen del progreso gestacional con semanas, días y trimestre.
   - `MaternalVitalsPage`: registro reactivo de tensión arterial, glucemia y síntomas con alertas visuales inmediatas.
   - `ContractionAndKickTimersPage`: cronómetro con intensidad de contracciones e interfaz táctil para conteo de patadas.
   - `BirthPlanAndAppointmentsPage`: configuración interactiva del plan de parto y agenda prenatal.
   - Integración fluida en `DynamicHomeDashboardPage` cuando la etapa activa es `LifeStage.pregnancy`.

---

## 2. Arquitectura, Módulos y Archivos Implementados

### Backend (FastAPI + Clean Architecture Hexagonal)

```
backend/
├── alembic/versions/
│   └── 0006_create_pregnancy_maternal_care_tables.py         # Tablas PostgreSQL en Neon
├── app/
│   ├── main.py                                                 # Inclusión del pregnancy_router
│   └── modules/
│       └── maternal_care/
│           ├── domain/
│           │   ├── exceptions/
│           │   │   └── maternal_care_exceptions.py             # InvalidBloodPressureError, etc.
│           │   ├── value_objects/
│           │   │   └── maternal_vitals.py                      # BloodPressure, MaternalClinicalAlert
│           │   ├── models/
│           │   │   └── pregnancy_episode.py                    # Agregado PregnancyEpisode, GestationalAge
│           │   └── services/
│           │       ├── maternal_risk_evaluator.py              # Reglas clínicas ACOG preeclampsia/GDM
│           │       ├── contraction_and_kick_analyzer.py        # 5-1-1, pretérmino y Cardiff count-to-10
│           │       └── fetal_weekly_milestones_catalog.py      # Catálogo anatómico semanas 4-42
│           ├── application/
│           │   ├── ports/
│           │   │   └── pregnancy_repository_port.py            # IPregnancyRepository
│           │   ├── dtos/
│           │   │   └── pregnancy_dtos.py                       # DTOs de casos de uso
│           │   └── use_cases/
│           │       └── pregnancy_use_cases.py                  # Casos de uso de embarazo, signos y plan
│           └── infrastructure/
│               ├── orm/
│               │   └── pregnancy_orm.py                        # Mapeo SQLAlchemy 2.0 Async
│               ├── adapters/
│               │   └── postgres_pregnancy_repository.py        # Repositorio PostgreSQL
│               └── entrypoints/
│                   ├── pregnancy_schemas.py                    # Esquemas Pydantic v2
│                   └── pregnancy_router.py                     # Router REST /api/v1/pregnancy
└── tests/
    ├── unit/maternal_care/
    │   ├── test_acog_maternal_risk_evaluator.py                # 28 tests unitarios ACOG / Vitals
    │   └── test_contractions_and_kicks.py                      # 19 tests unitarios contracciones/Cardiff
    └── integration/maternal_care/
        └── test_pregnancy_api.py                               # Tests de integración REST
```

### Mobile (Flutter + Drift SQLite Offline-First)

```
mobile/
├── lib/
│   ├── core/database/
│   │   ├── app_database.dart                                   # Schema v6: 6 nuevas tablas gestacionales
│   │   └── app_database.g.dart                                 # Código generado por drift build_runner
│   └── features/
│       ├── dashboard/presentation/pages/
│       │   └── dynamic_home_dashboard_page.dart                # Tarjeta de acceso directo al hub gestacional
│       └── pregnancy/
│           ├── domain/entities/
│           │   └── pregnancy_entities.dart                     # Entidades inmutables y MaternalOfflineEvaluator
│           ├── data/
│           │   └── pregnancy_repository_impl.dart              # SQLite local + SyncCoordinator outbox
│           └── presentation/
│               ├── providers/
│               │   └── pregnancy_providers.dart                # Providers Riverpod de gestación
│               └── pages/
│                   ├── pregnancy_weekly_hub_page.dart          # Hub semanal de embarazo
│                   ├── maternal_vitals_page.dart               # Monitor de PA, glucemia y síntomas
│                   ├── contraction_and_kick_timers_page.dart   # Cronómetro 5-1-1 y contador Cardiff
│                   └── birth_plan_and_appointments_page.dart   # Plan de parto ACOG y agenda médica
└── test/
    └── features/pregnancy/
        └── maternal_vitals_and_timers_test.dart                # 15 tests unitarios clínicos y de widgets
```

---

## 3. Decisiones Técnicas y Reglas Clínicas Aplicadas

| Decisión / Regla | Fundamento Clínico / Técnico |
| :--- | :--- |
| **Separación de `maternal_care`** | Evita la sobrecarga de `clinical_tracking` con reglas obstétricas irrelevantes para mujeres en otras etapas biológicas. |
| **Invariante `systolic > diastolic`** | La fisiología hemodinámica humana hace imposible que la presión diastólica supere a la sistólica; se intercepta antes de persistir. |
| **Criterios ACOG de Severidad ($\ge 160/110$)** | La hipertensión severa en el embarazo incrementa el riesgo de ictus, desprendimiento prematuro de placenta y eclampsia; requiere derivación urgente. |
| **Monitoreo de Síntomas Neurológicos/Visuales** | Cifras tensionales moderadas ($\ge 140/90$) con cefalea severa o escotomas reflejan vasoespasmo cerebral y se elevan a urgencia inmediata. |
| **Algoritmo de Cardiff (Count-to-10)** | Menos de 10 movimientos fetales en 2 horas correlaciona con hipoxia o compromiso fetal agudo; orienta estimulación y RCTG hospitalario. |
| **Regla 5-1-1 vs Alerta Pretérmino** | En embarazos a término ($\ge 37$ semanas) el patrón 5-1-1 previene ingresos hospitalarios en fase latente; en $< 37$ semanas cualquier dinámica regular exige tocodinamometría urgente. |
| **Espejo Determinista Offline** | En caso de que la madre se encuentre sin cobertura o modo avión, las alertas de preeclampsia y dinámicas uterinas se evalúan en milisegundos en el dispositivo. |

---

## 4. Pruebas Ejecutadas y Validación CI/CD

### Backend

- **Linters y Formateo:** `ruff check .` y `ruff format --check .` (0 issues).
- **Tipado Estricto:** `mypy --strict app` (0 issues).
- **Contrato OpenAPI:** Verificación con `test_openapi_drift.py` confirmando **0% de deriva**.
- **Tests Unitarios e Integración:** 130 tests pasando en total (`pytest tests -q`).

### Mobile

- **Generación de Código:** `dart run build_runner build --delete-conflicting-outputs` (69 outputs escritos, 0 errores).
- **Análisis Estático:** `flutter analyze --fatal-infos` (0 issues).
- **Tests Móviles:** 38 suites completas pasando exitosamente (`flutter test`).

---

## 5. Secuencia de Commits Realizados en la Fase

1. `fc5e626` — `feat(maternal-care): implement ACOG preeclampsia/GDM risk evaluator, contractions, and fetal tracking domain`
2. `5559cca` — `feat(maternal-care): add pregnancy persistence, ACOG vitals API, and birth plan endpoints`
3. `9a1fb27` — `feat(mobile-ui): build weekly fetal tracker, offline ACOG vitals alerts, and contraction/kick timers`
4. `b27dc32` — `docs(plan): mark phase 06 tasks completed in phase spec and roadmap`

---

## 6. Estado para la Siguiente Fase (Fase 07: Posparto y Salud Mental Perinatal)

La finalización de la Fase 06 deja construida la base para la **Fase 07** (`maternal_care` - Posparto):
- El agregado `PregnancyEpisode` cuenta con el estado y los campos para la transición de nacimiento hacia el episodio puerperal.
- Los módulos de signos vitales y persistencia en Neon DB están preparados para extenderse hacia el monitoreo de loquios, recuperación de piso pélvico, banco de leche y tamizaje emocional con la Escala de Depresión Posparto de Edimburgo (EPDS).
