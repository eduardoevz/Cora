# Fase 08 — Etapas 6 y 7: Perimenopausia/Menopausia y Plenitud/Adulta Mayor (`mature_health`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el módulo hexagonal `mature_health` y las vistas móviles adaptadas para **Perimenopausia y Menopausia** (transición STRAW+10, mapa de sofocos y síntomas vasomotores/cognitivos, seguimiento de TRH y salud cardiometabólica) y **Plenitud / Adulta Mayor** (salud ósea/osteoporosis, prevención de caídas, diario uroginecológico, modo de **Alta Legibilidad WCAG AAA** y botón directo de contacto familiar/soporte).

**Architecture:** `mature_health` agrupa las etapas de transición hormonal y madurez plena. `MenopauseTransitionService` aplica criterios **STRAW+10** y detecta sangrado posmenopáusico (bandera roja clínica tras `>= 12` meses de amenorrea sin causa hormonal cíclica), mientras `SeniorVitalityService` consolida marcadores de densidad mineral ósea (`DexaScore`), riesgo funcional de caídas y diario de continencia/suelo pélvico.

**Tech Stack:** Python 3.12+, FastAPI, SQLAlchemy 2.0 Async, Flutter, Riverpod, Drift, `url_launcher` (llamada/mensaje rápido a contacto de confianza con confirmación accesible).

**Spec:** `docs/SPECS.MD` (Sección 3.2 Etapas 6 y 7), `.agents/rules/03-clinical-tdd-and-safety.md`, `.agents/rules/05-mobile-flutter-offline-first.md`

## Global Constraints

- **Bandera roja clínica obligatoria en posmenopausia:** Cualquier episodio de sangrado vaginal una vez establecida la menopausia (`>= 12` meses consecutivos sin menstruación, salvo sangrado cíclico predecible explicado por esquema secuencial de TRH documentado, e incluso allí sujeto a revisión médica) genera una alerta prioritaria de valoración ginecológica (`POSTMENOPAUSAL_BLEEDING_ALERT`).
- Criterios **STRAW+10**: transición menopáusica temprana (`variación persistente >= 7 días` en longitud de ciclos adyacentes), transición tardía (`intervalo de amenorrea >= 60 días`), posmenopausia establecida (`>= 365 días` desde el último periodo menstrual).
- En etapa `senior_vitality`, la interfaz activa por defecto el perfil visual `CoraTheme.highLegibility()`: contraste mínimo `7:1` (WCAG AAA), tamaño base tipográfico ampliado, botones con altura `>= 56 dp` y acceso permanente en barra superior/dashboard al **Contacto Familiar / Soporte**.

## Review Focus

1. **Sangrado posmenopáusico tras `>= 12` meses sin regla:** Nunca debe tratarse como "inicio de un nuevo ciclo menstrual regular"; debe disparar `POSTMENOPAUSAL_BLEEDING_ALERT` recomendando evaluación ginecológica oportuna.
2. **Correlación temporal entre sofocos nocturnos, calidad de sueño y adherencia a TRH:** Permitir cruzar episodios vasomotores (`HotFlashEpisode`: diurno/nocturno, intensidad `1–4`, desencadenantes como cafeína/estrés/calor) con cambios en esquema de TRH.
3. **Clasificación OMS de densitometría ósea (`T-score`):** Normal (`>= -1.0`), Osteopenia (`-1.0 > T-score > -2.5`), Osteoporosis (`<= -2.5`), cruzado con historial de caídas previas (`>= 1` caída en últimos `12` meses o inestabilidad al caminar -> alerta preventiva de evaluación geriátrica/fisioterapia).
4. **Activación accidental del Botón de Contacto Familiar en adultos mayores:** Usar confirmación clara de dos toques grandes (sin gestos finos complejos como *pinch* o *long-press* oculto) antes de iniciar la llamada/mensaje.
5. **Accesibilidad real bajo `TextScaler.linear(2.0)` en todas las pantallas de `mature_health`:** Cero textos truncados con `TextOverflow.ellipsis` en instrucciones clínicas o alertas.

---

### Task 1: Dominio de `mature_health` — Transición STRAW+10, Sofocos, Cardiometabolismo, Salud Ósea/Caídas y Uroginecología (TDD)

**Files:**
- Create: `backend/app/modules/mature_health/domain/value_objects/menopause_and_senior_metrics.py`
- Create: `backend/app/modules/mature_health/domain/models/vasomotor_and_metabolic_logs.py`
- Create: `backend/app/modules/mature_health/domain/models/bone_fall_and_urogynecology.py`
- Create: `backend/app/modules/mature_health/domain/services/menopause_transition_service.py`
- Create: `backend/app/modules/mature_health/domain/services/senior_vitality_evaluator.py`
- Test: `backend/tests/unit/mature_health/test_straw10_and_postmenopausal_bleeding.py`
- Test: `backend/tests/unit/mature_health/test_bone_fall_and_urogynecology.py`

**Interfaces:**
- Consumes: `DomainError`
- Produces:
  - `Straw10Stage`, `HotFlashEpisode`, `CardiometabolicPanel` (`ldl_mg_dl`, `hdl_mg_dl`, `triglycerides_mg_dl`, `fasting_glucose_mg_dl`, `blood_pressure`)
  - `DexaBoneResult` (`t_score: Decimal`, `classification: NORMAL | OSTEOPENIA | OSTEOPOROSIS`), `FallRiskAssessment`, `ContinenceAndPelvicLog`, `TrustedSupportContact`
  - `MenopauseTransitionService` y `SeniorVitalityEvaluator`

- [ ] **Step 1: Escribir tests TDD parametrizados cubriendo: clasificación STRAW+10 temprana/tardía/posmenopausia, disparo obligatorio de `POSTMENOPAUSAL_BLEEDING_ALERT` tras `400` días de amenorrea, clasificación OMS de `T-score` (`-0.8`, `-1.8`, `-2.7`), puntaje de riesgo de caídas y frecuencia de episodios de incontinencia de esfuerzo vs urgencia**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/unit/mature_health -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar los Value Objects, entidades y servicios deterministas en `mature_health/domain/`**
- [ ] **Step 4: Verificar pase en `< 50 ms` y `mypy --strict`**
  - Run: `mypy --strict backend/app && pytest backend/tests/unit/mature_health -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/app/modules/mature_health/domain backend/tests/unit/mature_health`
  - `git commit -m "feat(mature-health): implement STRAW+10 menopause engine, postmenopausal bleeding alert, and senior bone/fall evaluators"`

---

### Task 2: Persistencia PostgreSQL, Casos de Uso y Endpoints REST de Perimenopausia y Plenitud

**Files:**
- Create: `backend/alembic/versions/0008_create_mature_health_tables.py`
- Create: `backend/app/modules/mature_health/application/ports/mature_health_repository_port.py`
- Create: `backend/app/modules/mature_health/application/use_cases/mature_health_use_cases.py`
- Create: `backend/app/modules/mature_health/infrastructure/orm/mature_health_orm.py`
- Create: `backend/app/modules/mature_health/infrastructure/adapters/postgres_mature_health_repository.py`
- Create: `backend/app/modules/mature_health/infrastructure/entrypoints/mature_health_router.py`
- Modify: `backend/app/main.py`
- Modify: `contracts/openapi.json`
- Test: `backend/tests/integration/mature_health/test_mature_health_api.py`

**Interfaces:**
- Consumes: `ICycleRepository`, `ITreatmentRepository` (correlación con TRH y calcio/vitamina D), servicios de Task 1
- Produces:
  - `IMatureHealthRepository` (reutilizado en Fase 9 PDF y Fase 10 RAG)
  - `POST /api/v1/mature-health/hot-flashes`, `GET /api/v1/mature-health/menopause-summary`, `POST /api/v1/mature-health/cardiometabolic-panels`, `POST /api/v1/mature-health/bone-and-fall-assessments`, `POST /api/v1/mature-health/continence-logs`, `PUT /api/v1/mature-health/support-contact`

- [ ] **Step 1: Escribir tests de integración HTTP verificando mapa semanal de sofocos diurnos/nocturnos, alerta ante sangrado posmenopáusico, registro de `T-score` y configuración de contacto familiar**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/integration/mature_health/test_mature_health_api.py -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar migración `0008`, ORM, repositorio Postgres, casos de uso, router y exportar `contracts/openapi.json`**
- [ ] **Step 4: Verificar suite completa backend**
  - Run: `python backend/scripts/export_openapi.py && pytest backend/tests -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/alembic/versions/0008_create_mature_health_tables.py backend/app/modules/mature_health backend/app/main.py contracts/openapi.json backend/tests/integration/mature_health/test_mature_health_api.py`
  - `git commit -m "feat(mature-health): add menopause, cardiometabolic, bone health, and urogynecology REST APIs"`

---

### Task 3: Módulos Móviles Flutter — Gestor de Sofocos/TRH, Hub de Plenitud en Alta Legibilidad y Botón de Contacto Familiar

**Files:**
- Create: `mobile/lib/features/menopause/domain/entities/menopause_entities.dart`
- Create: `mobile/lib/features/menopause/data/menopause_repository_impl.dart`
- Create: `mobile/lib/features/menopause/presentation/pages/perimenopause_hub_page.dart`
- Create: `mobile/lib/features/senior_vitality/domain/entities/senior_vitality_entities.dart`
- Create: `mobile/lib/features/senior_vitality/data/senior_vitality_repository_impl.dart`
- Create: `mobile/lib/features/senior_vitality/presentation/pages/senior_vitality_hub_page.dart`
- Create: `mobile/lib/features/senior_vitality/presentation/widgets/trusted_contact_quick_action_card.dart`
- Modify: `mobile/lib/core/database/app_database.dart`
- Modify: `mobile/lib/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart`
- Test: `mobile/test/features/menopause/hot_flash_tracker_test.dart`
- Test: `mobile/test/features/senior_vitality/high_legibility_and_support_contact_test.dart`

**Interfaces:**
- Consumes: `CoraTheme.highLegibility()`, `AppDatabase`, `SyncCoordinator`, `activeUserProfileProvider`
- Produces: Experiencia móvil completa de Etapas 6 y 7

- [ ] **Step 1: Escribir widget/unit tests verificando: registro rápido de sofoco en 2 toques, renderizado WCAG AAA con `TextScaler.linear(2.0)` sin overflow ni truncamiento de alertas en `SeniorVitalityHubPage`, y confirmación accesible de 2 pasos en `TrustedContactQuickActionCard`**
- [ ] **Step 2: Ejecutar `flutter test` y confirmar fallo**
  - Run: `cd mobile && flutter test test/features/menopause test/features/senior_vitality`
  - Expected: FAIL
- [ ] **Step 3: Implementar tablas Drift de menopausia y plenitud, repositorios *Offline-First* y pantallas adaptadas conectadas al *Home Dashboard***
- [ ] **Step 4: Ejecutar `build_runner`, `flutter analyze` y `flutter test`**
  - Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-infos && flutter test`
  - Expected: PASS
- [ ] **Step 5: Commits finales y cierre de Fase 08**
  - `git add mobile`
  - `git commit -m "feat(mobile-ui): add menopause hot-flash tracker, WCAG AAA senior vitality hub, and family support button"`
  - `git add docs/phases/phase-08-menopause-and-senior-vitality.md docs/phases/README.md`
  - `git commit -m "docs(plan): mark phase 08 tasks completed"`
