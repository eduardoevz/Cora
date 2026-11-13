# Bitácora de Implementación — Paso 4: Andamiaje Nativo, Automatización de Firma, Empaquetado y Compilación Móvil

**Fecha de ejecución:** 2026-11-13  
**Estado:** ✅ Completado

---

## 1. Resumen de lo Implementado

En este cuarto paso se configuró la infraestructura nativa y de compilación de **Cora Mobile** para su empaquetado release destinado a **Google Play Store** y **Apple App Store**:

1. **Andamiaje de Plataformas Nativas (`android/` e `ios/`):**
   - Configuración reproducible bajo el identificador único canónico `com.cora.health.mobile`.
2. **Configuración Nativa para Android (`mobile/android/`):**
   - **Permisos en `AndroidManifest.xml`:** Declaración de `INTERNET`, `USE_BIOMETRIC` y `USE_FINGERPRINT` para el Modo Discreto y sincronización Offline-First. Etiqueta pública de la aplicación `android:label="Cora"`.
   - **Configuración de Gradle (`build.gradle.kts`):** Carga dinámica de credenciales release desde `key.properties` si existe, con fallback a debug en desarrollo local/CI.
   - **Plantilla de Firma (`mobile/android/key.properties.example`):** Instrucciones para la generación y resguardo del Keystore de Google Play con `keytool`.
   - **Reglas de Proguard (`mobile/android/app/proguard-rules.pro`):** Protección y conservación de bindings C de SQLite3, clases de Drift y modelos de serialización.
3. **Configuración Nativa para iOS (`mobile/ios/`):**
   - **`Info.plist`:** `CFBundleDisplayName` y `CFBundleName` configurados como `"Cora"`. Justificación de uso de biometría en `NSFaceIDUsageDescription` en español e inglés.
   - **Apple Privacy Manifest (`PrivacyInfo.xcprivacy`):** Manifiesto oficial conforme a la política obligatoria de Apple para App Store (cero tracking de terceros y justificación de APIs de UserDefaults y FileTimestamp).
4. **Pipeline CI/CD Móvil en GitHub Actions (`.github/workflows/ci-cd-mobile-build.yml`):**
   - Automatización de resolución de dependencias, verificación estática (`flutter analyze --fatal-infos`), tests (`flutter test`) y compilación release de **Android App Bundle (`.aab`)** y **APK universal**, subiéndolos como artefactos descargables.
5. **Scripts de Compilación Local:**
   - `mobile/scripts/build_release_bundles.ps1` (PowerShell para Windows) y `build_release_bundles.sh` (Bash para macOS/Linux).

---

## 2. Archivos Creados y Modificados
- `mobile/android/` (scaffold nativo completo, Gradle, Gradle Wrapper, Manifests)
- `mobile/android/app/src/main/AndroidManifest.xml`
- `mobile/android/app/build.gradle.kts`
- `mobile/android/key.properties.example`
- `mobile/android/app/proguard-rules.pro`
- `mobile/ios/` (scaffold nativo completo, Runner, project.pbxproj, Assets)
- `mobile/ios/Runner/Info.plist`
- `mobile/ios/Runner/PrivacyInfo.xcprivacy`
- `.github/workflows/ci-cd-mobile-build.yml`
- `mobile/scripts/build_release_bundles.ps1`
- `mobile/scripts/build_release_bundles.sh`

---

## 3. Resultados de Pruebas y Linters
- `flutter analyze --fatal-infos`: **No issues found!**
- `flutter test`: **All 84 tests passed!**
