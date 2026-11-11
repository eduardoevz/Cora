# Guía Operativa de Despliegue y Lanzamiento — Cora v1.0.0

Este documento describe la arquitectura productiva, las variables de entorno requeridas, el aprovisionamiento de infraestructura administrada (**Neon PostgreSQL + `pgvector`**, **Cloudflare R2**, **Firebase Authentication**, **Google Gemini API**) y el procedimiento de despliegue continuo (CD) para **Cora v1.0.0**.

---

## 1. Arquitectura de Despliegue en Producción

```mermaid
flowchart TB
    subgraph Mobile["Clientes Móviles (iOS / Android)"]
        APP["Flutter 3.x App\nDrift SQLite + SQLCipher\nSyncOutbox Offline-First"]
    end

    subgraph Edge["Seguridad & Almacenamiento Directo"]
        FB["Firebase Authentication\nVerificación JWT RS256"]
        R2["Cloudflare R2 Bucket\nPresigned PUT/GET (Zero-Egress)"]
    end

    subgraph Cloud["Compute & Inteligencia Clínica"]
        API["Cora Backend API\nFastAPI + Gunicorn/Uvicorn\nContenedor Non-Root (UID 10001)"]
        DB[("Neon Serverless PostgreSQL 16\nExtensión vector + Índice HNSW")]
        AI["Google Gemini API\ngemini-3.8-flash (store=False)\ngemini-embedding-2 (768d)"]
    end

    APP -->|"Bearer JWT"| FB
    APP <-->|"HTTPS REST /api/v1/*"| API
    APP <-->|"Presigned HTTPS"| R2
    API -->|"SQLAlchemy 2.0 Async (asyncpg)"| DB
    API -->|"Boto3 S3 V4"| R2
    API -->|"google-genai >= 2.30.1"| AI
```

---

## 2. Aprovisionamiento de Servicios Externos

### 2.1 Neon Serverless PostgreSQL + `pgvector`
1. Crear un proyecto en **Neon** (PostgreSQL 16) con *connection pooling* activado para clientes concurrentes y conexión directa para migraciones de **Alembic**.
2. Ejecutar las migraciones desde `backend/`:
   ```bash
   cd backend
   uv run alembic upgrade head
   ```
   Esto aplica las **13 migraciones (`0001` a `0013`)**, habilitando automáticamente `CREATE EXTENSION IF NOT EXISTS vector`, creando el índice vectorial **HNSW (`m=16, ef_construction=64`)** sobre `clinical_evidence_chunks.embedding` y los índices compuestos longitudinales `(user_id, <fecha/timestamp>)`.
3. Sembrar el corpus clínico curado e indexar sus vectores en `pgvector`:
   ```bash
   cd backend
   uv run python scripts/ingest_clinical_library.py
   ```

### 2.2 Cloudflare R2 (Carpeta Clínica Digital)
1. Crear un bucket privado en **Cloudflare R2** (ej. `cora-medical-records-prod`) con acceso público deshabilitado.
2. Configurar la política CORS del bucket para permitir únicamente métodos `GET`, `PUT` y `HEAD` desde los orígenes autorizados con cabecera `Content-Type` (`application/pdf`, `image/jpeg`, `image/png`, `image/webp`).
3. Generar credenciales API S3-compatibles con permisos de lectura/escritura acotados exclusivamente a dicho bucket.

### 2.3 Firebase Authentication
1. Habilitar proveedores de inicio de sesión (Correo/Contraseña, Google, Apple Sign-In).
2. Descargar las credenciales de cuenta de servicio o configurar *Workload Identity Federation* en el entorno de ejecución del backend.
3. **Invariante de seguridad:** Jamás versionar `firebase_service_account.json` en el repositorio público `eduardoevz/Cora`.

### 2.4 Google Gemini API (`store=False`)
1. Generar una `GEMINI_API_KEY` en Google AI Studio / Vertex AI con acceso a:
   - Generación fundamentada: `gemini-3.8-flash`
   - Embeddings semánticos: `gemini-embedding-2` (`768` dimensiones)
2. El adaptador `GeminiClinicalAssistantAdapter` fuerza por código `store=False` en toda interacción y antecede el `DeterministicSafetyInterceptor` (`< 5 ms`, `0` llamadas al LLM ante banderas rojas clínicas).

---

## 3. Matriz de Variables de Entorno (`backend/.env.example`)

| Variable | Descripción | Obligatoria en Prod |
| :--- | :--- | :---: |
| `ENVIRONMENT` | Entorno de ejecución (`production`, `staging`, `development`) | Sí |
| `DATABASE_URL` | Cadena de conexión `postgresql+asyncpg://user:pass@host/db?ssl=require` | Sí |
| `FIREBASE_PROJECT_ID` | ID del proyecto en Firebase para validación de audiencia JWT | Sí |
| `R2_ENDPOINT_URL` | Endpoint S3 de Cloudflare R2 (`https://<account_id>.r2.cloudflarestorage.com`) | Sí |
| `R2_ACCESS_KEY_ID` | Access Key ID del token S3 de R2 | Sí |
| `R2_SECRET_ACCESS_KEY` | Secret Access Key del token S3 de R2 | Sí |
| `R2_BUCKET_NAME` | Nombre del bucket privado de documentos médicos | Sí |
| `GEMINI_API_KEY` | Llave de API para `google-genai` (`gemini-3.8-flash` / `gemini-embedding-2`) | Sí |

---

## 4. Empaquetado y Publicación Móvil (iOS / Android)

1. **Verificación de Código Generado y Pruebas:**
   ```bash
   cd mobile
   dart run build_runner build --delete-conflicting-outputs
   flutter analyze --fatal-infos
   flutter test --coverage
   ```
2. **Android App Bundle (`.aab`) / APK:**
   ```bash
   flutter build appbundle --release
   ```
3. **Privacidad y Permisos Nativos:**
   - **Biometría (`local_auth`):** Configurar `NSFaceIDUsageDescription` en `ios/Runner/Info.plist` y `USE_BIOMETRIC` en `android/app/src/main/AndroidManifest.xml`.
   - **Cifrado Local (`SQLCipher`):** La llave AES-256 se genera y resguarda en Keychain (iOS) / Keystore (Android) mediante `flutter_secure_storage`.

---

## 5. Verificación Post-Despliegue (Smoke Check)

1. `GET /api/v1/health` debe responder `200 OK` con `{"status": "healthy", "service": "cora-backend"}`.
2. Verificar sincronización de contrato OpenAPI 3.1:
   ```bash
   cd backend
   uv run pytest tests/contract tests/security tests/performance -v
   ```
