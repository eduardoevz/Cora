# Guía de Despliegue en Producción — Cora Backend en Render

**Versión:** v1.0.0  
**Fecha:** 2026-11-13  
**Plataforma Cloud:** [Render.com](https://render.com)  
**Base de Datos Administrada:** Neon Serverless PostgreSQL 16 + `pgvector`  

---

## 1. Resumen de la Arquitectura en Render

El backend de **Cora** está empaquetado como un contenedor Docker optimizado (`backend/Dockerfile`) que corre bajo un usuario seguro sin privilegios (`USER cora`), con soporte nativo para generación de reportes clínicos PDF vía **WeasyPrint** (con librerías del sistema Pango, Cairo y HarfBuzz) y conexión asíncrona a Neon PostgreSQL con extensión `pgvector`.

Render soporta dos modalidades de despliegue:
* **Modalidad A (Recomendada — Blueprint Automático):** Render lee `render.yaml` desde la raíz del repositorio, detecta el servicio web Docker, configura el puerto dinámico y ejecuta las migraciones de base de datos antes de enrutar tráfico.
* **Modalidad B (Manual desde Dashboard):** Creación directa de un "Web Service" conectado a tu repositorio en GitHub.

---

## 2. Variables de Entorno Requeridas en Render

Configura las siguientes variables en la sección **Environment** del servicio en Render:

| Variable | Valor / Ejemplo | Propósito |
| :--- | :--- | :--- |
| `ENVIRONMENT` | `production` | Activa modo estricto de producción y logs JSON estructurados. |
| `PORT` | `10000` (o automático de Render) | Puerto donde escucha Uvicorn dentro del contenedor. |
| `DATABASE_URL` | `postgresql://cora:pass@ep-xyz.us-east-2.aws.neon.tech/cora_prod?ssl=require` | Conexión a Neon PostgreSQL. Cora normaliza automáticamente a `postgresql+asyncpg://`. |
| `FIREBASE_PROJECT_ID` | `cora-health-prod` | Validación de emisor y audiencia en tokens JWT Bearer. |
| `FIREBASE_CREDENTIALS_JSON` | `{"type":"service_account",...}` *(Opcional)* | Permite pegar el JSON de la cuenta de servicio directamente sin montar archivos. |
| `R2_ENDPOINT_URL` | `https://<ACCOUNT_ID>.r2.cloudflarestorage.com` | Endpoint S3 compatible de Cloudflare R2 (cero costos de egress). |
| `R2_ACCESS_KEY_ID` | `<CLOUDFLARE_R2_ACCESS_KEY>` | Llave de acceso para la Carpeta Clínica Digital. |
| `R2_SECRET_ACCESS_KEY` | `<CLOUDFLARE_R2_SECRET_KEY>` | Llave secreta de Cloudflare R2. |
| `R2_BUCKET_NAME` | `cora-medical-records-prod` | Nombre del bucket R2 para PDFs y estudios médicos. |
| `GEMINI_API_KEY` | `AIzaSy...` | Llave de Google Gemini API (modelo `gemini-3.8-flash` con `store=False` y embeddings 768d). |

---

## 3. Paso a Paso para Desplegar

### Modalidad A: Vía Blueprint (`render.yaml`) — La más rápida

1. Inicia sesión en tu consola de [Render](https://dashboard.render.com).
2. Haz clic en **New +** (arriba a la derecha) y selecciona **Blueprint**.
3. Conecta tu repositorio de GitHub: `eduardoevz/Cora` (rama `main`).
4. Render detectará automáticamente el archivo `render.yaml` en la raíz.
5. Verás el servicio `cora-backend` con Docker runtime.
6. En la pantalla de revisión, Render te solicitará completar las variables de entorno marcadas con `sync: false` (Database URL, llaves de R2, Gemini, etc.).
7. Pega los valores de tus secretos reales y presiona **Apply**.
8. Render construirá la imagen Docker, ejecutará `preDeployCommand: alembic upgrade head` y desplegará el backend con HTTPS automático (`https://cora-backend-xxxx.onrender.com`).

---

### Modalidad B: Creación Manual como Web Service

Si prefieres crearlo manualmente:

1. En Render Dashboard, haz clic en **New +** -> **Web Service**.
2. Conecta el repositorio `eduardoevz/Cora`.
3. Configura los parámetros:
   * **Name:** `cora-backend`
   * **Region:** Elige la región más cercana a tu base de datos Neon (ej. `Ohio (US East)` o `Oregon (US West)`).
   * **Branch:** `main`
   * **Root Directory:** *(dejar vacío)*
   * **Runtime:** `Docker`
   * **Dockerfile Path:** `backend/Dockerfile`
   * **Docker Context:** `backend`
   * **Instance Type:** `Starter` ($7/mes) o `Free` (para pruebas).
4. En **Advanced**:
   * **Pre-Deploy Command:** `alembic upgrade head`
   * **Health Check Path:** `/api/v1/health`
5. Agrega las variables de entorno de la tabla de la Sección 2.
6. Haz clic en **Create Web Service**.

---

## 4. Ingesta Inicial del Corpus Clínico RAG en Producción

Una vez que tu servicio en Render esté desplegado y en estado **Live**, ejecuta la ingesta de las 6 guías clínicas canónicas (FIGO, ACOG, STRAW+10, EPDS, vacunas, fertilidad) apuntando a la base de datos de producción desde tu terminal local:

```powershell
cd backend
$env:DATABASE_URL = "postgresql+asyncpg://USUARIO:PASSWORD@ep-xyz.us-east-2.aws.neon.tech/cora_prod?ssl=require"
$env:GEMINI_API_KEY = "TU_GEMINI_API_KEY"
uv run python scripts/ingest_clinical_library.py
```

El script:
1. Conectará a Neon con pgvector.
2. Registrará los 6 artículos clínicos canónicos.
3. Generará los 21 embeddings vectoriales de 768 dimensiones usando `gemini-embedding-2`.
4. Dejará el asistente RAG listo para responder con citas clínicas verificadas.

---

## 5. Verificación de Despliegue con Smoke Tests

Verifica la disponibilidad, latencia y contrato OpenAPI de tu backend en producción ejecutando:

```powershell
cd backend
uv run python scripts/verify_deployment.py --base-url https://TU-SERVICIO.onrender.com
```

Salida esperada:
```text
[SMOKE CHECK] Verifying deployment at: https://cora-backend.onrender.com
✅ [PASSED] Healthcheck healthy (status=healthy, service=cora-backend, latency=142.30ms)
✅ [PASSED] OpenAPI schema valid (version=0.1.0, title=Cora Backend, endpoints=38)
🎉 All deployment smoke checks passed successfully!
```
