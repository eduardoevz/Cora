# Fase 13 — Sistema de Diseño Cora v2, Google Stitch (`DESIGN.md`), Tokens Visuales y Componentes Base

**Fecha de cierre:** 2026-11-21  
**Estado:** ✅ Completada (CI/CD 100% en verde — Inicio de evolución `Cora v2.0`)

---

## 1. Resumen Ejecutivo de la Fase

En la **Fase 13** extendimos la hoja de ruta oficial de **Cora** con las **Fases 13 a 16** y establecimos los cimientos visuales del **Sistema de Diseño Cora v2.0** con apoyo directo de **Google Stitch** (`https://stitch.google.com/projects/6856994269909508525`):

1. **Extensión del Plan Maestro (`docs/phases/phase-13` a `phase-16`):** Se crearon los 4 documentos detallados de implementación y se actualizó `docs/phases/README.md` con el nuevo grafo de dependencias para cubrir el sistema de diseño, el onboarding de últimos 2 periodos, el calendario menstrual interactivo de 7 etapas y el rediseño limpio del Home con menú lateral desplegable.
2. **Especificación Semántica `docs/DESIGN.md` + Exploración Visual en Google Stitch:** Se redactó `docs/DESIGN.md` bajo la skill `stitch-design-taste` (*Warm Botanical Health Editorial*) y se validó en vivo en **Google Stitch** (`projects/6856994269909508525`) generando las vistas de referencia de **Cora - Inicio** y **Cora - Calendario** (paleta marfil cálido `#FBF8F6`, tarjetas puras `#FFFFFF`, arena suave `#F4ECE8`, acento único rosa terracota `#B33A63` y codificación cromática + estructural de las 4 fases).
3. **Tokens de Color (`CoraColorTokens`) y `CoraTheme` v2 con Calibración WCAG AA/AAA:** Se actualizó `mobile/lib/core/theme/cora_theme.dart` añadiendo la extensión `ThemeExtension<CoraColorTokens>` para las 5 fases del ciclo y alertas clínicas, validada matemáticamente con pruebas de ratio de contraste (`>= 4.5:1` en modo estándar y `>= 7:1` + objetivos táctiles `>= 56dp` en `CoraTheme.highLegibility()`).
4. **Biblioteca de Primitivas UI Reutilizables (`cora_design_components.dart`):** Se construyeron los componentes base (`CoraSurfaceCard`, `CoraPhasePill`, `CoraSectionLabel`, `CoraPrimaryActionButton`, `CoraInfoCallout` y `CoraMetricTile`) preparados para escalado `TextScaler.linear(2.0)` sin overflow y funcionamiento 100% *Offline-First*.

---

## 2. Arquitectura, Módulos y Archivos Implementados

### Planificación y Diseño (`docs/`)
- `docs/phases/README.md`: Extensión de la hoja de ruta oficial a 16 fases y actualización del grafo Mermaid.
- `docs/phases/phase-13-design-system-and-stitch.md` … `phase-16-home-ux-redesign-drawer-and-qa.md`: Planes detallados tarea por tarea con TDD y reglas clínicas.
- `docs/DESIGN.md`: Sistema de diseño semántico Cora v2.0 con tokens exactos, reglas tipográficas, anti-patrones y notas verificadas de la sesión en Google Stitch (`projects/6856994269909508525`).

### Mobile Theme & Primitivas (`mobile/lib/core/theme/`)
- `mobile/lib/core/theme/cora_theme.dart`:
  - `CoraPhaseColorPair` y `CoraColorTokens` (`ThemeExtension<CoraColorTokens>`) con modos `standard` y `highLegibility`, `phaseColors(phaseKey)`, `copyWith` y `lerp`.
  - Actualización integral de `CoraTheme.standard()` y `CoraTheme.highLegibility()` (`scaffoldBackgroundColor`, `appBarTheme`, `drawerTheme`, `cardTheme`, `inputDecorationTheme`, `filledButtonTheme`, `elevatedButtonTheme`).
- `mobile/lib/core/theme/cora_design_components.dart`:
  - `CoraSurfaceCard`, `CoraPhasePill`, `CoraSectionLabel`, `CoraPrimaryActionButton`, `CoraInfoCallout` y `CoraMetricTile`.

### Pruebas (`mobile/test/core/`)
- `mobile/test/core/cora_theme_v2_test.dart`: Pruebas unitarias de contraste WCAG 2.1 (`AA >= 4.5:1` y `AAA >= 7:1`), lookups de fase, `copyWith`/`lerp` y widget tests de todas las primitivas bajo `TextScaler.linear(2.0)` y tema `highLegibility()`.

---

## 3. Decisiones Técnicas y Reglas Clínicas Aplicadas

1. **Contraste Calibrado Matemáticamente (WCAG AA y AAA):** Durante el ciclo TDD se calibraron los tonos semánticos de fase (`menstrual #BD2E4E`, `follicular #9E531E`, `ovulatory #1A6E5B`, `luteal #5B457E`, `hormonal #35566E`, `alertPreventive #9A4407`) para garantizar `>= 4.5:1` sobre sus superficies tintadas en modo estándar y `>= 7:1` en `highLegibility()` para la etapa `senior_vitality`, eliminando `#000000` puro en el modo estándar.
2. **Doble Codificación Visual (Color + Forma/Ícono):** Todas las primitivas (`CoraPhasePill`, `CoraInfoCallout`, `CoraMetricTile`) combinan color semántico con borde, ícono y texto explícito para garantizar accesibilidad a usuarias con daltonismo.
3. **100% *Offline-First* y Cero Regresiones:** Se conservaron todas las constantes públicas anteriores de `CoraTheme` (`primaryColor`, `secondaryColor`, `surfaceColor`, `textColor`, `highLegibilityPrimary`) y se evitó introducir dependencias de fuentes remotas obligatorias, manteniendo intactas las 89 pruebas previas más 6 pruebas nuevas (`95` totales).

---

## 4. Pruebas Ejecutadas y Validación CI/CD

- **Formato y Análisis Estático Mobile:**
  - `dart format --output=none --set-exit-if-changed .` → `Formatted 125 files (0 changed)`
  - `flutter analyze --fatal-infos` → `No issues found!`
- **Pruebas Unitarias, Widgets y Accesibilidad WCAG:**
  - `flutter test` → **`+95: All tests passed!`** (incluyendo `cora_theme_v2_test.dart`, `theme_accessibility_test.dart` y `wcag_all_stages_audit_test.dart` en las 7 etapas bajo `TextScaler.linear(2.0)`).
- **GitHub Actions CI/CD (commit `e229612` en `main`):**
  - `Security & OpenAPI Contract Verification` (`44984645423`): **`success`** (`14s`)
  - `Mobile CI` (`44984645411`): **`success`** (`2m22s`)

---

## 5. Secuencia de Commits Realizados

1. `5c01397` — `docs(plan): extend master roadmap with phases 13-16 for Stitch design, menstrual calendar, and home UX`
2. `030a432` — `docs(specs): create Cora v2 semantic DESIGN.md with Google Stitch guidance`
3. `0b9a3e1` — `feat(mobile-ui): upgrade CoraTheme with v2 editorial palette and semantic cycle tokens`
4. `90f61b8` — `feat(mobile-ui): add reusable Cora v2 editorial surface, badge, and callout components`
5. `e229612` — `docs(plan): mark completed tasks in phase-13 design system plan`
6. *(Cierre)* — `docs(documentacion): add phase-13 completion report in documentacion/`

---

## 6. Estado para la Siguiente Fase (Fase 14)

Quedan completamente listos para consumirse en la **Fase 14** (`phase-14-onboarding-menstrual-baseline-and-engine.md`):
- La especificación `docs/DESIGN.md` alineada con Google Stitch.
- `CoraTheme.tokensOf(context)` con colores semánticos de fase (`menstrual`, `follicular`, `ovulatory`, `luteal`, `hormonal`) y modo `highLegibility()`.
- Las primitivas `CoraSurfaceCard`, `CoraPhasePill`, `CoraSectionLabel`, `CoraPrimaryActionButton`, `CoraInfoCallout` y `CoraMetricTile` para construir el selector interactivo de los **últimos 2 periodos** en Onboarding, el **Calendario Menstrual Interactivo** (Fase 15) y el **Home limpio + `CoraNavigationDrawer`** (Fase 16).
