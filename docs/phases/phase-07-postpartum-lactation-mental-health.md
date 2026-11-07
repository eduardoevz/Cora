# Fase 07 — Etapa 5: Posparto, Lactancia y Salud Mental Materna (`maternal_care`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extender `maternal_care` y la app móvil para acompañar el **Cuarto Trimestre (Posparto y Crianza Inicial)**: monitoreo de recuperación física (loquios, cicatriz de cesárea/episiotomía y suelo pélvico), apoyo integral a la lactancia (tomas, extracción e inventario de almacenamiento) y despistaje preventivo de depresión posparto mediante la **Escala de Edimburgo (EPDS)**.

**Architecture:** Dentro de `maternal_care`, `PostpartumRecoveryService` evalúa signos de alarma puerperal (hemorragia posparto secundaria, endometritis o infección de herida quirúrgica), `LactationSession` y `MilkStashEntry` gestionan alimentación y caducidad segura según temperatura de conservación, y `EpdsScreeningService` puntúa los 10 ítems validados con reglas incondicionales de seguridad en salud mental.

**Tech Stack:** Python 3.12+, FastAPI, SQLAlchemy 2.0 Async, Flutter, Riverpod, Drift.

**Spec:** `docs/SPECS.MD` (Sección 3.2 Etapa 5: Posparto y Crianza Inicial), `.agents/rules/03-clinical-tdd-and-safety.md`

## Global Constraints

- **Regla clínica crítica EPDS (`0–30` puntos):**
  - Puntaje total `< 10` con ítem 10 `== 0`: seguimiento habitual de bienestar emocional.
  - Puntaje `10–12` con ítem 10 `== 0`: sugerencia empática de acompañamiento preventivo y repetir tamizaje en `2` semanas.
  - Puntaje `>= 13` con ítem 10 `== 0`: recomendación prioritaria de valoración por profesional de salud mental perinatal.
  - **Ítem 10 (pensamientos de hacerse daño) `> 0` (sea cual sea el puntaje total, incluso si el total es `1`):** clasificación obligatoria `IMMEDIATE_CRISIS_SUPPORT` mostrando contactos directos de ayuda de emergencia y red de apoyo.
- **Evolución fisiológica y banderas rojas de loquios:** alerta urgente ante empapar una compresa grande en `< 1` hora, coágulos grandes persistentes, olor fétido o fiebre materna `>= 38.0 °C`, o signos inflamatorios purulentos/dehiscencia en herida de cesárea o episiotomía.
- **Almacenamiento seguro de leche materna (guías OMS/CDC):** cálculo automático de vencimiento orientativo (`4h` temperatura ambiente `<= 25 °C`, `4 días` refrigerador `4 °C`, `6 meses` óptimo en congelador `-18 °C`).

## Review Focus

1. **Ítem 10 de EPDS positivo con puntaje global bajo (`total = 3`, `item_10 = 1`):** Debe disparar **siempre** `IMMEDIATE_CRISIS_SUPPORT`; un test específico debe fijar este invariante.
2. **Inversión de puntaje en los ítems de la escala EPDS:** Mientras los ítems `1, 2, 4` puntúan `0, 1, 2, 3`, los ítems `3, 5, 6, 7, 8, 9, 10` puntúan en orden inverso (`3, 2, 1, 0` según el orden estándar de presentación); validar cada ítem explícitamente por código de respuesta, no por índice ciego de UI.
3. **Regresión anormal de loquios (*alba/serosa* de vuelta a sangrado rojo intenso abundante tras la semana 2):** Debe distinguirse de manchado leve aislado para alertar posible hemorragia posparto secundaria.
4. **Uso con una sola mano de madrugada en el registro de lactancia:** Los botones de inicio/pausa/cambio de pecho en Flutter deben tener altura táctil `>= 56 dp` y funcionar en modo oscuro suave sin deslumbrar.
5. **Privacidad reforzada de resultados EPDS:** Los puntajes de salud mental nunca se exponen en resúmenes automáticos de *Partner View* salvo consentimiento explícito separado.

---

### Task 1: Dominio Puerperal — Recuperación Posparto, Lactancia/Banco de Leche y Escala EPDS (TDD)

**Files:**
- Create: `backend/app/modules/maternal_care/domain/value_objects/postpartum_observations.py`
- Create: `backend/app/modules/maternal_care/domain/models/lactation_and_milk_stash.py`
- Create: `backend/app/modules/maternal_care/domain/services/postpartum_recovery_evaluator.py`
- Create: `backend/app/modules/maternal_care/domain/services/epds_screening_service.py`
- Test: `backend/tests/unit/maternal_care/test_epds_screening_service.py`
- Test: `backend/tests/unit/maternal_care/test_postpartum_recovery_and_milk_stash.py`

**Interfaces:**
- Consumes: `DomainError`
- Produces:
  - `LochiaStage` (`RUBRA`, `SEROSA`, `ALBA`), `WoundHealingStatus`, `PelvicFloorLog`
  - `LactationSession`, `MilkStashEntry` (con cálculo `expires_at` según `StorageLocation`: `ROOM_TEMP`, `REFRIGERATOR`, `FREEZER`)
  - `EpdsScreeningService.score(responses: EpdsQuestionnaireInput) -> EpdsAssessmentResult`

- [ ] **Step 1: Escribir tests TDD exhaustivos para `EpdsScreeningService` (puntajes `0`, `9`, `11`, `14`, y el caso crítico `total=2` con `item_10_self_harm=1` -> `IMMEDIATE_CRISIS_SUPPORT`), alertas de endometritis/hemorragia/dehiscencia de herida en `PostpartumRecoveryEvaluator` y caducidad de leche extraída**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/unit/maternal_care/test_epds_screening_service.py backend/tests/unit/maternal_care/test_postpartum_recovery_and_milk_stash.py -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar modelos, Value Objects, `PostpartumRecoveryEvaluator` y `EpdsScreeningService`**
- [ ] **Step 4: Verificar pase en `< 50 ms` y `mypy --strict`**
  - Run: `mypy --strict backend/app && pytest backend/tests/unit/maternal_care -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/app/modules/maternal_care/domain backend/tests/unit/maternal_care`
  - `git commit -m "feat(maternal-care): implement postpartum recovery alerts, milk stash expiry, and EPDS screening with TDD"`

---

### Task 2: Persistencia PostgreSQL, Casos de Uso y Endpoints REST de Posparto

**Files:**
- Create: `backend/alembic/versions/0007_create_postpartum_lactation_epds_tables.py`
- Create: `backend/app/modules/maternal_care/application/ports/postpartum_repository_port.py`
- Create: `backend/app/modules/maternal_care/application/use_cases/postpartum_use_cases.py`
- Create: `backend/app/modules/maternal_care/infrastructure/orm/postpartum_orm.py`
- Create: `backend/app/modules/maternal_care/infrastructure/adapters/postgres_postpartum_repository.py`
- Create: `backend/app/modules/maternal_care/infrastructure/entrypoints/postpartum_router.py`
- Modify: `backend/app/main.py`
- Modify: `contracts/openapi.json`
- Test: `backend/tests/integration/maternal_care/test_postpartum_api.py`

**Interfaces:**
- Consumes: `IPregnancyRepository` (archivando el episodio de gestación al iniciar puerperio si estaba activo), servicios de Task 1
- Produces:
  - `IPostpartumRepository`
  - `POST /api/v1/postpartum/recovery-logs`, `POST /api/v1/postpartum/lactation-sessions`, `POST /api/v1/postpartum/milk-stash`, `GET /api/v1/postpartum/milk-stash`, `POST /api/v1/postpartum/epds-screenings`

- [ ] **Step 1: Escribir tests de integración HTTP verificando registro de loquios con fiebre puerperal, alta y consumo FIFO de lote en banco de leche, y envío de cuestionario EPDS sin filtrar respuestas en logs del servidor**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/integration/maternal_care/test_postpartum_api.py -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar migración `0007`, ORM, repositorio, casos de uso, router y regenerar `contracts/openapi.json`**
- [ ] **Step 4: Verificar toda la suite backend**
  - Run: `python backend/scripts/export_openapi.py && pytest backend/tests -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/alembic/versions/0007_create_postpartum_lactation_epds_tables.py backend/app/modules/maternal_care backend/app/main.py contracts/openapi.json backend/tests/integration/maternal_care/test_postpartum_api.py`
  - `git commit -m "feat(maternal-care): add postpartum recovery, lactation, milk stash, and EPDS REST endpoints"`

---

### Task 3: Módulo Móvil Flutter — Cuarto Trimestre, Cronómetro Nocturno de Lactancia y Cuestionario EPDS con Contención Inmediata

**Files:**
- Create: `mobile/lib/features/postpartum/domain/entities/postpartum_entities.dart`
- Create: `mobile/lib/features/postpartum/data/postpartum_repository_impl.dart`
- Create: `mobile/lib/features/postpartum/presentation/pages/postpartum_recovery_page.dart`
- Create: `mobile/lib/features/postpartum/presentation/pages/lactation_and_milk_bank_page.dart`
- Create: `mobile/lib/features/postpartum/presentation/pages/epds_mental_health_page.dart`
- Modify: `mobile/lib/core/database/app_database.dart`
- Modify: `mobile/lib/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart`
- Test: `mobile/test/features/postpartum/epds_and_lactation_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `SyncCoordinator`, `activeUserProfileProvider`
- Produces: Experiencia móvil completa *Offline-First* de Etapa 5

- [ ] **Step 1: Escribir tests en Flutter verificando: evaluación offline inmediata de EPDS mostrando tarjeta prioritaria de crisis si el ítem 10 `> 0`, sugerencia de último pecho ofrecido en lactancia y alertas de caducidad próxima en banco de leche**
- [ ] **Step 2: Ejecutar `flutter test` y confirmar fallo**
  - Run: `cd mobile && flutter test test/features/postpartum`
  - Expected: FAIL
- [ ] **Step 3: Implementar tablas Drift de posparto, calculador local EPDS espejo, UI ergonómica de una mano para lactancia y páginas de recuperación puerperal**
- [ ] **Step 4: Ejecutar `build_runner`, `flutter analyze` y `flutter test`**
  - Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-infos && flutter test`
  - Expected: PASS
- [ ] **Step 5: Commits finales y cierre de Fase 07**
  - `git add mobile`
  - `git commit -m "feat(mobile-ui): add fourth-trimester recovery tracker, one-hand lactation timer, and EPDS screening"`
  - `git add docs/phases/phase-07-postpartum-lactation-mental-health.md docs/phases/README.md`
  - `git commit -m "docs(plan): mark phase 07 tasks completed"`
