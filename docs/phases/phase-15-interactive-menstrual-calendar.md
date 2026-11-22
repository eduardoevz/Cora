# Fase 15 — Calendario Menstrual Interactivo Diario con Predicciones y Adaptación a las 7 Etapas

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir la pantalla interactiva **`MenstrualCalendarPage`** con cuadrícula mensual táctil, marcadores visuales claros y accesibles (periodo registrado, próximo periodo predicho, ventana fértil, día de ovulación y días con síntomas), panel reactivo de **información diaria** (día del ciclo, fase actual, fertilidad/ovulación, guía educativa del día y síntomas registrados), hoja rápida de registro/edición en cualquier fecha y adaptación completa a las **7 etapas biológicas** de Cora.

**Architecture:** `menstrual_calendar_providers.dart` combina `activeUserProfileProvider` + streams/datos locales de `CycleRepository` + `CycleCalendarEngine` (*Offline-First*) para proyectar instantáneamente cualquier mes sin bloquear la UI. `MenstrualCalendarPage` sigue estrictamente `docs/DESIGN.md` y las primitivas de `CoraTheme` v2, integrándose con `CycleMonitorPage` (cuya rueda `CycleWheelPainter` pasa a usar la duración real del ciclo).

**Tech Stack:** Flutter Material 3, Riverpod, Drift SQLite, `CoraColorTokens`, Widget Tests WCAG (`TextScaler.linear(2.0)`).

**Spec:** `docs/SPECS.MD`, `docs/DESIGN.md`, `.agents/rules/03-clinical-tdd-and-safety.md`, `.agents/rules/05-mobile-flutter-offline-first.md`.

## Global Constraints

- Toda diferenciación visual del calendario debe usar **color + forma/borde/icono** (nunca depender únicamente del color para daltonismo y WCAG).
- Al registrar o editar sangrado en cualquier día del calendario, las predicciones de próximo periodo, ventana fértil, ovulación y fase se recalculan instantáneamente desde Drift y encolan mutación idempotente en `SyncOutbox`.
- Adaptación obligatoria por etapa:
  - `adolescence`: tolerancia FIGO `21–45d`, tono pedagógico, enlace a guía y PIN.
  - `regular_adult`: vista completa de 4 fases, ovulación, próximo periodo y alertas FIGO.
  - `conception_search`: énfasis en ventana fértil, ovulación y acceso directo a BBT/LH/moco cervical.
  - `pregnancy`: modo gestacional (semanas, citas prenatales, sin predicción menstrual).
  - `postpartum`: modo puerperio (loquios, lactancia, recuperación y EPDS).
  - `perimenopause`: modo STRAW+10 (intervalos irregulares `>= 7d`, días sin sangrado, sofocos).
  - `senior_vitality`: calendario preventivo de salud/chequeos con tema **Alta Legibilidad (WCAG AAA)** y objetivos táctiles `>= 56dp`.

---

### Task 1: Providers Reactivos del Calendario Mensual y Estado Diario (TDD)

**Files:**
- Create: `mobile/lib/features/cycle/presentation/providers/menstrual_calendar_providers.dart`
- Test: `mobile/test/features/cycle/menstrual_calendar_providers_test.dart`

- [x] **Step 1: Escribir tests unitarios de providers (cambio de mes, selección de día, recálculo inmediato tras registrar sangrado o síntomas)**
- [x] **Step 2: Implementar `menstrual_calendar_providers.dart`**
- [x] **Step 3: Verificar tests en verde y commit**
  - `git commit -m "feat(mobile-ui): add reactive Riverpod providers for monthly menstrual calendar projection"`

---

### Task 2: Widgets del Calendario Mensual Interactivo y Panel de Detalle Diario (TDD)

**Files:**
- Create: `mobile/lib/features/cycle/presentation/widgets/menstrual_month_grid.dart`
- Create: `mobile/lib/features/cycle/presentation/widgets/calendar_day_detail_panel.dart`
- Create: `mobile/lib/features/cycle/presentation/widgets/calendar_day_log_sheet.dart`
- Create: `mobile/lib/features/cycle/presentation/pages/menstrual_calendar_page.dart`
- Modify: `mobile/lib/features/cycle/presentation/pages/cycle_monitor_page.dart`
- Test: `mobile/test/features/cycle/menstrual_calendar_page_test.dart`

- [x] **Step 1: Escribir widget tests completos para `MenstrualCalendarPage`: visualización de últimos 2 periodos + predicción próximo periodo + ovulación + ventana fértil, navegación de meses, tap en un día y detalle diario, registro de sangrado/síntomas desde el calendario con recálculo en vivo, adaptación de las 7 etapas y prueba WCAG `TextScaler.linear(2.0)`**
- [x] **Step 2: Ejecutar `flutter test test/features/cycle/menstrual_calendar_page_test.dart` y verificar fallo inicial (Red)**
- [x] **Step 3: Implementar `MenstrualMonthGrid`, `CalendarDayDetailPanel`, `CalendarDayLogSheet`, `MenstrualCalendarPage` y enlazarla con `CycleMonitorPage` (incluyendo `totalDays` dinámico en `CycleWheelPainter`)**
- [x] **Step 4: Ejecutar `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos` y `flutter test` completo en verde (Green)**
- [x] **Step 5: Commit**
  - `git commit -m "feat(mobile-ui): build interactive MenstrualCalendarPage with daily predictions and 7-stage adaptation"`

---

### Task 3: Cierre de Fase 15, Documentación y Verificación de CI en Verde

**Files:**
- Modify: `docs/phases/phase-15-interactive-menstrual-calendar.md`
- Modify: `docs/phases/README.md`
- Create: `documentacion/fase-15-calendario-menstrual-interactivo.md`
- Modify: `documentacion/README.md`

- [ ] **Step 1: Marcar checkboxes y actualizar `docs/phases/README.md`**
- [ ] **Step 2: Push a `origin/main` y verificar `Mobile CI` y `Security & OpenAPI Contract Verification` en verde (`success`)**
- [ ] **Step 3: Crear reporte `documentacion/fase-15-calendario-menstrual-interactivo.md`, actualizar índice, commit, push y re-verificar CI**
