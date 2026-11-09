# Documentación de Cierre — Fase 05: Etapa 3: Búsqueda de Concepción y Fertilidad Avanzada

**Repositorio:** `eduardoevz/Cora`  
**Rama:** `main`  
**Fecha de Cierre:** 2026-11-09  
**Estado:** ✅ **Completada y Verificada (100% CI Green en GitHub Actions)**

---

## 1. Resumen Ejecutivo de la Fase

Durante la **Fase 05**, se implementó en Cora el subsistema integral de **Fertilidad y Búsqueda de Concepción** dentro de `clinical_tracking` para la **Etapa 3 de la vida** (`conception_search`). Este desarrollo conecta la base cíclica longitudinal construida en la Fase 4 con biomarcadores diarios objetivos (temperatura basal, consistencia del moco cervical y tiras reactivas de LH), permitiendo tanto la estimación prospectiva de la ventana fértil como la confirmación retrospectiva de la ovulación y la preparación preconcepcional integral de la pareja:

1. **Value Objects Biomédicos Inmutables:**
   - `BasalBodyTemperature`: exige escala estricta de dos decimales y valida el rango fisiológico humano ($35.00^\circ\text{C} - 42.00^\circ\text{C}$). Cualquier temperatura que viole estos límites levanta la excepción de dominio `InvalidBasalTemperatureError`.
   - **Discriminación Fisiológica de Fiebre y Perturbaciones:** Toda medición igual o superior a $38.00^\circ\text{C}$ se cataloga automáticamente como fiebre y se marca con `is_disturbed = True`. De igual forma, noches con privación severa de sueño ($< 3\text{h}$), consumo de alcohol o enfermedad son etiquetadas como perturbadas y **se excluyen categóricamente del cálculo de la línea base (*coverline*) y del salto térmico**, evitando falsos positivos de fase lútea.
   - `CervicalMucusType`: clasificación estandarizada según el método sintotérmico (`DRY`, `STICKY`, `CREAMY`, `WATERY`, `EGG_WHITE`), donde las texturas lubricantes/elásticas (`WATERY` y `EGG_WHITE`) denotan fertilidad óptima bajo estímulo estrogénico.
   - `LhStripResult`: catalogación de tiras reactivas urinarias de hormona luteinizante (`NEGATIVE`, `HIGH`, `PEAK`).
   - `IntercourseType`: registro de actividad (`NONE`, `UNPROTECTED`, `PROTECTED`, `INSEMINATION`) para correlación temporal con el momento de ovulación.
2. **Algoritmo Sintotérmico Determinista (`SymptothermalFertilityService`):**
   - **Regla "3 sobre 6":** Requiere 6 temperaturas basales consecutivas válidas (no perturbadas ni febriles) para trazar la línea base horizontal (*coverline* = $\max(\text{6 basales previas})$). La ovulación se confirma retrospectivamente cuando se registran 3 basales consecutivas por encima de la *coverline*, siendo la 3ª al menos $+0.20^\circ\text{C}$ superior a la misma. La ovulación queda fechada en el último día de temperatura basal baja.
   - **Tolerancia a Múltiples Picos de LH en Síndrome de Ovario Poliquístico (SOP):** Si la usuaria tiene diagnóstico base de SOP (establecido en la Capa 3 del Onboarding), el detector reconoce que pueden ocurrir múltiples oleadas de LH sin liberación folicular inmediata. En este caso, la tira positiva activa la ventana fértil tentativa pero **únicamente el salto térmico sostenido de la BBT confirma retrospectivamente la ovulación**, evitando diagnósticos precipitados y orientando a la usuaria con notas explicativas claras.
   - **Orientación Médica Preventiva según Edad y Duración de Búsqueda:**
     - Menores de 35 años: si registran $\ge 12$ meses de búsqueda activa, el servicio emite una recomendación empática para acudir a una consulta especializada en fertilidad (siguiendo directrices de ACOG y la OMS).
     - De 35 años o más: la sugerencia preventiva se activa a partir de los $\ge 6$ meses de búsqueda activa para optimizar tiempos y evaluar la reserva ovárica.
3. **Checklist de Salud Preconcepcional (`PreconceptionChecklist`):**
   - Basado en guías clínicas internacionales: adherencia al ácido fólico diario ($\ge 400\,\mu\text{g}$ iniciado 1 a 3 meses antes), revisión médica y analítica sanguínea (glucosa, tiroides, hemograma), inmunidad a la rubéola/vacunación, control odontológico periodontal, cese de hábitos tóxicos (alcohol/tabaco) y planificación de evaluación de fertilidad en pareja.
   - Cálculo del porcentaje de adherencia clínica (0 a 100%).
4. **Persistencia y Migración en Neon PostgreSQL:**
   - Creación de la migración reversible de Alembic `0005_create_fertility_logs_and_preconception.py`.
   - Creación de las tablas `daily_fertility_logs` y `preconception_checklists` con restricciones únicas e índices optimizados.
   - Migración aplicada y validada en vivo en Neon DB (`0004 -> 0005 (head)`).
5. **Cero Deriva en Contratos REST y OpenAPI:**
   - Puertos y adaptadores: `IFertilityRepository` y `PostgresFertilityRepository`.
   - Endpoints en `/api/v1/fertility/`:
     - `PUT /logs/{log_date}` (registro o actualización idempotente de BBT, LH, moco y coito).
     - `GET /chart` (curva térmica bifásica, *coverline*, estado ovulatorio y notas clínicas).
     - `GET /preconception-checklist` y `PATCH /preconception-checklist` (consulta y actualización parcial del checklist de recomendaciones).
   - Contrato `contracts/openapi.json` sincronizado con **0% de deriva**.
6. **Experiencia Móvil Offline-First en Flutter:**
   - Esquema Drift actualizado a **versión 5** con las tablas `DailyFertilityEntries` y `PreconceptionChecklistEntries`.
   - Repositorio `FertilityRepositoryImpl` con persistencia inmediata en SQLite local y encolado outbox en `SyncCoordinator`.
   - Widget interactivo `BbtBiphasicChartWidget` con `CustomPainter`: traza la curva de temperatura basal en línea continua en días consecutivos, dibuja segmentos punteados/discontinuos en días sin medición (sin inventar datos ficticios), y proyecta la línea base horizontal de *coverline*.
   - Pantalla principal `ConceptionHubPage` con selector de unidad (°C / °F), tarjeta de estado dinámico ("Baja", "Alta", "Pico de Fertilidad", "Ovulación Confirmada"), modal bottom sheet de registro diario rápido y acceso directo al checklist.
   - Pantalla interactiva `PreconceptionChecklistPage` con barra de progreso y checkboxes reactivos.
   - Integración automática de la tarjeta de Hub de Concepción en el *Home Dashboard* (`DynamicHomeDashboardPage`) cuando la etapa activa es `LifeStage.conceptionSearch`.

---

## 2. Arquitectura, Módulos y Archivos Implementados

### Backend (Monolito Modular Hexagonal en FastAPI)

```
backend/
├── alembic/versions/
│   └── 0005_create_fertility_logs_and_preconception.py      # Migración: daily_fertility_logs, preconception_checklists
├── app/
│   ├── main.py                                              # Registro de fertility_router
│   └── modules/
│       └── clinical_tracking/
│           ├── domain/
│           │   ├── exceptions/
│           │   │   └── clinical_tracking_exceptions.py      # InvalidBasalTemperatureError
│           │   ├── models/
│           │   │   └── preconception_checklist.py           # PreconceptionChecklist domain entity
│           │   ├── services/
│           │   │   └── symptothermal_fertility_service.py   # Motor sintotérmico: regla 3 sobre 6 y triaje
│           │   └── value_objects/
│           │       └── fertility_biomarkers.py              # BasalBodyTemperature, CervicalMucusType, LhStripResult
│           ├── application/
│           │   ├── dtos/
│           │   │   └── fertility_dtos.py                    # DTOs de chart, logs y checklist
│           │   ├── ports/
│           │   │   └── fertility_repository_port.py         # IFertilityRepository port
│           │   └── use_cases/
│           │       └── fertility_tracking_use_cases.py      # 4 casos de uso para logs, chart y checklist
│           └── infrastructure/
│               ├── orm/
│               │   └── fertility_orm.py                     # DailyFertilityLogModel y PreconceptionChecklistModel
│               ├── adapters/
│               │   └── postgres_fertility_repository.py     # Adaptador SQLAlchemy 2.0 Async
│               └── entrypoints/
│                   ├── fertility_schemas.py                 # Esquemas Pydantic v2
│                   └── fertility_router.py                  # Endpoints REST /api/v1/fertility/
└── tests/
    ├── unit/clinical_tracking/
    │   └── test_symptothermal_fertility_service.py          # 13 tests unitarios (TDD estricto)
    ├── integration/clinical_tracking/
    │   └── test_fertility_api.py                            # Tests de integración API y flujo sintotérmico
    └── contract/
        └── test_openapi_drift.py                            # Verificación 0% drift OpenAPI
```

### Mobile (Clean Architecture Feature-First en Flutter con Riverpod y Drift)

```
mobile/
├── lib/
│   ├── core/
│   │   └── database/
│   │       ├── app_database.dart                            # Esquema Drift v5 con tablas de fertilidad y checklist
│   │       └── app_database.g.dart                          # Código generado por drift_dev
│   └── features/
│       ├── dashboard/presentation/pages/
│       │   └── dynamic_home_dashboard_page.dart             # Tarjeta de Hub de Concepción y rutas de módulos
│       └── fertility/
│           ├── domain/entities/
│           │   └── fertility_chart_entity.dart              # DailyFertilityEntity, PreconceptionChecklistEntity
│           ├── data/
│           │   └── fertility_repository_impl.dart           # IFertilityRepository Drift + SyncCoordinator
│           └── presentation/
│               ├── providers/
│               │   └── fertility_providers.dart             # Providers Riverpod de fertilidad y chart local
│               ├── widgets/
│               │   └── bbt_biphasic_chart_widget.dart       # CustomPainter curva térmica con trazo discontinuo
│               └── pages/
│                   ├── conception_hub_page.dart             # Pantalla principal Hub de Concepción y registro rápido
│                   └── preconception_checklist_page.dart    # Pantalla interactiva del Checklist Preconcepcional
└── test/
    └── features/fertility/
        └── bbt_chart_and_conception_hub_test.dart           # Tests unitarios Drift v5 y widget tests
```

---

## 3. Pruebas y Verificación

### Backend
- **Pruebas unitarias de dominio (`test_symptothermal_fertility_service.py`):** 13 pruebas parametrizadas evaluando validación de temperatura basal (35.00 a 42.00 °C), conversiones a Fahrenheit, exclusión de fiebre ($38.50^\circ\text{C}$) de la línea base, regla "3 sobre 6" con coverline matemática, tolerancia de múltiples picos de LH en SOP sin ascenso térmico, y avisos empáticos por edad/tiempo de búsqueda.
- **Pruebas de integración REST (`test_fertility_api.py`):** Ingesta de 16 días de curva sintotérmica (6 basales bajas, pico de moco y LH, y 3 basales altas), respuesta del endpoint `/api/v1/fertility/chart` y actualización parcial del checklist.
- **Verificación OpenAPI:** `test_openapi_drift.py` en verde con 0% de discrepancia de tipos.
- **Total Suite Backend:** 82 pruebas pasando en $6.06\,\text{s}$, `ruff check` sin errores, `ruff format` verificado y `mypy --strict` pasando en 96 archivos fuente.

### Mobile
- **Pruebas de widget y base de datos local (`bbt_chart_and_conception_hub_test.dart`):** 4 pruebas verificando persistencia y recuperación en Drift v5, renderizado de huecos discontinuos en la curva térmica, visualización del Hub de Concepción y apertura del bottom sheet de registro, y alternancia reactiva en los ítems del checklist preconcepcional.
- **Calidad de Código:** `flutter analyze --fatal-infos` ejecutado con 0 errores, 0 warnings y 0 infos.
- **Total Suite Móvil:** 23 grupos de pruebas pasando en $10\,\text{s}$.

---

## 4. Historial de Commits Atómicos de la Fase

```
34c3054 feat(clinical-tracking): implement BBT value object and symptothermal fertility engine with TDD
368ec5b feat(clinical-tracking): add fertility biomarkers persistence, chart API, and preconception endpoints
49cc0bd feat(mobile-ui): add interactive BBT biphasic chart, LH/mucus logger, and preconception checklist
7929180 docs(plan): mark phase 05 tasks completed in phase spec and roadmap
```

---

## 5. Preparación para la Siguiente Fase

Con la **Fase 05** completada y la persistencia en Neon DB en la revisión `0005`:
- Cora cuenta con el subdominio completo de **Búsqueda de Concepción (Etapa 3)**, tanto a nivel de algoritmos clínicos de ovulación como de experiencia interactiva en Flutter.
- El repositorio `IFertilityRepository` y los datos de biomarcadores quedan listos para ser consumidos en la **Fase 09** (*Doctor-Ready PDF*) y en la **Fase 11** (*Partner View* para compartir ventana fértil selectivamente con la pareja).
- La arquitectura se encuentra lista para avanzar hacia la **Fase 06: Etapa 4 — Embarazo y Cuidado Materno** (`maternal_care`), incorporando el desarrollo fetal semanal, signos vitales maternos, detección de preeclampsia según ACOG y plan de parto interactivo.
