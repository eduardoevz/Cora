# Fase 15 — Calendario Menstrual Interactivo Diario con Predicciones y Adaptación a las 7 Etapas

**Fecha de cierre:** 2026-11-21  
**Estado:** ✅ Completada (CI/CD 100% en verde — `Mobile CI` y `Security & OpenAPI Contract Verification`)

---

## 1. Resumen Ejecutivo de la Fase

En la **Fase 15** construimos el **Calendario Menstrual Interactivo Diario (`MenstrualCalendarPage`)** de **Cora v2.0**, alineado con el sistema de diseño *Warm Botanical Health Editorial* (`docs/DESIGN.md`) y conectado en tiempo real al motor *Offline-First* `CycleCalendarEngine` y **Drift SQLite**:

1. **Providers Reactivos del Calendario Mensual y Estado Diario (`menstrual_calendar_providers.dart`):** Orquestación reactiva en **Riverpod** que combina `activeUserProfileProvider`, historial de ciclos y registros diarios de síntomas en Drift SQLite para proyectar cualquier mes instantáneamente sin bloquear la interfaz ni depender de conectividad de red.
2. **Cuadrícula Mensual Accesible con Codificación Visual Dual (`MenstrualMonthGrid`):** Cuadrícula de 7 columnas (`L M X J V S D`) con cifras tabulares (`FontFeature.tabularFigures()`), áreas táctiles mínimas `>= 48x48dp` (`>= 56x56dp` en modo Alta Legibilidad WCAG AAA) y diferenciación por **color + forma/borde/icono**:
   - **Periodo registrado (`recordedPeriod`):** Relleno sólido `tokens.menstrual` con texto blanco en negrita e icono de gota (`Icons.water_drop_rounded`).
   - **Próximo periodo predicho (`predictedPeriod`):** Contorno discontinuo (`CustomPainter` de trazos) en `tokens.menstrual` sobre superficie `tokens.menstrualSurface`.
   - **Ventana fértil (`fertileWindow`):** Superficie salvia `tokens.ovulatorySurface` con borde continuo `tokens.ovulatory` e indicador cuadrado.
   - **Día estimado de ovulación (`predictedOvulation`):** Doble anillo concéntrico en `tokens.ovulatory` con punto central.
   - **Manchado (`spotting`):** Contorno discontinuo ámbar con icono `Icons.grain_rounded`.
   - **Síntomas registrados (`hasLoggedSymptoms`):** Micro-indicador circular inferior de `5dp`.
3. **Panel Reactivo de Detalle Diario (`CalendarDayDetailPanel`) y Hoja de Registro en Cualquier Fecha (`CalendarDayLogSheet`):** Al tocar cualquier día del calendario, el panel `DETALLE DEL REGISTRO` muestra día del ciclo, pill de fase biológica, probabilidad fértil, guía educativa contextual, chips de biomarcadores registrados y notas clínicas, permitiendo registrar o editar sangrado y síntomas en cualquier fecha con recálculo inmediato en Drift y encolado idempotente en `SyncOutbox`.
4. **Adaptación Integral a las 7 Etapas Biológicas y `CycleMonitorPage`:** El calendario adapta su modo visual, tarjetas de contexto y accesos directos a `adolescence`, `regular_adult`, `conception_search`, `pregnancy` (sin predicción menstrual), `postpartum`, `perimenopause` (STRAW+10) y `senior_vitality` (tema `CoraTheme.highLegibility()` WCAG AAA), mientras que `CycleMonitorPage` actualiza `CycleWheelPainter` para usar `totalDays` dinámico de la usuaria.

---

## 2. Arquitectura, Módulos y Archivos Implementados

### Mobile Flutter *Offline-First* (`mobile/lib/features/cycle/`)
- **Providers Riverpod (`presentation/providers/`):**
  - `mobile/lib/features/cycle/presentation/providers/menstrual_calendar_providers.dart`:
    - `calendarReferenceTodayProvider`: Fecha UTC normalizada de referencia.
    - `selectedCalendarMonthProvider`: Año y mes visibles en el calendario.
    - `selectedCalendarDateProvider`: Día seleccionado activo.
    - `calendarSymptomLogsByDateProvider`: Mapa reactivo `Map<DateTime, CycleSymptomEntity>` indexado por fecha UTC.
    - `activeCalendarMonthProjectionProvider`: Proyección mensual completa `CalendarMonthProjectionEntity` calculada localmente con `CycleCalendarEngine`.
    - `selectedCalendarDayProjectionProvider` y `selectedDaySymptomLogProvider`: Estado derivado del día seleccionado.
    - `MenstrualCalendarController` (`menstrualCalendarControllerProvider`): Acciones `selectDate`, `nextMonth`, `previousMonth`, `goToMonth`, `goToToday` y `saveDayLog`.
- **Widgets y Páginas (`presentation/widgets/` y `presentation/pages/`):**
  - `mobile/lib/features/cycle/presentation/widgets/menstrual_month_grid.dart`: Cuadrícula mensual interactiva, cabecera de navegación de meses, pills de contexto, `_DashedRoundedRectPainter` y leyenda 2x2 accesible.
  - `mobile/lib/features/cycle/presentation/widgets/calendar_day_detail_panel.dart`: Panel `DETALLE DEL REGISTRO` con fase, probabilidad fértil, educación diaria y chips de biomarcadores.
  - `mobile/lib/features/cycle/presentation/widgets/calendar_day_log_sheet.dart`: Hoja modal de registro/edición de sangrado (`none`, `spotting`, `light`, `medium`, `heavy`), dolor pélvico (`0–10`), fatiga (`0–10`), síntomas acompañantes y notas clínicas para cualquier fecha.
  - `mobile/lib/features/cycle/presentation/pages/menstrual_calendar_page.dart`: Pantalla principal del calendario menstrual con tarjetas de predicción y banner adaptativo para las 7 etapas biológicas.
  - `mobile/lib/features/cycle/presentation/pages/cycle_monitor_page.dart`: Integración de `totalDays` real en `CycleWheelPainter` y botón de navegación a `MenstrualCalendarPage`.

### Pruebas Automatizadas (`mobile/test/features/cycle/`)
- `mobile/test/features/cycle/menstrual_calendar_providers_test.dart`: 4 pruebas unitarias de integración con Drift en memoria (`NativeDatabase.memory()`) verificando proyección desde 2 periodos iniciales, cambio de mes y día, recálculo en vivo tras registrar sangrado/síntomas y adaptación de `CalendarDisplayMode` en las 7 etapas.
- `mobile/test/features/cycle/menstrual_calendar_page_test.dart`: 5 widget tests completos verificando marcadores visuales de los 2 periodos iniciales + predicción + ventana fértil + ovulación, navegación entre meses, registro desde `CalendarDayLogSheet`, adaptación en las 7 etapas, conexión con `CycleMonitorPage` (`totalDays: 33`) y auditoría WCAG `TextScaler.linear(2.0)` sin overflow.

---

## 3. Decisiones Técnicas y Reglas Clínicas Aplicadas

1. **Accesibilidad sin Dependencia Exclusiva del Color (WCAG AA/AAA):** Cada categoría clínica del calendario (`recordedPeriod`, `predictedPeriod`, `fertileWindow`, `predictedOvulation`, `spotting`, `hasLoggedSymptoms`) combina token cromático + geometría/borde (`CustomPainter` discontinuo, doble anillo concéntrico, icono de gota o punto inferior) + etiqueta semántica (`Semantics`) para lectores de pantalla.
2. **Recálculo Reactivo Instantáneo *Offline-First*:** Al guardar un registro desde `CalendarDayLogSheet`, `MenstrualCalendarController.saveDayLog` escribe transaccionalmente en Drift (`cycle_symptom_entries` y delimitación de `menstrual_cycle_entries`), encola la mutación idempotente en `sync_outbox` e invalida los providers de calendario y resumen para que todas las predicciones futuras se actualicen en el mismo frame.
3. **Supresión Segura en Etapas No Menstruales:** En `LifeStage.pregnancy` y `LifeStage.seniorVitality`, el calendario oculta los pills de duración de ciclo y las tarjetas de predicción menstrual/ovulatoria, priorizando el contexto obstétrico ACOG o preventivo geriátrico con tema `CoraTheme.highLegibility()`.

---

## 4. Pruebas Ejecutadas y Validación CI/CD

### Verificación Local Completa
- `dart format --output=none --set-exit-if-changed .` → `Formatted 136 files (0 changed)`
- `flutter analyze --fatal-infos` → `No issues found!`
- `flutter test` → **`+112: All tests passed!`**

### GitHub Actions CI/CD (Commit `b46a74f` en `main`)
- **`Security & OpenAPI Contract Verification`** (Run [`44989769406`](https://github.com/eduardoevz/Cora/actions/runs/44989769406)): **`success`** (`18s`) — OpenAPI Drift Check & Gitleaks PHI/Secret Scan en verde.
- **`Mobile CI`** (Run [`44989769598`](https://github.com/eduardoevz/Cora/actions/runs/44989769598)): **`success`** (`2m52s`) — Verificación de integridad Drift (`build_runner`), `flutter analyze` y los 112 tests de Flutter en verde.

---

## 5. Secuencia de Commits Realizados

1. `ca2eef1` — `feat(mobile-ui): add reactive Riverpod providers for monthly menstrual calendar projection`
2. `4efc9b3` — `feat(mobile-ui): build interactive MenstrualCalendarPage with daily predictions and 7-stage adaptation`
3. `b46a74f` — `docs(plan): mark tasks 1-2 completed in phase-15 plan pending CI certification`
4. `9876886` — `docs(plan): mark phase-15 completed after green CI certification`
5. *(Cierre bitácora)* — `docs(documentacion): add phase-15 completion report in documentacion/`

---

## 6. Estado para la Siguiente Fase (Fase 16)

Quedan completamente listos para consumirse en la **Fase 16** (`docs/phases/phase-16-home-ux-redesign-drawer-and-qa.md`):
- La pantalla completa `MenstrualCalendarPage` y los providers `activeCalendarMonthProjectionProvider` / `menstrualCalendarControllerProvider`, listos para enlazarse desde el nuevo `HomeCycleHeroCard`, la tira semanal interactiva `HomeWeekCalendarStrip` y el menú desplegable lateral `CoraNavigationDrawer`.
