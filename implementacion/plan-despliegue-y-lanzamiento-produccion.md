# Plan de Implementación: Automatización de Despliegue, Operaciones y Lanzamiento a Producción (Cora v1.0.0)

Este documento contiene la hoja de ruta de ejecución y el seguimiento por checkboxes de los **5 pasos operativos** aprobados para el lanzamiento de **Cora**.

---

### Paso 1: Despliegue del Backend en la Nube y CI/CD CD
- [x] **Step 1.1:** Crear workflow de GitHub Actions CD (`.github/workflows/cd-deploy-backend.yml`) para construir y publicar la imagen en GitHub Container Registry (`ghcr.io/eduardoevz/cora-backend`).
- [x] **Step 1.2:** Crear manifiesto `deploy/docker-compose.prod.yml` con proxy inverso Caddy (HTTPS automático Let's Encrypt), límites de recursos y contenedor backend non-root.
- [x] **Step 1.3:** Crear manifiestos PaaS/Serverless: `deploy/cloudrun/service.yaml`, `deploy/render.yaml` y `deploy/railway.toml`.
- [x] **Step 1.4:** Crear script de verificación y smoke testing `backend/scripts/verify_deployment.py`.
- [x] **Step 1.5:** Documentar en `implementacion/paso-01-despliegue-nube.md` y commit atómico.

---

### Paso 2: Validación y Aprovisionamiento de Secretos y Variables de Entorno
- [x] **Step 2.1:** Implementar script `backend/scripts/validate_production_env.py` con comprobación activa de Neon PostgreSQL (`vector`), Firebase Auth, Cloudflare R2 y Gemini API (`store=False`).
- [x] **Step 2.2:** Crear plantilla exhaustiva y segura `backend/.env.production.example`.
- [x] **Step 2.3:** Crear suite de pruebas unitarias `backend/tests/unit/test_env_validator.py`.
- [x] **Step 2.4:** Verificar ejecución con pytest (`100% pass`) y linter `ruff`.
- [x] **Step 2.5:** Documentar en `implementacion/paso-02-secretos-y-entorno.md` y commit atómico.

---

### Paso 3: Automatización de la Ingesta del Corpus Clínico RAG en PostgreSQL (Neon)
- [ ] **Step 3.1:** Crear script `backend/scripts/ingest_clinical_library.py` con el corpus canónico (FIGO, ACOG, STRAW+10, EPDS, vacunas) y soporte de `--dry-run`, `--batch-size` y `--force`.
- [ ] **Step 3.2:** Integrar `SemanticChunker` de `education_content` y generación de embeddings (`768d`) con almacenamiento HNSW en Neon PostgreSQL.
- [ ] **Step 3.3:** Crear prueba automatizada de integración `backend/tests/integration/test_clinical_ingestion_script.py`.
- [ ] **Step 3.4:** Validar ejecución del script en modo `--dry-run` y tests automatizados.
- [ ] **Step 3.5:** Documentar en `implementacion/paso-03-ingesta-corpus-rag.md` y commit atómico.

---

### Paso 4: Andamiaje Nativo, Automatización de Firma y Compilación Móvil
- [ ] **Step 4.1:** Andamiar plataformas nativas `mobile/android/` y `mobile/ios/` con identificador `com.cora.health`.
- [ ] **Step 4.2:** Configurar `AndroidManifest.xml` (biometría, internet, security config) y `build.gradle` (SDK 23-34, signing config release, Proguard para Drift/SQLCipher).
- [ ] **Step 4.3:** Configurar `mobile/ios/Runner/Info.plist` y `mobile/ios/Runner/PrivacyInfo.xcprivacy` (Apple Privacy Manifest).
- [ ] **Step 4.4:** Crear workflow en GitHub Actions `.github/workflows/ci-cd-mobile-build.yml` para compilar Android App Bundle (`.aab`) y APK release.
- [ ] **Step 4.5:** Crear scripts de empaquetado local `mobile/scripts/build_release_bundles.ps1` y `.sh`.
- [ ] **Step 4.6:** Verificar `flutter analyze --fatal-infos` y `flutter test`.
- [ ] **Step 4.7:** Documentar en `implementacion/paso-04-empaquetado-y-firma-movil.md` y commit atómico.

---

### Paso 5: Preparación de Lanzamiento y Metadata de Tiendas
- [ ] **Step 5.1:** Crear activos de Google Play en `distribution/store_assets/google_play/` (título, descripción corta, descripción completa, descargo médico y política de privacidad).
- [ ] **Step 5.2:** Crear activos de App Store en `distribution/store_assets/app_store/` (keywords, texto promocional y notas de revisión médica).
- [ ] **Step 5.3:** Crear script auditor `scripts/audit_store_readiness.py` validando longitudes de texto, disclaimers y consistencia de privacidad.
- [ ] **Step 5.4:** Ejecutar auditoría de tiendas y verificar cumplimiento 100%.
- [ ] **Step 5.5:** Documentar en `implementacion/paso-05-lanzamiento-tiendas.md`, actualizar `implementacion/README.md` y commit final.
