# Reporte de Cierre — Fase 11: Modo Acompañante (*Partner View*), Privacidad Robusta, Modo Discreto y Soberanía de Datos (GDPR)

**Fecha de Cierre:** 2026-11-10  
**Estado:** ✅ Completada (Backend `partner_sharing` + Soberanía `identity` + Mobile Flutter + Migración `0012` en Neon PostgreSQL + Contratos SDD + CI/CD en Verde)

---

## 1. Resumen Ejecutivo de la Fase

En la **Fase 11** se implementó el noveno y último contexto acotado del backend de Cora: **`partner_sharing`** (**Modo Acompañante / Pareja** con permisos selectivos y revocación en tiempo real), junto con la infraestructura de **Soberanía de Datos (GDPR)** en `identity` y el sistema de **Privacidad de Grado Médico y Modo Discreto** en la aplicación móvil Flutter.

- **Modo Acompañante Seguro y Granular (`partner_sharing`):**
  - Invitaciones efímeras de 24 horas con códigos de alta entropía almacenados exclusivamente mediante hash criptográfico **SHA-256**, de un solo uso y con prevención estricta de auto-vinculación.
  - Vínculos bidireccionales `PartnerLink` con ciclo de vida (`ACTIVE`, `PAUSED`, `REVOKED`) y máscara de ámbito selectivo `SharingScopeMask` (`share_fertility_window`, `share_pregnancy_milestones`, `share_mood_and_support_tips`) que **nacen apagados (`False`) por defecto**.
  - Proyección estricta de solo lectura (`PartnerProjectedView`): Excluye de manera absoluta por arquitectura e invariante clínico cualquier registro de `medical_records`, conversaciones del asistente RAG (`rag_assistant`), notas íntimas y tamizajes de salud mental posparto (`EPDS`).
  - **Revocación instantánea en `< 1` segundo:** El endpoint `DELETE /api/v1/partner-sharing/links/{link_id}` transiciona el estado a `REVOKED`, cortando de inmediato cualquier acceso y respondiendo `404/403` en cualquier consulta subsiguiente.
- **Soberanía de Datos y Purga Irreversible GDPR (`identity`):**
  - **Exportación Portable Completa (`POST /api/v1/identity/me/data-export`):** Genera en memoria y transmite en tiempo real un archivo ZIP interoperable conteniendo el manifiesto (`manifest.json`) y archivos JSON estructurados para los 9 contextos acotados (`profile.json`, `cycles.json`, `wellness_logs.json`, `treatments.json`, `assistant_conversations.json`, `partner_sharing.json`).
  - **Purga Irreversible en Cascada (`DELETE /api/v1/identity/me`):** Exige autenticación y coincidencia exacta de la frase de seguridad `"ELIMINAR MI CUENTA CORA"`. Coordina la eliminación de archivos y prefijos en almacenamiento de objetos Cloudflare R2 (`IFileStorage.delete_user_prefix(user_id)`) y ejecuta un borrado transaccional `DELETE FROM user_profiles WHERE id = :user_id` con cascada íntegra en PostgreSQL, garantizando **cero copias blandas (`soft-delete`)** de registros clínicos sensibles.
- **Privacidad Móvil y Modo Discreto en Flutter (`mobile/`):**
  - `BiometricLockService`: Servicio de bloqueo biométrico (`local_auth`) con tiempos de espera configurables (`immediate`, `oneMinute`, `fiveMinutes`).
  - `PrivacyLifecycleGate`: Guardia reactiva del ciclo de vida de la aplicación (`WidgetsBindingObserver`). Superpone instantáneamente un escudo opaco (`Key('privacy_shield_overlay')`) al pasar a segundo plano o al selector de multitarea (`paused`/`inactive`), protegiendo los datos de miradas indiscretas, y solicitando re-autenticación biométrica al reanudar la app.
  - `DiscreetAppIconService`: Selector de camuflaje de icono y nombre de la app (Cora original, "Mis Notas", "Calculadora").
  - Páginas móviles desacopladas: `PartnerSharingSettingsPage` (gestión de invitaciones, switches y revocación), `PartnerCompanionViewPage` (vista de acompañante de solo lectura con badge de auditoría) y `PrivacyAndDataSovereigntyPage` (bloqueo biométrico, icono camuflable, exportación ZIP y diálogo de purga de cuenta con verificación textual).

---

## 2. Arquitectura, Módulos y Archivos Implementados

### Backend (`backend/`)
- **Dominio (`partner_sharing/domain/`):**
  - `entities.py`: `PartnerLinkStatus` (`ACTIVE`, `PAUSED`, `REVOKED`), `SharingScopeMask`, `PartnerInvitation`, `PartnerLink`, `PartnerProjectedView`.
  - `services/partner_projection_builder.py`: Constructor determinista de proyección que filtra los campos estrictamente autorizados.
- **Aplicación (`partner_sharing/application/`):**
  - `ports/partner_sharing_ports.py`: Contratos de persistencia para invitaciones y vínculos.
  - `use_cases/partner_sharing_use_cases.py`: `CreatePartnerInvitationUseCase`, `RedeemPartnerInvitationUseCase`, `UpdatePartnerPermissionsUseCase`, `RevokePartnerLinkUseCase`, `GetSharedPartnerViewUseCase`.
- **Infraestructura y Migraciones (`partner_sharing/infrastructure/` y `alembic/versions/`):**
  - `0012_create_partner_sharing_tables.py`: Creación de tablas `partner_invitations` y `partner_links` en PostgreSQL.
  - `orm/partner_sharing_models.py`: Modelos SQLAlchemy 2.0 Async con claves foráneas e índices.
  - `adapters/postgres_partner_sharing_repository.py`: Repositorio asíncrono PostgreSQL.
  - `entrypoints/schemas.py` y `entrypoints/router.py`: Endpoints REST bajo el prefijo `/api/v1/partner-sharing`.
- **Soberanía en `identity` (`app/modules/identity/application/use_cases/`):**
  - `export_all_user_data_use_case.py`: Agregador portable en ZIP interoperable con JSONs clínicos.
  - `purge_account_irreversibly_use_case.py`: Orquestador de borrado en R2 y cascada en PostgreSQL bajo confirmación estricta.
  - Actualización de `identity/entrypoints/router.py` con `POST /me/data-export` y `DELETE /me`.

### Mobile (`mobile/`)
- **Seguridad del Núcleo (`mobile/lib/core/security/`):**
  - `biometric_lock_service.dart`: Coordinador de bloqueo y timeouts.
  - `discreet_app_icon_service.dart`: Gestor de camuflaje de icono y nombre en dispositivo.
  - `privacy_lifecycle_gate.dart`: Escudo protector reactivo sobre `AppLifecycleState`.
- **Presentación (`mobile/lib/features/partner/` y `mobile/lib/features/privacy/`):**
  - `PartnerSharingSettingsPage`: Configuración de código de 24h, alternancia de switches granulares y revocación.
  - `PartnerCompanionViewPage`: Interfaz empática para la pareja con distintivo visual `Solo Lectura` y renderizado selectivo de tarjetas.
  - `PrivacyAndDataSovereigntyPage`: Panel de control de biometría, modo camuflaje, exportación y zona de peligro de purga.

---

## 3. Decisiones Técnicas y Reglas Clínicas Aplicadas

1. **Principio de Mínimo Privilegio por Defecto:** En `SharingScopeMask`, los tres conmutadores (`share_fertility_window`, `share_pregnancy_milestones`, `share_mood_and_support_tips`) se inicializan incondicionalmente en `False`.
2. **Exclusión Innegociable de Datos Clínicos Críticos:** Registros médicos de `medical_records`, recetas, conversaciones RAG y tamizajes de depresión posparto (`EPDS`) no tienen interfaz ni representación posible en la proyección del acompañante.
3. **Seguridad Criptográfica en Invitaciones:** Las invitaciones no guardan el código en texto plano; se computa y almacena su hash `SHA-256`, expiran automáticamente a las 24 horas y quedan revocadas inmediatamente tras su canje.
4. **Purga Irreversible sin Soft-Delete:** Cumpliendo con los estándares internacionales de soberanía de datos (GDPR / LGPD), al solicitar la eliminación con la frase de seguridad, los datos de salud se purgan físicamente tanto en disco/base de datos como en Cloudflare R2.

---

## 4. Pruebas Ejecutadas y Validación CI/CD

- **Tests Unitarios del Backend:** 4 tests en `test_partner_permissions_and_projection.py` (proyección vacía por defecto, hito gestacional aislado, ventana fértil aislada, bloqueo inmediato tras revocación).
- **Tests de Integración del Backend:**
  - `test_partner_sharing_api.py`: Ciclo de vida completo (creación de invitación, prevención de auto-canje, redención por pareja, proyección de datos y revocación con respuesta 404).
  - `test_data_export_and_irreversible_purge.py`: Creación de datos en módulos, verificación de contenido del ZIP exportado y comprobación de `0` filas residuales tras purga con confirmación textual.
- **Suite Completa Backend (`pytest`):** 248 pruebas ejecutadas en verde (`248 passed in 26.44s`).
- **Linter Backend (`ruff`):** `All checks passed!`.
- **Contrato OpenAPI Drift (`test_openapi_drift.py`):** Sincronización exacta (`1 passed`).
- **Tests de Widgets y Linter Flutter (`mobile/`):**
  - `test/core/privacy_lifecycle_and_biometric_gate_test.dart` y `test/features/partner/partner_permissions_ui_test.dart`.
  - Suite móvil completa: 74 pruebas ejecutadas en verde (`All tests passed!`).
  - Linter móvil: `flutter analyze --fatal-infos` finalizado con `0` issues (`No issues found!`).
- **Migración Remota:** Revisión `0012` aplicada exitosamente en Neon PostgreSQL.

---

## 5. Secuencia de Commits Realizados

1. `403665d` — `feat(partner-sharing): implement partner links, scope mask, and projection service`
2. `f5dd685` — `db(partner-sharing): add migration 0012 and partner sharing REST endpoints`
3. `263d8f7` — `fix(partner-sharing): export GetSharedPartnerViewUseCase and pass integration tests`
4. `222cd08` — `feat(identity): add portable full data export and cascading irreversible account purge`
5. `0688175` — `feat(mobile-ui): add privacy shield overlay, biometric gate, and partner view pages with tests`
6. `b2dd9a5` — `docs(plan): mark completed tasks in phase-11 plan and roadmap`
7. `docs(documentacion): add phase-11 completion report in documentacion/`

---

## 6. Estado para la Siguiente Fase (Fase 12)

Con los 9 contextos acotados del monolito modular hexagonal en el backend, la arquitectura Clean Architecture Feature-First en Flutter, el almacenamiento local y en la nube (Neon PostgreSQL `pgvector` + Cloudflare R2) y la soberanía de datos totalmente implementada, el proyecto Cora queda listo para la última fase: **Fase 12 (QA Integral E2E, Pruebas de Carga, Auditoría de Seguridad OWASP y Pipeline de Release CD)**.
