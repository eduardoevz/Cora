# Hoja de Ruta Maestra por Fases — Plataforma Cora

Este directorio contiene el plan de implementación completo de **Cora**, estructurado en **16 fases autocontenidas** (Fases `01–12` de **Cora v1.0** y Fases `13–16` de la evolución **Cora v2.0** con Google Stitch, Calendario Menstrual Interactivo y rediseño UX/UI del Home + Drawer) diseñadas para ejecutarse **una fase por sesión** dentro de Antigravity siguiendo TDD biomédico, Arquitectura Hexagonal, Clean Architecture *Offline-First*, SDD (OpenAPI → Dart) y CI/CD en GitHub Actions.

---

## Cómo Ejecutar Cada Fase en una Nueva Sesión de Antigravity

Al abrir una nueva conversación en Antigravity para avanzar con la siguiente etapa del proyecto, utiliza esta instrucción:

> `/plan Ejecutemos la Fase X siguiendo estrictamente docs/phases/phase-0X-<nombre>.md y las reglas en .agents/rules/. Verifica cada tarea con tests reales, realiza todos los commits atómicos indicados y haz push al repositorio público eduardoevz/Cora.`

Al finalizar cada sesión:
1. Todas las tareas (`- [x]`) del archivo de la fase deben quedar marcadas.
2. Se debe crear el reporte completo de lo implementado en [`documentacion/fase-XX-<nombre>.md`](../../documentacion/README.md) y actualizar su índice.
3. Se debe hacer push a `origin/main` y verificar en vivo (`gh run list` / `gh run watch`) que **todos los pipelines de CI en GitHub Actions pasen en verde (`success`)**.
4. **Regla de Cierre Innegociable:** Si algún CI falla, el agente está obligado a resolverlo en la misma sesión antes de dar por cerrada la fase (prohibido cerrar con CI en rojo).
5. El estado en la tabla inferior únicamente se actualiza a `✅ Completada` tras la certificación verde del CI en GitHub.

---

## Tablero Maestro de Progreso

| Fase | Archivo del Plan | Alcance Principal y Módulos | Dependencias | Estado |
| :--- | :--- | :--- | :--- | :--- |
| **Fase 0** | Gobernanza Inicial | Reglas `.agents/rules/`, `AGENTS.md`, `docs/desarrollo.md`, planes `01–12` y creación del repo público `eduardoevz/Cora`. | Ninguna | ✅ Completada |
| **Fase 1** | [phase-01-foundation-and-cicd.md](./phase-01-foundation-and-cicd.md) | Monorepo `backend/` + `mobile/`, Docker Compose (`pgvector`), Drift + `SyncCoordinator`, script SDD OpenAPI y **GitHub Actions CI/CD**. | Fase 0 | ✅ Completada |
| **Fase 2** | [phase-02-identity-onboarding-lifestage.md](./phase-02-identity-onboarding-lifestage.md) | Módulo `identity`: Firebase JWT, Onboarding de 3 Capas, `LifeStageStateMachine`, *Life-Stage Switcher*, Modularidad a la Carta y *Home Dashboard* dinámico. | Fase 1 | ✅ Completada |
| **Fase 3** | [phase-03-wellness-and-treatments.md](./phase-03-wellness-and-treatments.md) | Núcleo transversal: Bienestar/Hábitos diarios (`clinical_tracking` base) y Gestor de Tratamientos/Fármacos (`treatments`) con sincronización *Offline-First*. | Fase 2 | ✅ Completada |
| **Fase 4** | [phase-04-cycle-reproductive-adolescence.md](./phase-04-cycle-reproductive-adolescence.md) | **Etapa 2 (Juventud/Reproductiva)** y **Etapa 1 (Adolescencia)**: motor de 4 fases, SOP/Endometriosis, modo Adolescencia + PIN y alertas preventivas **FIGO**. | Fase 3 | ✅ Completada |
| **Fase 5** | [phase-05-fertility-and-conception.md](./phase-05-fertility-and-conception.md) | **Etapa 3 (Búsqueda de Concepción)**: temperatura basal (`BasalBodyTemperature`), moco cervical, LH, algoritmo sintotérmico y gráficas interactivas. | Fase 4 | ✅ Completada |
| **Fase 6** | [phase-06-pregnancy-maternal-care.md](./phase-06-pregnancy-maternal-care.md) | **Etapa 4 (Embarazo)** (`maternal_care`): desarrollo fetal semanal, PA/peso/glucosa con alertas **ACOG** (preeclampsia y DG), contracciones, patadas y plan de parto. | Fase 2, 3 | ✅ Completada |
| **Fase 7** | [phase-07-postpartum-lactation-mental-health.md](./phase-07-postpartum-lactation-mental-health.md) | **Etapa 5 (Posparto)** (`maternal_care`): loquios, cicatrices, suelo pélvico, registro de lactancia/banco de leche y despistaje **EPDS** con protocolo de crisis. | Fase 6 | ✅ Completada |
| **Fase 8** | [phase-08-menopause-and-senior-vitality.md](./phase-08-menopause-and-senior-vitality.md) | **Etapas 6 y 7** (`mature_health`): transición **STRAW+10**, sofocos, TRH, salud ósea/caídas, uroginecología, tema **Alta Legibilidad (WCAG AAA)** y contacto familiar. | Fase 2, 3 | ✅ Completada |
| **Fase 9** | [phase-09-medical-records-r2-pdf.md](./phase-09-medical-records-r2-pdf.md) | Módulo `medical_records`: Carpeta Clínica Digital, vacunas, calendario preventivo por edad, **Cloudflare R2** (`IFileStorage`) y **Doctor-Ready PDF** (`WeasyPrint`). | Fase 3, 4 | ✅ Completada |
| **Fase 10** | [phase-10-education-and-clinical-rag.md](./phase-10-education-and-clinical-rag.md) | Módulos `education_content` + `rag_assistant`: biblioteca clínica curada, ingesta HNSW en `pgvector` (`gemini-embedding-2`), `DeterministicSafetyInterceptor` y chat (`gemini-3.8-flash`, `store=False`). | Fase 4, 6, 8, 9 | ✅ Completada |
| **Fase 11** | [phase-11-partner-view-privacy-gdpr.md](./phase-11-partner-view-privacy-gdpr.md) | Módulo `partner_sharing` (*Partner View* selectivo/revocable), bloqueo biométrico, icono camuflable, notificaciones neutras, exportación total y purga irreversible GDPR. | Fase 6, 9, 10 | ✅ Completada |
| **Fase 12** | [phase-12-qa-e2e-security-release.md](./phase-12-qa-e2e-security-release.md) | Suite E2E completa, pruebas de carga, auditoría OWASP/prompt-injection clínico, accesibilidad integral y activación de pipeline CD de lanzamiento. | Fases 1–11 | ✅ Completada |
| **Fase 13** | [phase-13-design-system-and-stitch.md](./phase-13-design-system-and-stitch.md) | **Cora v2.0:** Sistema de Diseño semántico (`docs/DESIGN.md`) + sesión visual en **Google Stitch**, `CoraColorTokens`, `CoraTheme` v2 y primitivas accesibles WCAG AA/AAA. | Fase 12 | ✅ Completada |
| **Fase 14** | [phase-14-onboarding-menstrual-baseline-and-engine.md](./phase-14-onboarding-menstrual-baseline-and-engine.md) | Onboarding interactivo de últimos 2 periodos (inicio/fin), regularidad y duración del ciclo + migración Alembic `0014` y Drift + motor de proyección mensual (`GET /api/v1/cycles/calendar` y `CycleCalendarEngine`). | Fase 13 | ⏳ Pendiente |
| **Fase 15** | [phase-15-interactive-menstrual-calendar.md](./phase-15-interactive-menstrual-calendar.md) | **Calendario Menstrual Interactivo** mensual con marcadores diarios, predicciones de periodo/ovulación/ventana fértil, panel de detalle diario, registro en cualquier fecha y adaptación a las 7 etapas. | Fase 14 | ⏳ Pendiente |
| **Fase 16** | [phase-16-home-ux-redesign-drawer-and-qa.md](./phase-16-home-ux-redesign-drawer-and-qa.md) | **Rediseño UX/UI del Home** limpio (Hero de ciclo/predicciones, tira semanal, educación de fase actual), **Menú Desplegable Lateral (`CoraNavigationDrawer`)**, QA Android Studio y Release v2.0. | Fase 15 | ⏳ Pendiente |

---

## Grafo de Dependencias entre Fases

```mermaid
flowchart TD
    P0["Fase 0: Reglas y Planes"] --> P1["Fase 1: Cimientos y CI/CD"]
    P1 --> P2["Fase 2: Identity, Onboarding y LifeStageStateMachine"]
    P2 --> P3["Fase 3: Bienestar Transversal y Tratamientos"]
    P3 --> P4["Fase 4: Etapas 1 y 2 (Ciclo, Adolescencia, FIGO)"]
    P4 --> P5["Fase 5: Etapa 3 (Fertilidad y Concepcion)"]
    P3 --> P6["Fase 6: Etapa 4 (Embarazo y Alertas ACOG)"]
    P6 --> P7["Fase 7: Etapa 5 (Posparto, Lactancia y EPDS)"]
    P3 --> P8["Fase 8: Etapas 6 y 7 (Menopausia y Plenitud)"]
    P4 --> P9["Fase 9: Carpeta Clinica, R2 y Doctor-Ready PDF"]
    P5 --> P9
    P7 --> P10["Fase 10: Biblioteca Curada y Asistente RAG"]
    P8 --> P10
    P9 --> P10
    P10 --> P11["Fase 11: Partner View, Modo Discreto y Purga GDPR"]
    P11 --> P12["Fase 12: QA E2E, Auditoria Seguridad y Release CD"]
    P12 --> P13["Fase 13: Sistema de Diseno v2 y Google Stitch"]
    P13 --> P14["Fase 14: Onboarding 2 Periodos y Motor Calendario"]
    P14 --> P15["Fase 15: Calendario Menstrual Interactivo (7 Etapas)"]
    P15 --> P16["Fase 16: Home UX Limpio, Drawer Lateral y Release v2.0"]
```
