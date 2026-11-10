# Documentación de Cierre — Fase 07: Etapa 5: Posparto, Lactancia y Salud Mental Materna (El Cuarto Trimestre)

**Repositorio:** `eduardoevz/Cora`  
**Rama:** `main`  
**Fecha de Cierre:** 2026-11-10  
**Estado:** ✅ **Completada y Verificada (100% CI Green en GitHub Actions)**

---

## 1. Resumen Ejecutivo de la Fase

Durante la **Fase 07**, se expandió el bounded context hexagonal **`maternal_care`** para acompañar la **Etapa 5 de la vida: Posparto y Crianza Inicial ("El Cuarto Trimestre")**. Este período biológico crítico aborda los tres pilares fundamentales de la salud puerperal:

1. **Recuperación Física Puerperal y Banderas Rojas Fisiológicas:**
   - **Evolución fisiológica de los loquios:** progresión esperada a través de las etapas `RUBRA` (días 1–4, sangrado rojo oscuro/abundante), `SEROSA` (días 4–10, flujo rosado/marronáceo) y `ALBA` (días 10–28+, secreción amarillenta/blanquecina o ausente).
   - **Hemorragia posparto secundaria:** alerta de urgencia inmediata (`URGENT_EMERGENCY`) ante el empapado de una compresa grande en menos de 1 hora o presencia de coágulos abundantes de gran tamaño.
   - **Infección puerperal / Endometritis:** detección inmediata ante la combinación de fiebre materna ($\ge 38.0^\circ\text{C}$) y loquios de olor fétido, orientando derivación médica hospitalaria sin demoras.
   - **Cicatrización de heridas quirúrgicas y perineales:** detección de dehiscencia (apertura de suturas) o secreción purulenta en episiotomías/desgarros y heridas de cesárea.
   - **Suelo pélvico:** registro de incontinencia fecal, urinaria o sensación de prolapso/pesadez vaginal para derivación oportuna a fisioterapia especializada.

2. **Lactancia Materna y Banco de Leche Inteligente (FIFO):**
   - **Cronómetro interactivo ergonómico de doble pecho:** optimizado para el uso nocturno con una sola mano mediante blancos táctiles de altura $\ge 56\,\text{dp}$, indicador del pecho sugerido para la siguiente toma (prevención de ingurgitación mastítica) y registro de duración por lado o biberón.
   - **Banco de leche extraída con caducidad automatizada CDC/OMS:** almacenamiento por lote con cálculo riguroso del tiempo de expiración según la ubicación térmica:
     - Temperatura ambiente ($\le 25^\circ\text{C}$): hasta 4 horas.
     - Refrigerador ($4^\circ\text{C}$): hasta 4 días.
     - Congelador estándar ($-18^\circ\text{C}$): hasta 6 meses (180 días).
     - Ultracongelador profundo: hasta 12 meses (365 días).
   - **Consumo bajo principio First-In, First-Out (FIFO):** consulta ordenada por lote más próximo a caducar y acción de marcado de consumo en un toque.

3. **Salud Mental Perinatal y Escala de Edimburgo (EPDS):**
   - Implementación estandarizada de los 10 ítems de la *Edinburgh Postnatal Depression Scale* ($0 - 30$ puntos) con puntuación normal para ítems 1, 2, 4 e invertida para ítems 3, 5, 6, 7, 8, 9, 10.
   - **Regla clínica innegociable de contención en crisis:** si el **Ítem 10 (pensamientos de autolesión o ideación suicida)** es $> 0$ ($1, 2$ o $3$ puntos), el sistema clasifica de forma **incondicional e inmediata** el resultado como `IMMEDIATE_CRISIS_SUPPORT` con despliegue visible de la Línea de Apoyo y Contención en Crisis 24/7 (800 911 2000), sin importar si la puntuación global fue baja.
   - Categorización del tamizaje: $0–9$ (Tranquilizador / bienestar adecuado), $10–12$ (Atención preventiva / seguimiento en 2 semanas), $\ge 13$ (Riesgo alto de depresión mayor posparto / derivación prioritaria).

4. **Persistencia PostgreSQL y Migración en Neon DB:**
   - Migración de Alembic `0007_create_postpartum_lactation_epds_tables.py` aplicada exitosamente en Neon (`0006 -> 0007 (head)`).
   - Tablas creadas: `postpartum_recovery_logs`, `lactation_sessions`, `milk_stash_entries`, `epds_screenings`.
   - Compatibilidad total con UUID en relaciones de clave foránea a `user_profiles.id`.

5. **Experiencia Móvil Offline-First en Flutter:**
   - Esquema Drift actualizado a **versión 7** con 4 tablas locales idénticas.
   - `PostpartumOfflineEvaluator` y `EpdsOfflineScoringService`: motores deterministas espejo en Dart para alertas clínicas inmediatas sin esperar respuesta de red.
   - Pantallas: `PostpartumRecoveryPage`, `LactationAndMilkBankPage`, `EpdsMentalHealthPage`.
   - Integración nativa en `DynamicHomeDashboardPage` cuando la etapa activa es `LifeStage.postpartum`.

---

## 2. Arquitectura, Módulos y Archivos Implementados

### Backend (FastAPI + Arquitectura Hexagonal)

```
backend/
├── alembic/versions/
│   └── 0007_create_postpartum_lactation_epds_tables.py           # Migración PostgreSQL Neon
├── app/
│   ├── main.py                                                   # Registro del router /api/v1/postpartum
│   └── modules/
│       └── maternal_care/
│           ├── domain/
│           │   ├── value_objects/
│           │   │   └── postpartum_observations.py                # Enums, LochiaStage, PostpartumClinicalAlert
│           │   ├── models/
│           │   │   └── lactation_and_milk_stash.py               # LactationSession, MilkStashEntry
│           │   └── services/
│           │       ├── postpartum_recovery_evaluator.py          # Alertas de hemorragia, endometritis, dehiscencia
│           │       └── epds_screening_service.py                 # Puntuación EPDS e invariante de crisis en ítem 10
│           ├── application/
│           │   ├── ports/
│           │   │   └── postpartum_repository_port.py             # IPostpartumRepository
│           │   ├── dtos/
│           │   │   └── postpartum_dtos.py                        # DTOs de casos de uso puerperales
│           │   └── use_cases/
│           │       └── postpartum_use_cases.py                   # 9 Casos de uso de recuperación, tomas, leche y EPDS
│           └── infrastructure/
│               ├── orm/
│               │   └── postpartum_orm.py                         # Modelos SQLAlchemy 2.0 Async
│               ├── adapters/
│               │   └── postgres_postpartum_repository.py         # Repositorio PostgreSQL
│               └── entrypoints/
│                   ├── postpartum_schemas.py                     # Esquemas Pydantic v2
│                   └── postpartum_router.py                      # Router REST FastAPI
└── tests/
    ├── unit/maternal_care/
    │   ├── test_epds_screening_service.py                        # Tests unitarios EPDS (inversión e ítem 10)
    │   └── test_postpartum_recovery_and_milk_stash.py            # Tests de endometritis, loquios y caducidad CDC
    └── integration/maternal_care/
        └── test_postpartum_api.py                                # Tests de integración de endpoints REST
```

### Mobile (Flutter + Drift SQLite Offline-First + Riverpod)

```
mobile/
├── lib/
│   ├── core/database/
│   │   ├── app_database.dart                                     # Drift schema v7 con 4 tablas puerperales
│   │   └── app_database.g.dart                                   # Código generado por drift_dev
│   └── features/
│       ├── dashboard/presentation/pages/
│       │   └── dynamic_home_dashboard_page.dart                  # Acceso dinámico a módulos de etapa posparto
│       └── postpartum/
│           ├── domain/entities/
│           │   └── postpartum_entities.dart                      # Entidades, evaluadores offline y caducidad leche
│           ├── data/
│           │   └── postpartum_repository_impl.dart               # IPostpartumRepository con Drift + SyncCoordinator
│           └── presentation/
│               ├── providers/
│               │   └── postpartum_providers.dart                 # Riverpod providers puerperales
│               └── pages/
│                   ├── postpartum_recovery_page.dart             # Registro de loquios, fiebre y heridas
│                   ├── lactation_and_milk_bank_page.dart         # Cronómetro doble pecho >= 56 dp y banco FIFO
│                   └── epds_mental_health_page.dart              # Cuestionario EPDS 10 ítems y banner de crisis
└── test/
    └── features/postpartum/
        └── postpartum_and_epds_test.dart                         # 7 tests unitarios y de widgets en Flutter
```

---

## 3. Decisiones Técnicas y Reglas Clínicas Aplicadas

1. **Protocolo Inviolable de Seguridad en Salud Mental Perinatal:**
   - La depresión posparto afecta entre el 10% y el 15% de las madres; los pensamientos de autolesión requieren atención inmediata. Se diseñó el sistema para que una respuesta $> 0$ al ítem 10 de la escala EPDS clasifique obligatoriamente a la usuaria en `IMMEDIATE_CRISIS_SUPPORT`, renderizando en la UI un banner de ayuda urgente no punitivo y un botón de llamada directa a líneas de intervención en crisis disponibles 24/7.
2. **Ergonomía de Lactancia Nocturna con Una Sola Mano:**
   - Las tomas de lactancia de madrugada a menudo se realizan mientras se sostiene al bebé en brazos. Por ello, las tarjetas de control de tiempo poseen un blanco táctil superior a $56\,\text{dp}$ y una arquitectura de un solo toque para pausar o alternar de pecho, informando en todo momento cuál debe ser el próximo lado para evitar asimetrías de vaciado y estasis láctea.
3. **Gestión FIFO y Caducidad de la Leche Materna:**
   - Para evitar desperdicio y garantizar la inocuidad alimentaria del lactante según lineamientos CDC y OMS, el banco de leche calcula automáticamente la fecha de caducidad en el momento de la extracción y ordena los lotes de forma ascendente por expiración, alertando visualmente con insignias verdes ($> 24\,\text{h}$), ámbar ($< 24\,\text{h}$) y rojas (vencida).
4. **Vigilancia de Endometritis Puerperal:**
   - La combinación de loquios fétidos y fiebre materna ($\ge 38.0^\circ\text{C}$) es el sello diagnóstico de infección puerperal bacteriana. Se implementó un evaluador clínico en Python y Dart que genera de forma determinista una alerta roja hospitalaria inmediata.

---

## 4. Pruebas Ejecutadas y Validación CI/CD

### Backend (`pytest`, `ruff`, `mypy`)
- **Tests unitarios e integración:** 148 pruebas automáticas pasando en verde (`148 passed in 7.94s`).
- **Verificación de contrato OpenAPI:** 0% de deriva de tipos (`test_runtime_openapi_matches_committed_contract PASSED`).
- **Linter y formateador:** `ruff check app` y `ruff format --check app` al 100% sin advertencias.
- **Análisis estático de tipos:** `mypy --strict app` con 117 archivos fuente validados sin errores.

### Mobile (`flutter test`, `flutter analyze`)
- **Tests de widgets y unitarios:** 45 pruebas automáticas pasando al 100% (`All tests passed!`).
- **Análisis estático de Dart:** `flutter analyze --fatal-infos` finalizado con 0 problemas (`No issues found!`).

---

## 5. Secuencia de Commits Realizados

1. `08391c3 feat(maternal-care): implement postpartum recovery alerts, milk stash expiry, and EPDS screening with TDD`
2. `5a27ee3 feat(maternal-care): add postpartum recovery, lactation, milk stash, and EPDS REST endpoints`
3. `1e0746c feat(mobile-ui): add fourth-trimester recovery tracker, one-hand lactation timer, and EPDS screening`
4. `70de04e docs(plan): mark phase 07 tasks completed in phase spec and roadmap`
5. *(Commit de documentación de cierre e índice en `documentacion/`)*

---

## 6. Estado para la Siguiente Fase

Con la **Fase 07** concluida exitosamente, el proyecto queda con el soporte completo de las **Etapas 1, 2, 3, 4 y 5 de la vida**. Queda listo el camino para la **Fase 08**:
- **Fase 08:** Etapas 6 y 7 de la vida (`mature_health`): Transición Menopáusica (**STRAW+10**), control de episodios vasomotores (sofocos), seguimiento de Terapia de Reemplazo Hormonal (TRH), prevención ósea/caídas, confort uroginecológico y activación del tema **Alta Legibilidad (WCAG AAA)** para usuarias sénior.
