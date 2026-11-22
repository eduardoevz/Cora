# Release Cora v3.0.0 — Google Stitch Faithful Edition

**Fecha de Lanzamiento:** 2026-11-22  
**Versión:** `3.0.0+3`  
**Rama Base:** `main` (merge `--no-ff` desde `feat/stitch-faithful-design`)  
**Tag de Respaldo Pre-Merge:** `pre-v3-merge` (y `v2.0.0` intacto)

---

## 1. Novedades de Cora v3.0.0

1. **Tipografía Editorial 100% *Offline-First*:**
   - Integración local de las fuentes oficiales **Outfit** (encabezados y cifras biométricas tabulares) y **Plus Jakarta Sans** (cuerpo clínico y etiquetas) en `mobile/assets/fonts/`.
   - Aplicadas tanto al tema estándar (`CoraTheme.standard()`) como al tema de alta legibilidad WCAG AAA (`CoraTheme.highLegibility()`).
2. **Activos Botánicos Editoriales Locales (`mobile/assets/images/`):**
   - 7 ilustraciones y fotografías botánicas empaquetadas en el binario para funcionar con 0% de conectividad en Bienvenida, Home, Calibración de Onboarding, Monitoreo del Ciclo, Embarazo, Perimenopausia y Plenitud Sénior.
3. **Adaptación Fiel de los 31 Diseños de Google Stitch:**
   - Nuevos tokens tonales (`surfaceContainer`, `surfaceContainerHigh`, `surfaceContainerHighest`, `outlineVariant`, `primaryFixed`, `tertiaryFixed`) y componentes compartidos (`CoraBrandEmblem`, `CoraTonalStepProgressBar`, `CoraEditorialImageBanner`, `CoraMetricProgressRow`, `CoraStitchBottomNav`).
   - Actualización visual fiel de las `30` pantallas `*_page.dart` y `CoraNavigationDrawer` manteniendo intacta toda la lógica clínica (FIGO, ACOG, STRAW+10, EPDS, BBT 3-sobre-6), persistencia local Drift SQLite, `SyncOutboxService` y objetivos de accesibilidad WCAG AA/AAA (`TextScaler.linear(2.0)` sin desbordamientos).

---

## 2. Verificación y Calidad

| Dimensión | Resultado |
| :--- | :--- |
| **`dart format --output=none --set-exit-if-changed .`** | **`144` archivos formateados (`0` cambios)** |
| **`flutter analyze --fatal-infos`** | **`No issues found!`** |
| **`flutter test`** | **`121/121` pruebas aprobadas** |
| **Suite E2E Base (`Pixel_10_Pro`)** | **`app_full_flow_e2e_test.dart` (`01:11 +1 passed`)** |
| **Suite E2E Completa 7 Etapas (`Pixel_10_Pro`)** | **`all_features_production_e2e_test.dart` (`01:56 +1 passed`)** |
| **APK Release Universal (`cora-v3.0.0-release.apk`)** | **`71.4 MB` (`74,878,720` bytes)** |

---

## 3. Puntos de Restauración (*Rollback* Seguro)

El historial de `main` se integró mediante `--no-ff` preservando cada commit atómico. Para volver al estado exacto previo a `v3.0.0`:
- Ver el estado anterior en `pre-v3-merge` o `v2.0.0`: `git checkout pre-v3-merge`
- Revertir el merge en `main` sin reescribir historia: `git revert -m 1 <merge_commit_sha>`
