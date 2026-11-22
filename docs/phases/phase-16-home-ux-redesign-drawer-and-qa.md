# Fase 16 — Rediseño UX/UI del Home Principal, Menú Desplegable Lateral (`NavigationDrawer`), QA Android Studio y Release v2.0

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rediseñar completamente la pantalla principal (`DynamicHomeDashboardPage`) aplicando principios modernos de UX/UI y `docs/DESIGN.md` para dejarla limpia, serena y enfocada en lo más relevante del día (ciclo actual, predicción de periodo y ovulación, tira semanal conectada al calendario completo e información educativa sobre el periodo/fase actual), trasladando los módulos secundarios a un **menú lateral desplegable (`CoraNavigationDrawer`)** bien categorizado, y certificar la experiencia completa v2.0 en Android Studio (`Pixel_10_Pro`), Render y GitHub Actions CI.

**Architecture:** `DynamicHomeDashboardPage` utiliza un `Scaffold` con `drawer: CoraNavigationDrawer(...)` y un cuerpo respirable compuesto por 4 bloques modulares (`HomeCycleHeroCard`, `HomeWeekCalendarStrip`, `HomePhaseEducationCard` y alertas/acceso contextual de etapa), eliminando la grilla saturada de 8 accesos directos y manteniendo compatibilidad de accesibilidad WCAG `2.0x` en las 7 etapas biológicas.

**Tech Stack:** Flutter Material 3, Riverpod, Drift SQLite, Android Studio Emulator (`emulator-5554`), Render Production Backend, Firebase Auth real (`cora-5d341`), GitHub Actions CI.

**Spec:** `docs/SPECS.MD`, `docs/DESIGN.md`, `.agents/rules/05-mobile-flutter-offline-first.md`, `.agents/rules/07-testing-and-cicd.md`.

## Global Constraints

- El Home principal debe permanecer despejado: máximo 1 CTA primario en el Hero, sin grillas de 8 módulos amontonados en el body principal.
- Todas las funcionalidades existentes de Cora (Bienestar Diario, Pastillero Virtual, Carpeta Clínica, Doctor-Ready PDF, Asistente Cora RAG, Biblioteca Clínica, Modo Acompañante, Hubs por etapa, Módulos a la Carta, Cambio de Etapa y Privacidad/GDPR/Modo Discreto) siguen accesibles en 1–2 toques desde `CoraNavigationDrawer`.
- Cero `RenderFlex overflow` en las 7 etapas con `TextScaler.linear(2.0)` y tema `highLegibility()` en `senior_vitality`.

---

### Task 1: Menú Lateral Desplegable (`CoraNavigationDrawer`) y Bloques del Home Limpio (TDD)

**Files:**
- Create: `mobile/lib/features/dashboard/presentation/widgets/cora_navigation_drawer.dart`
- Create: `mobile/lib/features/dashboard/presentation/widgets/home_cycle_hero_card.dart`
- Create: `mobile/lib/features/dashboard/presentation/widgets/home_week_calendar_strip.dart`
- Create: `mobile/lib/features/dashboard/presentation/widgets/home_phase_education_card.dart`
- Modify: `mobile/lib/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart`
- Test: `mobile/test/features/dashboard/dynamic_dashboard_test.dart`
- Test: `mobile/test/accessibility/wcag_all_stages_audit_test.dart`

- [ ] **Step 1: Escribir/actualizar widget tests del Home v2 y `CoraNavigationDrawer` (verificando Hero de ciclo/ovulación/periodo en etapas menstruales, adaptación en embarazo/posparto/menopausia/plenitud, tira semanal -> `MenstrualCalendarPage`, tarjeta educativa del periodo, navegación por Drawer a todos los módulos y auditoría WCAG `2.0x` en las 7 etapas)**
- [ ] **Step 2: Ejecutar `flutter test` y verificar fallo inicial (Red)**
- [ ] **Step 3: Implementar `CoraNavigationDrawer`, `HomeCycleHeroCard`, `HomeWeekCalendarStrip`, `HomePhaseEducationCard` y refactorizar `DynamicHomeDashboardPage`**
- [ ] **Step 4: Actualizar `test/core/cora_app_boot_test.dart`, `test/core/firebase_auth_flow_test.dart`, `test/e2e/longitudinal_journey_e2e_test.dart` e `integration_test/app_full_flow_e2e_test.dart` para el nuevo flujo de Onboarding + Home + Drawer + Calendario Menstrual**
- [ ] **Step 5: Ejecutar `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos` y `flutter test` en verde (Green)**
- [ ] **Step 6: Commits atómicos (`feat(mobile-ui): ...` y `test(mobile): ...`)**

---

### Task 2: QA Integral en Android Studio (`emulator-5554`), APK Release v2.0 y Verificación en Vivo contra Render

**Files:**
- Build artifact (local gitignored): `mobile/build/app/outputs/flutter-apk/app-release.apk`

- [ ] **Step 1: Ejecutar `flutter test integration_test/app_full_flow_e2e_test.dart -d emulator-5554` y verificar pase al 100%**
- [ ] **Step 2: Compilar el APK release firmado (`flutter build apk --release`), instalar en `emulator-5554` y probar flujo real completo contra Firebase Auth (`cora-5d341`) + Render en producción (Onboarding con últimos 2 periodos → Home limpio → Calendario Menstrual interactivo → Drawer lateral → Cambio de etapa → Purga GDPR → 0 errores en `logcat`)**
- [ ] **Step 3: Verificar `alembic upgrade head` y endpoints v2 (`/api/v1/cycles/calendar`, `/api/v1/identity/onboarding`) en producción Render**

---

### Task 3: Cierre de Fase 16, Documentación, Walkthrough y Verificación de CI en Verde

**Files:**
- Modify: `docs/phases/phase-16-home-ux-redesign-drawer-and-qa.md`
- Modify: `docs/phases/README.md`
- Create: `documentacion/fase-16-rediseno-home-drawer-y-release-v2.md`
- Modify: `documentacion/README.md`
- Modify: `README.md`

- [ ] **Step 1: Marcar checkboxes completados en `phase-16-home-ux-redesign-drawer-and-qa.md` y actualizar `docs/phases/README.md` y `README.md`**
- [ ] **Step 2: Push a `origin/main` y monitorear `gh run list` / `gh run watch` hasta certificar `Backend CI`, `Mobile CI` y `Security & OpenAPI Contract Verification` en `success`**
- [ ] **Step 3: Crear reporte `documentacion/fase-16-rediseno-home-drawer-y-release-v2.md`, actualizar `documentacion/README.md`, hacer commit, push y re-verificar CI en verde**
