# Fase 13 — Sistema de Diseño Cora v2, Google Stitch (`DESIGN.md`), Tokens Visuales y Componentes Base

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Definir y codificar el **Sistema de Diseño Cora v2.0** con apoyo de **Google Stitch** (`labs.google/stitch` + `stitch-design-taste`), estableciendo `docs/DESIGN.md` como fuente de verdad visual, renovando `CoraTheme` con una paleta cálida editorial libre de clichés genéricos, tipografía *Offline-First*, tokens semánticos para las 4 fases del ciclo y las 7 etapas de vida, y una librería base de componentes accesibles (`WCAG AA` estándar y `WCAG AAA >= 7:1` en `senior_vitality`).

**Architecture:** `docs/DESIGN.md` documenta la atmósfera visual, calibración de color, escala tipográfica, reglas de layout, micro-interacciones y anti-patrones para Google Stitch y Flutter. En `mobile/lib/core/theme/`, `CoraColorTokens` (`ThemeExtension`) expone colores semánticos de fases menstruales y superficies, mientras `cora_design_components.dart` centraliza las primitivas UI (`CoraSurfaceCard`, `CoraPhasePill`, `CoraSectionLabel`, `CoraPrimaryActionButton`, `CoraInfoCallout`) consumidas por las Fases 14–16.

**Tech Stack:** Google Stitch (`labs.google/stitch`), `stitch-design-taste`, Flutter Material 3, `ThemeExtension`, fuentes empaquetadas *Offline-First*, Widget Tests WCAG (`TextScaler.linear(2.0)`).

**Spec:** `docs/SPECS.MD`, `.agents/rules/05-mobile-flutter-offline-first.md`, `.agents/rules/07-testing-and-cicd.md`.

## Global Constraints

- Cero estética genérica IA (sin neones, sin morados/azules fosforescentes, sin `#000000` puro en modo estándar, sin emojis en componentes UI ni textos clínicos).
- Cumplimiento estricto de accesibilidad: contraste mínimo `>= 4.5:1` en modo estándar (`WCAG AA`) y `>= 7:1` en `CoraTheme.highLegibility()` (`WCAG AAA`), objetivos táctiles `>= 48x48 dp` (`>= 56x56 dp` en `senior_vitality`), sin `RenderFlex overflow` bajo `TextScaler.linear(2.0)`.
- Arquitectura *Offline-First*: el tema y los componentes jamás requieren conexión a red para renderizar tipografía o estilos.

## Review Focus

1. **Coherencia con Google Stitch:** `docs/DESIGN.md` describe con códigos hexadecimales exactos, roles funcionales y anti-patrones la estética aprobada con Google Stitch.
2. **Contraste de tokens de fase:** Todos los badges/celdas de fase (`Menstrual`, `Folicular`, `Ovulatoria/Fértil`, `Lútea`, `Gestión Hormonal`) mantienen contraste legible tanto sobre superficies claras como en modo `highLegibility()`.
3. **Compatibilidad hacia atrás:** Ningún test existente de las Fases 01–12 se rompe al actualizar `CoraTheme`.

---

### Task 1: Especificación Semántica `docs/DESIGN.md` y Sesión de Diseño en Google Stitch

**Files:**
- Create: `docs/DESIGN.md`

- [x] **Step 1: Redactar `docs/DESIGN.md` siguiendo `stitch-design-taste` (atmósfera *Warm Botanical Health Editorial*, paleta calibrada, tokens de fases menstruales, tipografía, reglas de componentes, layout mobile-first, movimiento y anti-patrones)**
- [x] **Step 2: Conectar con Google Stitch (`https://labs.google/stitch`) mediante el navegador integrado, enviar el brief de Cora v2.0 (Home limpio + Menú lateral + Calendario Menstrual + Onboarding de últimos 2 periodos) y capturar/registrar los lineamientos y referencias generadas por Stitch en `docs/DESIGN.md`**
- [x] **Step 3: Commit**
  - `git add docs/DESIGN.md`
  - `git commit -m "docs(specs): create Cora v2 semantic DESIGN.md with Google Stitch guidance"`

---

### Task 2: Tokens de Color (`CoraColorTokens`), Tipografía y `CoraTheme` v2 (TDD)

**Files:**
- Modify: `mobile/lib/core/theme/cora_theme.dart`
- Modify: `mobile/pubspec.yaml` (si se empaquetan assets/fuentes locales)
- Test: `mobile/test/core/cora_theme_v2_test.dart`

- [x] **Step 1: Escribir tests unitarios y de contraste WCAG (`AA >= 4.5:1` en estándar, `AAA >= 7:1` en `highLegibility`) para `CoraTheme.standard()`, `CoraTheme.highLegibility()` y `CoraColorTokens` (fases menstrual, folicular, ovulatoria, lútea, hormonal)**
- [x] **Step 2: Ejecutar `flutter test test/core/cora_theme_v2_test.dart` y verificar fallo inicial (Red)**
- [x] **Step 3: Implementar `CoraColorTokens` (`ThemeExtension<CoraColorTokens>`) y actualizar `CoraTheme` con la paleta, tipografía, formas, inputs, botones y AppBar definidos en `docs/DESIGN.md`**
- [x] **Step 4: Verificar `flutter analyze --fatal-infos` y `flutter test` en verde (Green)**
- [x] **Step 5: Commit**
  - `git add mobile/lib/core/theme/cora_theme.dart mobile/test/core/cora_theme_v2_test.dart`
  - `git commit -m "feat(mobile-ui): upgrade CoraTheme with v2 editorial palette and semantic cycle tokens"`

---

### Task 3: Primitivas de Componentes Cora v2 (`cora_design_components.dart`) (TDD)

**Files:**
- Create: `mobile/lib/core/theme/cora_design_components.dart`
- Modify: `mobile/test/core/cora_theme_v2_test.dart`

- [x] **Step 1: Escribir widget tests para `CoraSurfaceCard`, `CoraPhasePill`, `CoraSectionLabel`, `CoraPrimaryActionButton`, `CoraInfoCallout` verificando renderizado limpio, semántica accesible, áreas táctiles `>= 48dp` (`>= 56dp` en `highLegibility`) y cero overflow a `TextScaler.linear(2.0)`**
- [x] **Step 2: Ejecutar `flutter test test/core/cora_theme_v2_test.dart` y verificar fallo inicial (Red)**
- [x] **Step 3: Implementar `mobile/lib/core/theme/cora_design_components.dart`**
- [x] **Step 4: Ejecutar `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos` y toda la suite `flutter test` para certificar 0 regresiones**
- [x] **Step 5: Commit**
  - `git add mobile/lib/core/theme/cora_design_components.dart mobile/test/core/cora_theme_v2_test.dart`
  - `git commit -m "feat(mobile-ui): add reusable Cora v2 editorial surface, badge, and callout components"`

---

### Task 4: Cierre de Fase 13, Documentación y Verificación de CI en Verde

**Files:**
- Modify: `docs/phases/phase-13-design-system-and-stitch.md`
- Modify: `docs/phases/README.md`
- Create: `documentacion/fase-13-sistema-de-diseno-y-stitch.md`
- Modify: `documentacion/README.md`

- [x] **Step 1: Marcar checkboxes completados en `phase-13-design-system-and-stitch.md` y actualizar `docs/phases/README.md`**
- [x] **Step 2: Hacer push a `origin/main` y verificar `gh run list` / `gh run watch` hasta que todos los workflows aplicables culminen en `success`**
- [x] **Step 3: Crear `documentacion/fase-13-sistema-de-diseno-y-stitch.md`, actualizar `documentacion/README.md`, hacer commit (`docs(documentacion): add phase-13 completion report in documentacion/`), push y re-verificar CI en verde**
