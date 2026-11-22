# Auditoría Integral del Sistema y Certificación de Producción — Cora v2.0

**Fecha de Auditoría:** 2026-11-22  
**Versión Evaluada:** `Cora v2.0` (*Warm Botanical Health Editorial — Google Stitch Hybrid*)  
**Estado General:** **APROBADO / LISTO PARA PRODUCCIÓN**

---

## 1. Resumen Ejecutivo

Se ejecutó una auditoría técnica, arquitectónica, clínica, de seguridad y de flujo *End-to-End* (E2E) sobre el monorepo de **Cora** (`backend/` + `mobile/` + `contracts/openapi.json` + `.github/workflows/`).

Durante la auditoría se verificaron y endurecieron los siguientes puntos críticos:
1. **Backend FastAPI Hexagonal:** 9 contextos acotados con **0 violaciones de pureza de dominio**, `269` archivos validados con `ruff`, `253` archivos con `mypy --strict` (`0` errores), `227` pruebas unitarias en verde y `0` deriva en `contracts/openapi.json`.
2. **Seguridad y Privacidad (PHI / PII / IA):** Endurecimiento de política CORS (`cors_allowed_origins` sin combinar `*` con `allow_credentials=True`), cabeceras de seguridad HTTP (`X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `Permissions-Policy`), redacción de trazas en verificación de tokens Firebase (`type(exc).__name__`), **0 fugas de PHI en logs** y **100% llamadas Gemini con `store=False`** y `DeterministicSafetyInterceptor` previo.
3. **Estabilidad Móvil y Eliminación de Pantalla Negra en Emulador:**
   - Se envolvió el contenido de `CoraSurfaceCard` y `CoraBlushInsetBox` en `Material(type: MaterialType.transparency)` para erradicar excepciones de `ListTile`/`SwitchListTile` sobre `DecoratedBox` en las 30 pantallas.
   - Se protegió `CoraRootGate` con `PopScope(canPop: false)` para evitar que el gesto Back de Android o un `pop` adicional vacíe la pila del `Navigator` (causa de pantalla negra).
   - Se añadió el botón **"Continuar en Modo Local (Offline-First)"** en `FirebaseAuthPage` para pruebas manuales inmediatas sin requerir sesión remota de Firebase, y se acotaron las llamadas remotas oportunistas a `4–6s` de timeout para que el fallback *Offline-First* responda sin bloqueos.
   - Se reinstaló el APK real (`lib/main.dart`) tras la ejecución de `integration_test/` para que el emulador nunca quede con el binario de arnés de pruebas instalado.

---

## 2. Resultados por Capa Arquitectónica

### 2.1 Backend (`backend/`)

| Dimensión Auditada | Herramienta / Verificación | Resultado |
| :--- | :--- | :--- |
| **Pureza Hexagonal (`domain/`)** | Escaneo recursivo de imports prohibidos (`fastapi`, `sqlalchemy`, `pydantic`, `httpx`, `boto3`, `weasyprint`, `google.genai`) | **`0` violaciones** en los 9 módulos |
| **Linter y Formato** | `uv run ruff check .` y `uv run ruff format --check .` | **`269` archivos limpios (`0` errores)** |
| **Tipado Estático Estricto** | `uv run mypy --strict app scripts tests` | **`Success: no issues found in 253 source files`** |
| **Pruebas Unitarias Biomédicas y Seguridad** | `uv run pytest tests/unit -q` | **`227 passed`** (FIGO, ACOG, STRAW+10, EPDS, BBT 3-sobre-6, triaje determinista, CORS y cabeceras HTTP) |
| **Contrato SDD OpenAPI 3.1** | `uv run python scripts/export_openapi.py --check` | **`0` deriva** respecto a `contracts/openapi.json` |
| **Privacidad PHI y Gemini AI** | Auditoría de `logger.*` y configuración `google-genai` | **`0` logs con PHI**, `gemini_store_interactions = False` (`store=False`) |
| **Producción en Vivo (Render)** | `GET /api/v1/health` y `GET /api/v1/identity/me` sin JWT | `200 OK` (`{"status":"healthy","environment":"production"}`) y `401 Unauthorized` |

### 2.2 Mobile Flutter *Offline-First* (`mobile/`)

| Dimensión Auditada | Herramienta / Verificación | Resultado |
| :--- | :--- | :--- |
| **Formato y Analizador Estático** | `dart format --output=none --set-exit-if-changed .` y `flutter analyze --fatal-infos` | **`142` archivos formateados, `No issues found!`** |
| **Auditoría de 30 Pantallas Stitch Hybrid** | `test/accessibility/design_system_30_screens_audit_test.dart` | **`30/30` pantallas `*_page.dart`** con tokens Cora v2, `0` colores heredados de Material y `0` emojis |
| **Accesibilidad WCAG AA/AAA (`2.0x`)** | `test/accessibility/wcag_all_stages_audit_test.dart` + auditoría de pantallas representativas | **`0` desbordamientos (`RenderFlex overflow`)** a `TextScaler.linear(2.0)` en las 7 etapas + Drawer |
| **Pruebas Unitarias y de Widgets** | `flutter test` | **`121/121` pruebas aprobadas** |
| **Suite E2E Flujo Base (`emulator-5554`)** | `flutter test integration_test/app_full_flow_e2e_test.dart -d emulator-5554` | **`00:58 +1: All tests passed!`** |
| **Suite E2E Completa 7 Etapas (`emulator-5554`)** | `flutter test integration_test/all_features_production_e2e_test.dart -d emulator-5554` | **`01:47 +1: All tests passed!`** (`0` excepciones de framework) |
| **APK Release Producción** | `flutter build apk --release` + instalación en `Pixel_10_Pro` (`emulator-5554`) | **`app-release.apk` (`65.0 MB`)**, **`0` errores fatales en `logcat`** |

---

## 3. Cobertura E2E Verificada en Dispositivo Android (`Pixel_10_Pro`)

La suite `mobile/integration_test/all_features_production_e2e_test.dart` verificó de extremo a extremo en el emulador real:

1. **Onboarding de 4 Capas:** Datos base, intenciones, contexto clínico y selección de 2 periodos iniciales en calendario con siembra en Drift SQLite.
2. **Home Dinámico + Calendario Menstrual Interactivo + Monitoreo del Ciclo:** Navegación al calendario mensual, rueda de 4 fases y registro rápido de sangrado/síntomas.
3. **SOP & Endometriosis (`ChronicConditionsTrackerPage`) y Módulos a la Carta (`ModulePreferencesPage`):** Guardado de marcadores inflamatorios/endocrinos y configuración fisiológica.
4. **Etapa 1 — Adolescencia (`FirstPeriodAndBodyGuidePage`):** Cambio de etapa biológica y guía juvenil protegida.
5. **Etapa 2 — Búsqueda de Concepción (`ConceptionHubPage` + `PreconceptionChecklistPage`):** Curva térmica basal y marcado de ácido fólico en checklist preconcepcional.
6. **Etapa 3 — Embarazo (`PregnancyWeeklyHubPage`, `MaternalVitalsPage`, `ContractionAndKickTimersPage`, `BirthPlanAndAppointmentsPage`):** Inicio de episodio gestacional, ingreso de tensión arterial `165/115 mmHg` con **activación en vivo de bandera roja urgente ACOG por preeclampsia severa**, cronómetro 5-1-1/Cardiff y plan de parto.
7. **Etapa 4 — Posparto (`PostpartumRecoveryPage`, `LactationAndMilkBankPage`, `EpdsMentalHealthPage`):** Evolución de loquios, cronómetro dual de lactancia/banco de leche FIFO y tamizaje EPDS con **activación inmediata e incondicional del banner de crisis 24/7 al marcar positivo el ítem 10**.
8. **Etapa 5 — Perimenopausia (`PerimenopauseHubPage` + `HotFlashTrackerPage`):** Clasificación STRAW+10 y monitor de sofocos con escala Greene.
9. **Etapa 6 — Plenitud y Vitalidad Sénior (`SeniorVitalityHubPage`):** Conmutación automática al tema de alta legibilidad WCAG AAA (`>= 7:1`), referencia DXA T-Score y tarjeta de contacto de confianza.
10. **Módulos Transversales y Soberanía GDPR:** Bienestar Diario, Pastillero Virtual (`Vitamina D3`), Carpeta Clínica Digital, Vacunas/Especialistas, generación de **Reporte Doctor-Ready PDF**, Asistente Clínico RAG (**interceptación determinista urgente** ante hemorragia aguda), Biblioteca Clínica, Modo Acompañante (`Solo Lectura`) y **Purga Irreversible GDPR** (`ELIMINAR MI CUENTA CORA`) con retorno limpio al estado inicial.

---

## 4. Lista de Verificación de Salida a Producción (*Go-Live Checklist*)

### Listo y Certificado en Código y CI/CD
- [x] Arquitectura Hexagonal pura en Backend y Clean Architecture *Offline-First* (Drift SQLite + `SyncOutbox`) en Mobile.
- [x] 30 pantallas móviles + Menú Lateral integradas con el sistema visual híbrido Google Stitch (*Warm Botanical Health Editorial*).
- [x] Protección de ruta raíz (`PopScope(canPop: false)`), ancestro `Material` en tarjetas y modo local *Offline-First* en `FirebaseAuthPage`.
- [x] Seguridad HTTP (CORS explícito, cabeceras anti-sniffing/clickjacking, JWT Firebase con rechazo `401` verificado en Render, `0` secretos expuestos con Gitleaks).
- [x] Pipelines `Backend CI`, `Mobile CI` y `Security & OpenAPI Contract Verification` al 100% en verde (`success`).

### Requisitos Operativos Externos (Propietario de Cuenta al Publicar en Tiendas)
- [ ] **Llave de firma de Google Play (`key.properties` / `CORA_UPLOAD_*`):** El `build.gradle.kts` ya soporta firma de producción mediante `mobile/android/key.properties` o variables `CORA_UPLOAD_STORE_FILE` y flag `-PrequireReleaseSigning`. Para subir el `.aab`/`.apk` a Google Play Console se debe proveer el keystore privado de subida (nunca versionado en Git).
- [ ] **Instancia Render sin *Cold Start* (Plan Starter/Pro):** El backend en `https://cora-backend-h52h.onrender.com` está operativo (`healthy`), pero en el tier gratuito entra en suspensión tras inactividad (~30–50s de arranque en frío). La app móvil ya está blindada con timeouts locales de 4–6s y fallback *Offline-First*.
