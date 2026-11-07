---
trigger: always_on
description: Reglas estrictas de Arquitectura Hexagonal en Backend, Clean Architecture Feature-First en Flutter y Spec-Driven Development (SDD).
---

# Regla 02 — Arquitectura Hexagonal, Clean Architecture y SDD

## 1. Backend: Monolito Modular con Arquitectura Hexagonal

Todo código de negocio reside en `backend/app/modules/<modulo>/` dentro de uno de los **9 contextos acotados**:
`identity`, `clinical_tracking`, `maternal_care`, `mature_health`, `treatments`, `medical_records`, `education_content`, `rag_assistant`, `partner_sharing`.

### Regla de Dirección de Dependencias (`infrastructure -> application -> domain`)

1. **`domain/` (Núcleo Puro):**
   - Contiene Entidades, Agregados, `ValueObjects` (`@dataclass(frozen=True)`), Servicios de Dominio deterministas y Excepciones de Dominio.
   - **Prohibido importar:** `fastapi`, `sqlalchemy`, `pydantic` (de capa HTTP), `httpx`, `boto3`, `google.genai`, `weasyprint` o `app.core.database`.
2. **`application/` (Orquestación):**
   - Contiene `UseCases` (una clase por caso de uso con un único método público `async def execute(...)`), `DTOs` de aplicación y `Ports` (`typing.Protocol` o `abc.ABC`).
   - Solo puede importar `domain/` y librerías estándar de Python (`typing`, `uuid`, `datetime`, ` dataclasses`, `decimal`).
3. **`infrastructure/` (Adaptadores y Entrada/Salida):**
   - `orm/`: Modelos `SQLAlchemy 2.0` y mappers explícitos entre Entidades de Dominio y filas ORM.
   - `adapters/`: Implementaciones concretas de los puertos (`PostgresClinicalRepository`, `CloudflareR2StorageAdapter`, `GeminiClinicalAssistantAdapter`, `WeasyPrintPdfGenerator`).
   - `entrypoints/`: Routers `FastAPI`, esquemas `Pydantic v2` (`Request`/`Response`) e inyección de dependencias con `Depends`.

### Comunicación Entre Módulos
- Un módulo **nunca** consulta directamente tablas ORM ni adaptadores internos de otro módulo.
- Toda interacción entre módulos ocurre a través de un puerto público expuesto en `application/ports/` o mediante eventos de dominio en proceso.

## 2. Mobile: Clean Architecture Feature-First + Riverpod

Cada funcionalidad en `mobile/lib/features/<feature>/` respeta tres capas:

1. **`domain/` (Dart Puro):** Entidades inmutables, `ValueObjects`, contratos abstractos de repositorios y `UseCases`. Sin imports de `flutter/material.dart`, `dio` ni código generado de SQL.
2. **`data/`:** Implementaciones de repositorios que coordinan `LocalDataSource` (**Drift SQLite**) + `SyncOutboxService` + `RemoteDataSource` (cliente HTTP tipado).
3. **`presentation/`:** Páginas, widgets desacoplados y `AsyncNotifier` / providers de **Riverpod** (`@riverpod`). Ningún widget invoca clientes HTTP ni sentencias SQL directamente.

## 3. Spec-Driven Development (SDD — Contract-First)

1. Los esquemas `Pydantic v2` de `entrypoints/` en FastAPI son la **única fuente de verdad** del contrato REST (`openapi.json`).
2. Todo endpoint debe declarar `response_model`, códigos de estado explícitos, descripciones clínicas claras y esquemas de error estándar **RFC 7807 (`ProblemDetails`)**.
3. Cada vez que se modifique un endpoint en `backend/`, se debe exportar/actualizar el artefacto `openapi.json` y sincronizar los modelos/clientes Dart en `mobile/`, verificando que no exista deriva de tipos.
