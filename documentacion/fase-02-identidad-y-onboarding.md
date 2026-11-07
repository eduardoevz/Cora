# Documentación de Cierre — Fase 02: Identidad, Onboarding de 3 Capas y LifeStage Navigation

**Repositorio:** `eduardoevz/Cora`  
**Rama:** `main`  
**Fecha de Cierre:** 2026-11-07  
**Estado:** ✅ **Completada y Verificada en GitHub Actions (100% CI Green)**

---

## 1. Resumen Ejecutivo de la Fase

Durante la **Fase 02**, se implementó de forma completa el módulo acotado `identity` de **Cora**, estableciendo los cimientos biomédicos, de seguridad y de experiencia de usuario para toda la plataforma:

1. **Autenticación Biomédica y Seguridad JWT:** Integración de verificación criptográfica de tokens Firebase Auth (`firebase-admin`), abstrayendo el verificador tras el puerto `ITokenVerifier` y exponiendo el inyector de dependencias FastAPI `CurrentUserDep` (`AuthenticatedUser`). Se implementó un modo mock determinista para entornos de testing y desarrollo local.
2. **Onboarding Progresivo de 3 Capas:** Flujo de calibración clínica empática:
   - *Capa 1 (Identidad y Etapa Inicial):* Registro de nombre, apellido, año de nacimiento y etapa de vida inicial.
   - *Capa 2 (Prioridades Inmediatas):* Selección estricta de 1 a 3 intenciones de salud (`PrimaryIntent`), bloqueando intentos de omitir o exceder el límite tanto en el Value Object del backend como en la interfaz móvil.
   - *Capa 3 (Contexto Clínico Base):* Registro opcional y diferible ("Responder después") de métodos anticonceptivos/hormonales (`HormonalMethod`) y condiciones diagnosticadas (`DiagnosedCondition`: SOP, Endometriosis, Tiroides, Resistencia a la insulina/Diabetes), asegurando que ninguna usuaria sea bloqueada.
3. **Máquina de Estados Longitudinal (`LifeStageStateMachine`):** Motor de dominio determinista que gobierna las 7 etapas biológicas de Cora (`adolescence`, `regular_adult`, `conception_search`, `pregnancy`, `postpartum`, `perimenopause`, `senior_vitality`). Cada transición valida la coherencia etaria, archiva un registro inmutable en el historial (`LifeStageTransition`) con marca de tiempo UTC y motivo (`TransitionReason`), y computa los módulos activos correspondientes. Contempla transiciones sensibles (como `pregnancy -> postpartum` por parto o `pregnancy -> regular_adult` por pérdida gestacional) ajustando de inmediato el tono y suspendiendo alertas perinatales para prevenir daño emocional.
4. **Persistencia PostgreSQL y Contrato OpenAPI:** Modelado relacional ORM en SQLAlchemy 2.0 Async, migración reversible de Alembic `0002_create_identity_tables.py`, adaptador `PostgresUserProfileRepository` y 4 endpoints REST asegurados con RFC 7807 (`ProblemDetails`) y 0% deriva OpenAPI.
5. **Experiencia Móvil Flutter Offline-First:** Tablas locales Drift SQLite (`user_profile_entries`, `life_stage_transition_entries`), sincronización encolada en `SyncCoordinator`, providers reactivos de Riverpod, asistente de onboarding en 3 pasos (`OnboardingWizardPage`), conmutador modal de etapas (`LifeStageSwitcherSheet`), gestor de módulos a la carta (`ModulePreferencesPage`) y pantalla principal adaptativa (`DynamicHomeDashboardPage`) validada bajo escalado de texto de accesibilidad 2.0x.

---

## 2. Arquitectura, Módulos y Archivos Implementados

### Backend (Monolito Modular Hexagonal en FastAPI)

```
backend/
├── alembic/versions/
│   └── 0002_create_identity_tables.py                  # Migración reversible (tablas user_profiles y life_stage_transitions)
├── app/
│   ├── core/
│   │   ├── errors.py                                   # Excepciones RFC 7807 (EntityNotFoundError, ConflictError)
│   │   └── security.py                                 # AuthenticatedUser y dependencia CurrentUserDep
│   ├── modules/
│   │   └── identity/
│   │       ├── domain/
│   │       │   ├── exceptions/identity_exceptions.py   # InvalidOnboardingGoalsError, InvalidLifeStageTransitionError, etc.
│   │       │   ├── models/user_profile.py              # Entidad UserProfile y LifeStageTransition inmutable
│   │       │   ├── services/life_stage_state_machine.py# Máquina de estados determinista de las 7 etapas biológicas
│   │       │   └── value_objects/
│   │       │       ├── life_stage.py                   # LifeStage y TransitionReason (StrEnum)
│   │       │       └── onboarding_context.py           # OnboardingContext, PrimaryIntent, HormonalMethod, DiagnosedCondition
│   │       ├── application/
│   │       │   ├── dtos/identity_dtos.py               # DTOs de entrada y respuesta de casos de uso
│   │       │   ├── ports/token_verifier_port.py        # Puerto abstracto ITokenVerifier
│   │       │   ├── ports/user_profile_repository_port.py# Puerto abstracto IUserProfileRepository
│   │       │   └── use_cases/
│   │       │       ├── complete_onboarding_use_case.py # Orquestación de onboarding progresivo
│   │       │       ├── get_user_profile_use_case.py    # Consulta de perfil e historial
│   │       │       ├── switch_life_stage_use_case.py   # Conmutación de etapa con validación clínica
│   │       │       └── update_module_preferences_use_case.py # Activación/pausa de módulos a la carta
│   │       └── infrastructure/
│   │           ├── adapters/
│   │           │   ├── firebase_token_verifier.py      # Adaptador ITokenVerifier (Firebase SDK + Mock)
│   │           │   └── postgres_user_profile_repository.py # Adaptador SQLAlchemy 2.0 Async
│   │           ├── entrypoints/
│   │           │   ├── router.py                       # Endpoints /api/v1/identity (GET /me, PUT /onboarding, etc.)
│   │           │   └── schemas.py                      # Esquemas Pydantic v2 de entrada y salida
│   │           └── orm/
│   │               └── identity_models.py              # Mappings ORM (UserProfileModel, LifeStageTransitionModel)
contracts/
└── openapi.json                                        # Contrato OpenAPI 3.1.0 regenerado sin deriva
```

### Mobile (Clean Architecture Feature-First + Riverpod + Drift en Flutter)

```
mobile/
├── lib/
│   ├── core/
│   │   └── database/
│   │       ├── app_database.dart                       # Esquema Drift v2 (UserProfileEntries, LifeStageTransitionEntries)
│   │       └── app_database.g.dart                     # Código generado por drift_dev
│   └── features/
│       ├── dashboard/
│       │   └── presentation/
│       │       ├── pages/dynamic_home_dashboard_page.dart # Home Dashboard adaptativo por etapa y módulos activos
│       │       └── widgets/
│       │           ├── life_stage_switcher_sheet.dart  # Modal bottom-sheet para transición de etapas
│       │           └── module_preferences_page.dart    # Ajustes de módulos visibles a la carta
│       └── onboarding/
│           ├── data/
│           │   ├── local/profile_dao.dart              # DAO Drift para UserProfile y transiciones
│           │   └── repositories/identity_repository_impl.dart # Repositorio Offline-First con outbox sync
│           ├── domain/
│           │   ├── entities/user_profile_entity.dart   # Entidades inmutables Dart (UserProfileEntity, LifeStage, etc.)
│           │   └── repositories/identity_repository.dart# Contrato abstracto del repositorio de identidad
│           └── presentation/
│               ├── pages/onboarding_wizard_page.dart   # Asistente visual de 3 capas con límites de chips
│               └── providers/identity_providers.dart   # Providers Riverpod (activeUserProfileProvider, etc.)
```

---

## 3. Decisiones Técnicas y Reglas Clínicas Aplicadas

1. **Validación de Capa 2 en el Núcleo Puro (`OnboardingContext`):**
   - Para salvaguardar la pureza hexagonal (Regla 02), la restricción biomédica de seleccionar entre 1 y 3 metas principales se valida dentro del Value Object inmutable `@dataclass(frozen=True) OnboardingContext`. Si la lista de intenciones está vacía o contiene más de 3 elementos, arroja `InvalidOnboardingGoalsError`, el cual el router mapea a un error RFC 7807 (`status=400`, `code=invalid_onboarding_goals`).
2. **Inmutabilidad y Preservación Longitudinal de Transiciones:**
   - La salud femenina es un continuo que nunca debe ser sobrescrito o borrado. Cada cambio de etapa en `LifeStageStateMachine` no elimina el historial anterior: se añade una nueva tupla a `life_stage_transitions` con el motivo clínico (`natural_progression`, `conception_confirmed`, `childbirth`, `pregnancy_loss`, `user_manual_selection`) y fecha UTC, manteniendo la trazabilidad histórica de la paciente.
3. **Manejo Empático de Transiciones Sensibles:**
   - Ante eventos perinatales críticos (como pérdida gestacional `PREGNANCY -> REGULAR_ADULT`), la máquina de estados desactiva de inmediato los módulos de desarrollo fetal y contador de pataditas, asignando los módulos ginecológicos regulares y permitiendo al frontend mitigar cualquier impacto emocional negativo.
4. **Compatibilidad Multi-Motor en Base de Datos (JSON Variant):**
   - En `UserProfileModel` y la migración `0002`, los campos `primary_intents`, `diagnosed_conditions` y `enabled_modules` utilizan `JSON().with_variant(JSONB, "postgresql")`. Esto asegura compatibilidad nativa con SQLite en memoria (`sqlite:///:memory:`) para pruebas unitarias hiper-rápidas y con PostgreSQL 16 `JSONB` en producción.
5. **Offline-First y Encolamiento Idempotente Móvil:**
   - En Flutter, el usuario puede completar su onboarding o conmutar de etapa biológica en modo avión. La acción se almacena inmediatamente en Drift SQLite local y encola una mutación en `SyncOutboxEntries` con un `client_mutation_id` tipo UUID v4 para sincronización posterior idempotente con el servidor.

---

## 4. Pruebas Ejecutadas y Validación CI/CD

### Pruebas Locales

- **Backend Pytest (Unitarias, Integración y Contrato OpenAPI):**
  - **35 pruebas pasando (100%)** con **88% de cobertura de código**.
  - `test_life_stage_state_machine.py`: 6 pruebas parametrizadas validando transiciones legales, bloqueo de transiciones anómalas, módulos por defecto y preservación de historial.
  - `test_onboarding_validation.py`: 10 pruebas unitarias de validación etaria, límites de intenciones (0, 1..3, 4) y opcionalidad de Capa 3.
  - `test_identity_use_cases.py`: 7 pruebas unitarias de casos de uso y verificación JWT con mock.
  - `test_identity_api.py`: 7 pruebas de integración HTTP en FastAPI contra base de datos.
  - `test_openapi_drift.py`: 0% deriva entre esquemas Pydantic y `contracts/openapi.json`.
- **Backend Linting y Tipado Estricto:**
  - `ruff check backend` → 0 errores.
  - `ruff format --check backend` → 0 discrepancias.
  - `mypy --strict backend/app` → 0 errores de tipos en 28 archivos de producción.
- **Mobile Flutter (Tests Unitarios, Accesibilidad y Widgets):**
  - **9 pruebas pasando (100%)**.
  - `onboarding_wizard_test.dart`: validación de límite de 1 a 3 intenciones (chips) y skipping de Capa 3 con botón "Responder después".
  - `dynamic_dashboard_test.dart`: renderizado reactivo de tarjetas dinámicas según etapa (`pregnancy` vs `senior_vitality`) y verificación de diseño sin desbordamientos (`takeException() == null`) bajo escalado de texto de accesibilidad a **2.0x**.
  - `sync_outbox_test.dart` y `theme_accessibility_test.dart`: pruebas de sincronización y temas WCAG AAA.
  - `flutter analyze --fatal-infos` → 0 warnings o infos en todo `mobile/lib/` y `mobile/test/`.

### Verificación en Tiempo Real de GitHub Actions CI/CD

Al realizar el push de los commits de la Fase 02, se monitorearon en vivo los flujos de trabajo de GitHub Actions, certificando el pase en verde al 100%:

| Workflow | Run ID | Commit | Duración | Estado |
| :--- | :--- | :--- | :--- | :--- |
| **Mobile CI** | `42407851026` | `67d62fa` | 1m 54s | ✅ `completed success` |
| **Backend CI** | `42407850990` | `67d62fa` | 51s | ✅ `completed success` |
| **Security & OpenAPI Contract** | `42407850916` | `67d62fa` | 15s | ✅ `completed success` |

---

## 5. Secuencia de Commits Realizados

Historial trazable y atómico de commits correspondientes a la Fase 02:

1. `f67956d` — `feat(identity): implement 3-layer onboarding domain models and LifeStageStateMachine with TDD`
2. `1bffa00` — `feat(identity): add Firebase JWT verification and onboarding/stage-switching use cases`
3. `1fc2dcd` — `feat(identity): add PostgreSQL persistence, REST endpoints, and OpenAPI schemas for identity`
4. `65a1a9b` — `feat(mobile-ui): build 3-layer onboarding wizard, life-stage switcher, and dynamic dashboard`
5. `a91bf5b` — `chore(backend): update uv.lock with firebase-admin dependency`
6. `67d62fa` — `docs(plan): mark phase 02 tasks completed in phase spec and roadmap`

---

## 6. Estado para la Siguiente Fase

Con la culminación y verificación de la **Fase 02**, la plataforma Cora cuenta con:

- Módulo `identity` completamente funcional, desacoplado y blindado contra suplantación de identidad mediante `CurrentUserDep`.
- Puerto `IUserProfileRepository` disponible para que futuros módulos consulten la etapa activa y diagnósticos base (SOP, Endometriosis) de cualquier usuaria.
- `activeUserProfileProvider` y `enabledModulesProvider` disponibles en Flutter para condicionar la navegación, vistas y módulos secundarios.
- Flujo de base de datos local y remota preparado para recibir los módulos clínicos transversales.

El repositorio queda 100% listo para iniciar la **Fase 03: Bienestar Transversal, Hábitos Diarios y Gestor de Tratamientos/Fármacos (`clinical_tracking` base y `treatments`)**.
