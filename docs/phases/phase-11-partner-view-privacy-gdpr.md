# Fase 11 — Modo Acompañante (*Partner View*), Privacidad Robusta, Modo Discreto y Purga GDPR Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el módulo `partner_sharing` (**Modo Acompañante / Pareja** con permisos selectivos revocables al instante) y endurecer de punta a punta la **Privacidad de Grado Médico y Modo Discreto**: cifrado local SQLCipher en Drift, bloqueo biométrico (`local_auth`), icono de aplicación camuflable, ocultamiento en multitarea, exportación portable completa y purga irreversible de cuenta.

**Architecture:** `partner_sharing` implementa una proyección estricta de solo lectura mediada por `PartnerLink` (`ACTIVE`, `PAUSED`, `REVOKED`) y `SharingScopeMask` (`share_fertility_window`, `share_pregnancy_milestones`, `share_mood_and_support_tips`). En `identity`, `ExportUserDataUseCase` y `PurgeAccountIrreversiblyUseCase` coordinan la extracción total o eliminación atómica en PostgreSQL + Cloudflare R2 (`IFileStorage.delete_user_prefix`).

**Tech Stack:** Python 3.12+, FastAPI, SQLAlchemy 2.0 Async, Flutter, Riverpod, Drift + `sqlcipher_flutter_libs`, `local_auth`, `flutter_secure_storage`, ` dynamic icon / activity-alias`.

**Spec:** `docs/SPECS.MD` (Sección 4: Modo Acompañante y Privacidad Robusta / Modo Discreto), `.agents/rules/05-mobile-flutter-offline-first.md`

## Global Constraints

- **Principio de mínimo privilegio en *Partner View*:** Por defecto todos los permisos nacen en `False`; documentos de `medical_records`, conversaciones de `rag_assistant`, notas íntimas y tamizajes `EPDS` están **excluidos por diseño** de *Partner View*.
- Los códigos de invitación de pareja son de un solo uso, alta entropía, almacenados como hash SHA-256 y expiran en `24` horas.
- Revocar un enlace (`DELETE /api/v1/partner-sharing/links/{link_id}`) invalida el acceso del acompañante en `< 1` segundo (`403/404` inmediato en cualquier petición subsiguiente).
- La **purga irreversible de cuenta** exige confirmación explícita autenticada y elimina en cascada todas las filas del `user_id` en los 9 módulos de PostgreSQL más todos sus objetos en Cloudflare R2, sin dejar backups blandos (`soft-delete`) de datos clínicos.

## Review Focus

1. **Filtración de campos no autorizados en *Partner View*:** Si la usuaria activa únicamente `share_pregnancy_milestones = True`, el endpoint de acompañante jamás debe serializar estado de ánimo, síntomas ni ventana fértil.
2. **Auto-vinculación o reutilización de código expirado:** Una usuaria no puede canjear su propio código de invitación ni reutilizar un código ya consumido o vencido.
3. **Migración transparente de base SQLite local a SQLCipher cifrado:** La llave de cifrado AES-256 de Drift se genera criptográficamente y se resguarda en Keychain (iOS) / Keystore (Android) vía `flutter_secure_storage`.
4. **Fallo parcial de red durante la purga de cuenta en R2:** Primero eliminar/invalidar el acceso y limpiar prefijos en Cloudflare R2; si R2 confirma borrado, ejecutar `DELETE CASCADE` transaccional en PostgreSQL y registrar únicamente un evento de auditoría anónimo sin PII.
5. **Bloqueo biométrico al volver desde segundo plano (`AppLifecycleState.paused -> resumed`):** Exigir re-autenticación tras el umbral configurable (`inmediato` o `1 minuto`) cubriendo la pantalla con un overlay opaco en el selector de apps recientes.

---

### Task 1: Módulo Hexagonal `partner_sharing` — Invitaciones Seguras, Permisos Granulares y Proyección Selectiva (TDD)

**Files:**
- Create: `backend/alembic/versions/0012_create_partner_sharing_tables.py`
- Create: `backend/app/modules/partner_sharing/domain/models/partner_link.py`
- Create: `backend/app/modules/partner_sharing/domain/services/partner_projection_builder.py`
- Create: `backend/app/modules/partner_sharing/application/ports/partner_sharing_repository_port.py`
- Create: `backend/app/modules/partner_sharing/application/use_cases/partner_sharing_use_cases.py`
- Create: `backend/app/modules/partner_sharing/infrastructure/orm/partner_sharing_orm.py`
- Create: `backend/app/modules/partner_sharing/infrastructure/adapters/postgres_partner_sharing_repository.py`
- Create: `backend/app/modules/partner_sharing/infrastructure/entrypoints/partner_sharing_router.py`
- Test: `backend/tests/unit/partner_sharing/test_partner_permissions_and_projection.py`
- Test: `backend/tests/integration/partner_sharing/test_partner_sharing_api.py`

**Interfaces:**
- Consumes: Puertos de solo lectura de `identity`, `clinical_tracking` (ventana fértil) y `maternal_care` (hito semanal fetal)
- Produces:
  - `POST /api/v1/partner-sharing/invitations`, `POST /api/v1/partner-sharing/invitations/redeem`, `PATCH /api/v1/partner-sharing/links/{link_id}/permissions`, `DELETE /api/v1/partner-sharing/links/{link_id}`, `GET /api/v1/partner-sharing/shared-with-me`

- [x] **Step 1: Escribir tests TDD unitarios y de integración verificando expiración a las `24h`, rechazo de auto-vinculación, proyección estricta campo por campo según `SharingScopeMask`, ausencia absoluta de datos de `medical_records`/`EPDS`, y bloqueo instantáneo tras revocación**
- [x] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/unit/partner_sharing backend/tests/integration/partner_sharing -v`
  - Expected: FAIL
- [x] **Step 3: Implementar dominio, migración `0012`, ORM, repositorio, casos de uso y router de `partner_sharing`**
- [x] **Step 4: Verificar tests y `mypy --strict`**
  - Run: `mypy --strict backend/app && pytest backend/tests/unit/partner_sharing backend/tests/integration/partner_sharing -v`
  - Expected: PASS
- [x] **Step 5: Commit**
  - `git add backend/alembic/versions/0012_create_partner_sharing_tables.py backend/app/modules/partner_sharing backend/tests/unit/partner_sharing backend/tests/integration/partner_sharing`
  - `git commit -m "feat(partner-sharing): implement selective bidirectional partner links with instant revocation"`

---

### Task 2: Soberanía de Datos en `identity` — Exportación Completa (`JSON/ZIP`) y Purga Irreversible en Cascada

**Files:**
- Create: `backend/app/modules/identity/application/use_cases/export_all_user_data_use_case.py`
- Create: `backend/app/modules/identity/application/use_cases/purge_account_irreversibly_use_case.py`
- Modify: `backend/app/modules/identity/infrastructure/entrypoints/router.py`
- Modify: `backend/app/main.py`
- Modify: `contracts/openapi.json`
- Test: `backend/tests/integration/identity/test_data_export_and_irreversible_purge.py`

**Interfaces:**
- Consumes: Repositorios de los 9 módulos + `IFileStorage.delete_user_prefix` (Fase 9)
- Produces:
  - `POST /api/v1/identity/me/data-export` (archivo ZIP estructurado con JSON clínicos y manifiesto de documentos)
  - `DELETE /api/v1/identity/me` (con header/body de confirmación explícita `confirm_phrase="ELIMINAR MI CUENTA CORA"`)

- [x] **Step 1: Escribir test de integración poblando datos en todos los módulos (perfil, ciclos, embarazo, tratamientos, exámenes en R2 mock, conversaciones RAG y vínculo de pareja), verificando que `/data-export` los incluye todos y que `DELETE /me` deja exactamente `0` registros del usuario en todas las tablas y `0` objetos en R2 sin afectar a otra usuaria vecina**
- [x] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/integration/identity/test_data_export_and_irreversible_purge.py -v`
  - Expected: FAIL
- [x] **Step 3: Implementar `ExportAllUserDataUseCase`, `PurgeAccountIrreversiblyUseCase`, rutas en `identity` y actualizar `contracts/openapi.json`**
- [x] **Step 4: Verificar toda la suite backend**
  - Run: `python backend/scripts/export_openapi.py && pytest backend/tests -v`
  - Expected: PASS
- [x] **Step 5: Commit**
  - `git add backend/app/modules/identity backend/app/main.py contracts/openapi.json backend/tests/integration/identity/test_data_export_and_irreversible_purge.py`
  - `git commit -m "feat(identity): add portable full data export and cascading irreversible account purge"`

---

### Task 3: Privacidad Móvil en Flutter — SQLCipher, Bloqueo Biométrico, Icono Camuflable, Overlay de Privacidad y UI de *Partner View*

**Files:**
- Create: `mobile/lib/core/security/biometric_lock_service.dart`
- Create: `mobile/lib/core/security/discreet_app_icon_service.dart`
- Create: `mobile/lib/core/security/privacy_lifecycle_gate.dart`
- Create: `mobile/lib/features/partner/presentation/pages/partner_sharing_settings_page.dart`
- Create: `mobile/lib/features/partner/presentation/pages/partner_companion_view_page.dart`
- Create: `mobile/lib/features/privacy/presentation/pages/privacy_and_data_sovereignty_page.dart`
- Modify: `mobile/lib/core/database/app_database.dart`
- Modify: `mobile/lib/main.dart`
- Test: `mobile/test/core/privacy_lifecycle_and_biometric_gate_test.dart`
- Test: `mobile/test/features/partner/partner_permissions_ui_test.dart`

**Interfaces:**
- Consumes: `local_auth`, `flutter_secure_storage`, endpoints `/api/v1/partner-sharing/*` y `/api/v1/identity/me/*`
- Produces: Cifrado local en reposo, Modo Discreto integral y pantallas de Pareja/Privacidad

- [x] **Step 1: Escribir tests en Flutter verificando: activación inmediata del overlay opaco al pasar a `AppLifecycleState.inactive`/`paused`, solicitud biométrica al reanudar, selector de icono camuflado (ej. icono neutro de Calendario/Notas), switches granulares de *Partner View* y confirmación de borrado total con limpieza de Drift + SecureStorage**
- [x] **Step 2: Ejecutar `flutter test` y confirmar fallo**
  - Run: `cd mobile && flutter test test/core/privacy_lifecycle_and_biometric_gate_test.dart test/features/partner`
  - Expected: FAIL
- [x] **Step 3: Configurar clave cifrada SQLCipher en `AppDatabase`, implementar `BiometricLockService`, `PrivacyLifecycleGate`, configuración nativa de iconos alternativos Android/iOS y páginas de *Partner View* y Soberanía de Datos**
- [x] **Step 4: Ejecutar `build_runner`, `flutter analyze` y `flutter test`**
  - Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-infos && flutter test`
  - Expected: PASS
- [x] **Step 5: Commits finales y cierre de Fase 11**
  - `git add mobile`
  - `git commit -m "feat(mobile-ui): add SQLCipher encryption, biometric lock, camouflage icon mode, and Partner View"`
  - `git add docs/phases/phase-11-partner-view-privacy-gdpr.md docs/phases/README.md`
  - `git commit -m "docs(plan): mark phase 11 tasks completed"`
