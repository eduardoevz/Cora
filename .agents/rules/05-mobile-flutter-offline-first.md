---
trigger: model_decision
description: Activar al crear, editar o probar codigo Flutter/Dart en mobile/, providers Riverpod, tablas Drift SQLite, cola Offline-First, graficas, accesibilidad o privacidad movil.
---

# Regla 05 — Estándares Mobile: Flutter, Riverpod y Estrategia Offline-First

## 1. Arquitectura de Presentación y Gestión de Estado (`Riverpod`)

- Usar exclusivamente **Flutter Riverpod** con generación de código (`riverpod_annotation`, `riverpod_generator`, `build_runner`) y modelos inmutables (`freezed` o clases Dart inmutables con igualdad estructural).
- **Prohibido mezclar gestores de estado** (no introducir `flutter_bloc`, `GetX` ni `Provider` clásico).
- Los widgets complejos se dividen en componentes pequeños `ConsumerWidget` / `ConsumerStatefulWidget` con constructores `const` siempre que sea posible.
- El **Home Dashboard** y la navegación principal escuchan un provider reactivo del perfil activo (`activeLifeStageProvider` + `enabledModulesProvider`) para adaptar tarjetas y accesos directos dinámicamente sin reiniciar la app.

## 2. Arquitectura *Offline-First* con Drift + Sync Outbox

1. **Fuente Única de Verdad en UI:** La interfaz **siempre** lee streams reactivos desde **Drift (SQLite local)** (`watch...()`), nunca directamente de respuestas HTTP efímeras.
2. **Escritura Transaccional Local:** Cuando la usuaria registra un síntoma, ciclo, toma de medicamento o signo vital, una única transacción en Drift:
   - Inserta/actualiza el registro local marcándolo con `syncStatus = pending`.
   - Inserta una fila en la tabla `sync_outbox` con `clientMutationId` (UUIDv7), `entityType`, `entityId`, `operation` (`upsert` / `delete`), `payloadJson`, `attemptCount` y `createdAt`.
3. **Sincronización Idempotente en Segundo Plano:**
   - `SyncCoordinator` observa conectividad y drena `sync_outbox` en orden FIFO con backoff exponencial.
   - El backend acepta `client_mutation_id` de forma idempotente para evitar registros duplicados si se corta la conexión a mitad de respuesta.
   - Resolución de conflictos: estrategia determinista `Last-Write-Wins` por `updated_at` UTC del servidor con preservación de auditoría en registros clínicos críticos.

## 3. Accesibilidad, Diseño Empático y Etapa Plenitud

- Todo elemento interactivo cumple área táctil mínima de `48x48 dp` (y `>= 56x56 dp` cuando está activa la etapa **Plenitud / Adulta Mayor**).
- Soportar escalado dinámico de texto (`TextScaler` hasta `2.0x`) sin desbordamientos (`RenderFlex overflow`).
- El sistema de diseño incluye un tema específico de **Alta Legibilidad (WCAG AAA, contraste >= 7:1)** activable automáticamente en etapa `SENIOR_VITALITY` o manualmente desde preferencias.

## 4. Privacidad Móvil y Modo Discreto

- **Biometría y PIN Adolescente:** Proteger el acceso a carpeta clínica, diario íntimo y modo Adolescencia con `local_auth` (Face ID / Huella) o PIN cifrado en `flutter_secure_storage`.
- **Protección Visual:** Ofuscar la vista previa de la app en el conmutador de aplicaciones recientes (`secure screen` / overlay de privacidad) cuando el Modo Discreto está activo.
- **Notificaciones Neutras:** Cuando el enmascaramiento está habilitado (por defecto), los textos de recordatorios nunca exponen términos sensibles en pantalla bloqueada (ej. mostrar *"Tienes un recordatorio pendiente en Cora"* en lugar de *"Toma tu pastilla anticonceptiva / Registro de ovulación"*).
