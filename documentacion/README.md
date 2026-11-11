# Bitácora Oficial de Documentación por Fases (`documentacion/`)

Esta carpeta almacena la **documentación técnica e histórica de lo implementado en cada fase** del proyecto **Cora**.

De acuerdo con la regla obligatoria definida en [`.agents/rules/01-project-workflow-and-git.md`](../.agents/rules/01-project-workflow-and-git.md) y [`AGENTS.md`](../AGENTS.md), **al finalizar cada fase (antes de dar por cerrada la sesión en Antigravity)** se debe certificar que todos los workflows de CI en GitHub Actions pasaron en verde (`success`), crear aquí el archivo `fase-XX-<nombre>.md` correspondiente y actualizar el índice inferior. Si algún flujo de CI falla, se debe solucionar antes de registrar la fase como completada.

---

## Estructura Estándar de Cada Documento (`fase-XX-<nombre>.md`)

Cada reporte de cierre de fase debe incluir estas 6 secciones:

1. **Resumen Ejecutivo de la Fase:** Qué objetivos de negocio y clínicos se cumplieron.
2. **Arquitectura, Módulos y Archivos Implementados:** Capas tocadas (`domain`, `application`, `infrastructure`, `mobile`), migraciones de base de datos y endpoints/pantallas creadas.
3. **Decisiones Técnicas y Reglas Clínicas Aplicadas:** Algoritmos validados (FIGO, ACOG, STRAW+10, EPDS, *Offline-First*, seguridad) y por qué se diseñaron así.
4. **Pruebas Ejecutadas y Validación CI/CD:** Resultados verificados de tests unitarios, integración, contrato OpenAPI, widgets Flutter y workflows de GitHub Actions.
5. **Secuencia de Commits Realizados:** Listado trazable de los commits atómicos generados durante la fase.
6. **Estado para la Siguiente Fase:** Qué interfaces o componentes quedan listos para ser consumidos por las fases posteriores.

---

## Índice de Fases Documentadas

| Fase | Documento de Cierre | Fecha | Resumen |
| :--- | :--- | :--- | :--- |
| **Fase 00** | [fase-00-gobernanza-reglas-y-planificacion.md](./fase-00-gobernanza-reglas-y-planificacion.md) | 2026-11-07 | Definición de arquitectura, creación de reglas `.agents/rules/`, planes detallados `01–12` e inicialización del repositorio público `eduardoevz/Cora`. |
| **Fase 01** | [fase-01-cimientos-y-cicd.md](./fase-01-cimientos-y-cicd.md) | 2026-11-07 | Monorepo `backend/` + `mobile/`, Docker Compose `pgvector`, Drift SQLite + `SyncCoordinator` *Offline-First*, SDD OpenAPI y GitHub Actions CI/CD. |
| **Fase 02** | [fase-02-identidad-y-onboarding.md](./fase-02-identidad-y-onboarding.md) | 2026-11-07 | Identidad Firebase JWT, Onboarding de 3 Capas, `LifeStageStateMachine`, Modularidad y Dashboard dinámico. |
| **Fase 03** | [fase-03-bienestar-y-tratamientos.md](./fase-03-bienestar-y-tratamientos.md) | 2026-11-07 | Bienestar/Hábitos diarios consolidado con merge-patch y Gestor de Tratamientos/Pastillero virtual Offline-First con alertas clínicas. |
| **Fase 04** | [fase-04-salud-ciclica-y-adolescencia.md](./fase-04-salud-ciclica-y-adolescencia.md) | 2026-11-09 | Etapas 1 y 2: Ciclo de 4 fases, Adolescencia + PIN 30s, SOP/Endometriosis y alertas preventivas FIGO. |
| **Fase 05** | [fase-05-fertilidad-y-concepcion.md](./fase-05-fertilidad-y-concepcion.md) | 2026-11-09 | Etapa 3: Fertilidad sintotérmica (BBT, regla 3 sobre 6, moco cervical, LH) y checklist preconcepcional. |
| **Fase 06** | [fase-06-embarazo-y-cuidado-materno.md](./fase-06-embarazo-y-cuidado-materno.md) | 2026-11-10 | Etapa 4: Embarazo semanal, alertas ACOG (preeclampsia/DG), contracciones 5-1-1 y patadas Cardiff. |
| **Fase 07** | [fase-07-posparto-lactancia-y-salud-mental.md](./fase-07-posparto-lactancia-y-salud-mental.md) | 2026-11-10 | Etapa 5: Recuperación puerperal, loquios, cronómetro ergonómico de lactancia, banco de leche FIFO y tamizaje EPDS con contención inmediata. |
| **Fase 08** | [fase-08-menopausia-y-plenitud-adulta-mayor.md](./fase-08-menopausia-y-plenitud-adulta-mayor.md) | 2026-11-10 | Etapas 6 y 7: Transición STRAW+10, sofocos, TRH, salud ósea/caídas, suelo pélvico, tema WCAG AAA y contacto familiar. |
| **Fase 09** | [fase-09-carpeta-clinica-r2-y-doctor-ready-pdf.md](./fase-09-carpeta-clinica-r2-y-doctor-ready-pdf.md) | 2026-11-10 | Carpeta Clínica Digital, vacunas, directorio médico, Cloudflare R2 con defensa anti-IDOR y reportes *Doctor-Ready PDF*. |
| **Fase 10** | [fase-10-biblioteca-clinica-y-asistente-rag.md](./fase-10-biblioteca-clinica-y-asistente-rag.md) | 2026-11-10 | Biblioteca clínica curada, búsqueda `pgvector` HNSW (`gemini-embedding-2`), triaje determinista (`< 5 ms`) y chat RAG (`gemini-3.8-flash`, `store=False`). |
| **Fase 11** | *Se generará al cerrar la Fase 11* | Pendiente | *Partner View* selectivo, SQLCipher, biometría, icono camuflable y purga GDPR. |
| **Fase 12** | *Se generará al cerrar la Fase 12* | Pendiente | Suite E2E completa, auditoría de seguridad BOLA/RAG, benchmarks y Release CD. |
