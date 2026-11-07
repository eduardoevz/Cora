# Guía de Arquitectura y Especificación Técnica: Cora (`desarrollo.md`)

Este documento define la base tecnológica, patrones arquitectónicos, metodologías y estándares de ingeniería para el desarrollo del ecosistema **Cora**. Actúa como directriz técnica estricta para desarrolladores y agentes de código en Antigravity junto con las reglas en `.agents/rules/`.

---

## 1. Stack Tecnológico Oficial

| Capa | Tecnología | Propósito y Justificación |
| :--- | :--- | :--- |
| **Frontend Móvil** | **Flutter 3.x** (Dart 3.x) | Código base único para iOS y Android. Renderizado de alto rendimiento para gráficas hormonales interactivas, accesibilidad escalable y animaciones fluidas. |
| **Gestión de Estado Móvil** | **Riverpod** (`riverpod_annotation` + `AsyncNotifier`) | Separación estricta entre presentación y dominio mediante flujos reactivos unidireccionales, inyección de dependencias declarativa e integración directa con streams de Drift. |
| **Persistencia Local (Móvil)** | **Drift** (SQLite relacional + SQLCipher) | Soporte *Offline-First* con cifrado local en reposo. Permite consultas estructuradas reactivas y cola transaccional de sincronización asíncrona (`sync_outbox`). |
| **Backend Framework** | **FastAPI** (Python 3.12+) | API REST asíncrona de alto rendimiento con tipado estricto en Pydantic v2, respuestas de error RFC 7807 y generación automática de contratos OpenAPI 3.1. |
| **ORM / Data Access** | **SQLAlchemy 2.0 (Asyncio)** + **Alembic** | Mapeo objeto-relacional 100% asíncrono (`asyncpg`) con control formal y reversible de migraciones de base de datos. |
| **Base de Datos Principal** | **Neon (PostgreSQL Serverless)** | Postgres gestionado *scale-to-zero* con auto-resume en milisegundos y aislamiento multi-tenant estricto por `user_id`. |
| **Motor Vectorial (RAG)** | **`pgvector`** (en Neon con índice HNSW) | Almacenamiento e indexación vectorial de literatura médica verificada directamente en PostgreSQL, sin clusters externos. |
| **Almacenamiento de Objetos** | **Cloudflare R2** | Almacenamiento compatible con S3 para estudios clínicos, ecografías y PDFs mediante URLs prefirmadas (*zero-egress*). |
| **Autenticación** | **Firebase Authentication** | Gestión del ciclo de vida de credenciales (correo/contraseña y Google OAuth). El backend valida criptográficamente los JWT emitidos. |
| **Motor de IA / RAG Clínico** | **Google GenAI SDK (`google-genai >= 2.30.1`)** | Adaptador hexagonal directo con **`gemini-3.8-flash`** (`client.interactions.create` con `store=False` para privacidad PHI) y **`gemini-embedding-2`** (`client.models.embed_content`, dimensiones normalizadas 768/1536). |
| **Generación de Reportes** | **WeasyPrint** + **Jinja2** | Renderizado de informes clínicos *Doctor-Ready PDF* (1–2 páginas) a partir de plantillas HTML/CSS de alta legibilidad médica. |
| **CI/CD & Calidad** | **GitHub Actions** + **Docker** | Ejecución automatizada de `ruff`, `mypy --strict`, `pytest` (unit + integration con `pgvector`), `flutter analyze`, `flutter test`, verificación de contrato OpenAPI y plantillas CD. |

---

## 2. Arquitectura del Sistema

### 2.1. Backend: Monolito Modular con Arquitectura Hexagonal (Puertos y Adaptadores)

El backend se organiza en **9 módulos de negocio desacoplados (*Bounded Contexts*)** que cubren el 100% de `docs/SPECS.MD`. Cada módulo contiene su propio hexágono con inversión estricta de dependencias: la capa `domain/` no tiene dependencias de FastAPI, SQLAlchemy ni SDKs externos.

```text
backend/app/modules/<modulo>/
├── domain/                      # Capa más interna: reglas clínicas y de negocio puras
│   ├── models/                  # Entidades y Agregados con identidad única
│   ├── value_objects/           # Objetos inmutables validados (ej. BloodPressure, MenstrualCycle)
│   ├── services/                # Motores deterministas de dominio (ej. FIGO, ACOG, EPDS)
│   └── exceptions/              # Excepciones semánticas de dominio
│
├── application/                 # Casos de uso y orquestación
│   ├── use_cases/               # Clases enfocadas con un método execute()
│   ├── dtos/                    # Contratos internos de entrada/salida
│   └── ports/                   # Interfaces abstractas (typing.Protocol / ABC)
│       ├── repository_port.py   # Contrato de persistencia
│       └── service_port.py      # Contrato de servicios externos (R2, Gemini, Auth)
│
└── infrastructure/              # Capa externa: implementaciones concretas
    ├── orm/                     # Modelos SQLAlchemy 2.0 y mappers Dominio <-> ORM
    ├── adapters/                # Implementaciones concretas (Neon, Cloudflare R2, Gemini)
    └── entrypoints/             # Routers HTTP FastAPI y Schemas Pydantic (OpenAPI)
```

#### Los 9 Módulos de Negocio Definidos

1. `identity`: Gestión de perfil, validación Firebase JWT, onboarding progresivo de 3 capas, `LifeStageStateMachine`, preferencias modulares (*Modularidad a la Carta*) y exportación/purga irreversible de cuenta.
2. `clinical_tracking`: Registros diarios transversales de bienestar/hábitos, ciclo menstrual de 4 fases, etapa Adolescencia, etapa Juventud/Reproductiva (SOP/Endometriosis), etapa Búsqueda de Concepción (TBC, moco cervical, LH) y motor preventivo de patrones atípicos (criterios FIGO).
3. `maternal_care`: Etapa Embarazo (desarrollo fetal semana a semana, monitor materno PA/peso/glucosa con alertas ACOG de preeclampsia y diabetes gestacional, contracciones, patadas, plan de parto) y etapa Posparto (loquios, cicatrices, lactancia y escala EPDS).
4. `mature_health`: Etapa Perimenopausia/Menopausia (transición STRAW+10, sofocos, sueño, impacto de TRH, marcadores cardiometabólicos) y etapa Plenitud/Adulta Mayor (salud ósea/osteoporosis, riesgo de caídas, salud uroginecológica y contacto de soporte familiar).
5. `treatments`: Pastillero virtual, anticonceptivos hormonales/DIU/implante, suplementación por etapa, medicación crónica, cálculo de adherencia y programación de recordatorios.
6. `medical_records`: Carpeta clínica digital (exámenes preventivos parametrizados por edad, cartilla de vacunación, directorio de especialistas), integración con Cloudflare R2 (`IFileStorage`) y generador de reportes *Doctor-Ready PDF*.
7. `education_content`: Biblioteca clínica curada basada en evidencia (OMS, ACOG, FIGO), categorizada por etapa de vida y utilizada como corpus verificado para el motor RAG.
8. `rag_assistant`: `DeterministicSafetyInterceptor` de triaje de urgencias, búsqueda semántica HNSW en `pgvector` (`gemini-embedding-2`) y generación conversacional (`gemini-3.8-flash`, `store=False`) cruzando el historial privado de la usuaria con citas científicas verificables.
9. `partner_sharing`: Modo Acompañante / Pareja (*Partner View*) mediante invitaciones efímeras y proyección de solo lectura con permisos granulares revocables en tiempo real.

### 2.2. Frontend: Clean Architecture Feature-First + Estrategia *Offline-First*

La aplicación móvil se estructura en tres capas por funcionalidad: **Presentation** (Riverpod + Widgets), **Domain** (Dart puro) y **Data** (Drift + Sync Outbox + Remote API).

```text
mobile/lib/features/<feature>/
├── presentation/                # Pages, Widgets accesibles y Providers/Notifiers Riverpod
├── domain/                      # Entidades inmutables, Repositorios abstractos y UseCases (Dart puro)
└── data/                        # Repositorios concretos, DAOs Drift locales y DataSources remotos
```

* **Estrategia Offline-First Idempotente:** Toda escritura del usuario se guarda transaccionalmente en **Drift (SQLite)** junto con un evento en `sync_outbox` identificado por un `client_mutation_id` (UUIDv7). Un sincronizador en segundo plano envía los lotes pendientes cuando vuelve la conectividad, garantizando cero pérdida de datos y cero duplicados ante reintentos de red.

---

## 3. Metodologías y Prácticas de Ingeniería

### 3.1. Spec-Driven Development (SDD)
* La API sigue un diseño **Contract-First**: los esquemas Pydantic en FastAPI generan el documento `openapi.json` versionado.
* Los modelos DTO y clientes HTTP en Flutter se generan/verifican contra `openapi.json`, y GitHub Actions falla si existe deriva de contrato entre backend y móvil.

### 3.2. Test-Driven Development (TDD) en Lógica Biomédica
* Toda regla ginecológica, obstétrica o de triaje (FIGO, ACOG, STRAW+10, EPDS, ventana fértil) exige ciclo **Red-Green-Refactor** estricto.
* Los tests unitarios de dominio son parametrizados y se ejecutan en `< 50 ms` sin base de datos ni red (`>= 95%` de cobertura en `domain/`).

### 3.3. Domain-Driven Design (DDD) y Empatía Clínica
* **Lenguaje Ubicuo en Código:** Identificadores técnicos en inglés clínico formal (`MenstrualCycle`, `FollicularPhase`, `LutealPhase`, `BasalBodyTemperature`, `BloodPressure`, `LifeStage`).
* **Comunicación en Interfaz:** Español claro, cálido, inclusivo, libre de estigmas y **no alarmista**, recomendando valoración médica profesional oportuna sin emitir diagnósticos definitivos.

---

## 4. Patrones de Diseño Clave

1. **State Machine Pattern (`LifeStageStateMachine`):** Rige las transiciones entre las 7 etapas de vida archivando ciclos/etapas previas y recalibrando el dashboard sin destruir jamás el historial longitudinal.
2. **Repository Pattern:** Los casos de uso dependen exclusivamente de puertos abstractos (`IClinicalRepository`, `IMaternalRepository`), permitiendo dobles de prueba en memoria ultrarrápidos.
3. **Deterministic Safety Interceptor (Triaje de Emergencia RAG):** Filtro determinista previo al LLM que intercepta banderas rojas (hemorragia severa, dolor pélvico agudo súbito, signos de preeclampsia severa, ideación autolesiva) y retorna una directiva inmediata de urgencias médicas en `< 5 ms` sin llamar a Gemini.
4. **Adapter Pattern (`IFileStorage`, `IAiClinicalAssistant`):** Encapsula Cloudflare R2 y Google GenAI SDK en la capa `infrastructure/adapters/`.

---

## 5. Estructura Completa del Monorepo

```text
Cora/
├── .agents/
│   └── rules/                           # Reglas modulares nativas para Antigravity
├── .github/
│   └── workflows/                       # Pipelines de CI/CD en GitHub Actions
├── docs/
│   ├── SPECS.MD                         # Especificación funcional del producto
│   ├── desarrollo.md                    # Especificación arquitectónica y técnica
│   └── phases/                          # Planes detallados ejecutables por fase (01 a 12)
├── documentacion/                       # Bitácora oficial de lo construido al finalizar cada fase
├── backend/
│   ├── alembic/                         # Migraciones asíncronas de PostgreSQL + pgvector
│   ├── app/
│   │   ├── core/                        # Settings, AsyncSession, Firebase JWT, RFC 7807
│   │   ├── modules/                     # Los 9 módulos hexagonales de negocio
│   │   └── main.py                      # Composición de aplicación FastAPI
│   ├── tests/
│   │   ├── unit/                        # Tests puros de dominio (TDD clínico)
│   │   ├── integration/                 # Tests con PostgreSQL + pgvector real
│   │   └── contract/                    # Validación de esquema OpenAPI
│   ├── Dockerfile
│   └── pyproject.toml
├── mobile/
│   ├── lib/
│   │   ├── core/                        # Drift DB, SyncQueue, HTTP Client, Design System, Biometría
│   │   └── features/                    # Módulos Feature-First con Riverpod
│   ├── test/                            # Unit & Widget tests
│   ├── integration_test/                # Flujos E2E completos
│   └── pubspec.yaml
├── AGENTS.md                            # Regla raíz del proyecto para Antigravity
└── README.md                            # Documentación principal del repositorio público
```

---

## 6. Variables de Entorno Requeridas (Plantilla de Referencia)

> **Nota de Seguridad:** Nunca subir valores reales al repositorio público `Cora`. Configurar localmente en `.env` (ignorado por Git) y en `GitHub Secrets` para CI/CD.

```bash
# Base de Datos (Neon PostgreSQL con pgvector)
DATABASE_URL=postgresql+asyncpg://<user>:<password>@<neon-host>/<dbname>?sslmode=require

# Firebase Auth (Verificación criptográfica de JWT)
FIREBASE_PROJECT_ID=cora-health-app
FIREBASE_CREDENTIALS_PATH=./secrets/firebase_service_account.json

# Cloudflare R2 (Object Storage S3-Compatible)
R2_ACCOUNT_ID=<cloudflare-account-id>
R2_ACCESS_KEY_ID=<access-key>
R2_SECRET_ACCESS_KEY=<secret-key>
R2_BUCKET_NAME=cora-medical-documents
R2_ENDPOINT_URL=https://<account-id>.r2.cloudflarestorage.com

# Motor de IA / RAG Clínico (Google GenAI SDK >= 2.30.1)
GEMINI_API_KEY=<gemini-api-key>
GEMINI_GENERATION_MODEL=gemini-3.8-flash
GEMINI_EMBEDDING_MODEL=gemini-embedding-2
GEMINI_EMBEDDING_DIMENSIONS=768
GEMINI_STORE_INTERACTIONS=false
```
