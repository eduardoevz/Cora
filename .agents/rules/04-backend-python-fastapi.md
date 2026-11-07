---
trigger: model_decision
description: Activar al crear, editar o probar codigo Python en backend/, routers FastAPI, modelos SQLAlchemy 2.0 Async, migraciones Alembic, Neon pgvector, Cloudflare R2 o reportes PDF WeasyPrint.
---

# Regla 04 — Estándares Backend: Python, FastAPI, SQLAlchemy Async, R2 y PDF

## 1. Entorno Python y Calidad Estática

- **Versión objetivo:** Python `3.12+` en imágenes Docker oficiales (`python:3.12-slim`) y compatibilidad verificada en desarrollo local (gestionado preferiblemente con `uv` y `pyproject.toml`).
- **Tipado y estilo obligatorios:**
  - `ruff check backend` y `ruff format --check backend` sin advertencias.
  - `mypy --strict backend/app` sin `type: ignore` injustificados.
- Usar sintaxis moderna de tipado (`list[str]`, `dict[str, Any]`, `X | None`, `typing.Protocol`).

## 2. Persistencia Asíncrona (`SQLAlchemy 2.0` + `Alembic` + `Neon`)

- Utilizar exclusivamente `AsyncEngine`, `async_sessionmaker(expire_on_commit=False)` y el driver `asyncpg`.
- Usar sintaxis declarativa tipada de SQLAlchemy 2.0 (`Mapped[...]`, `mapped_column(...)`).
- Todas las llaves primarias de entidades clínicas y usuarios usan `UUID` (preferiblemente `UUIDv7` ordenable temporalmente o `uuid4`) junto con `created_at` y `updated_at` en UTC (`TIMESTAMPTZ`).
- **Aislamiento Multi-Tenant Estricto:** Todo método de repositorio que lea o modifique datos de una usuaria **debe exigir `user_id: UUID` por firma** y aplicarlo en el `WHERE`. Nunca confiar en un `user_id` enviado en el body/query si difiere del `sub`/`uid` autenticado en el token JWT de Firebase (salvo proyección explícita de *Partner View* validada por `partner_sharing`).
- **Migraciones Alembic:** Cada cambio de esquema incluye función `upgrade()` y `downgrade()` reversible, probada sobre PostgreSQL con la extensión `CREATE EXTENSION IF NOT EXISTS vector;`.

## 3. Diseño de Endpoints FastAPI y Seguridad

- Versionar todas las rutas bajo `/api/v1/<recurso>`.
- Estandarizar respuestas de error bajo **RFC 7807 (`application/problem+json`)** mapeando excepciones de `domain/exceptions/` en un manejador global en `app/core/errors.py`.
- Validación criptográfica de tokens **Firebase Auth** mediante `firebase-admin` (o JWKS cacheado en tests/entornos desacoplados) inyectado por dependencia `CurrentUserDep`.

## 4. Almacenamiento Cloudflare R2 y Generación de PDFs

- **Cloudflare R2 (`IFileStorage`):**
  - Usar cliente S3 asíncrono/boto3 encapsulado en `CloudflareR2StorageAdapter`.
  - Nunca exponer buckets públicos: subir y descargar estudios médicos mediante **Presigned URLs de corta duración (`<= 15` minutos)** bajo prefijos aislados `users/{user_id}/records/{record_id}`.
  - Validar tipo MIME real (`application/pdf`, `image/jpeg`, `image/png`, `image/webp`) y límite máximo de tamaño (`<= 15 MB`).
- **Reportes *Doctor-Ready PDF* (`WeasyPrint` + `Jinja2`):**
  - Encapsular tras un puerto `IClinicalReportRenderer`.
  - En `Dockerfile` incluir las librerías del sistema requeridas por Pango/Cairo (`libpango-1.0-0`, `libpangoft2-1.0-0`, `libharfbuzz-subset0`), y en Windows local permitir ejecución vía contenedor Docker o adaptador verificable en tests.
