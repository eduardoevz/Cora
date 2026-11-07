# Bitácora Oficial de Documentación por Fases (`documentacion/`)

Esta carpeta almacena la **documentación técnica e histórica de lo implementado en cada fase** del proyecto **Cora**.

De acuerdo con la regla obligatoria definida en [`.agents/rules/01-project-workflow-and-git.md`](../.agents/rules/01-project-workflow-and-git.md) y [`AGENTS.md`](../AGENTS.md), **al finalizar cada fase (antes de dar por cerrada la sesión en Antigravity)** se debe crear aquí el archivo `fase-XX-<nombre>.md` correspondiente y actualizar el índice inferior.

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
| **Fase 01** | *Se generará al cerrar la Fase 01* | Pendiente | Monorepo `backend/` + `mobile/`, Docker `pgvector`, `SyncCoordinator` y GitHub Actions CI/CD. |
| **Fase 02** | *Se generará al cerrar la Fase 02* | Pendiente | Identidad Firebase JWT, Onboarding de 3 Capas, `LifeStageStateMachine` y Dashboard dinámico. |
| **Fase 03** | *Se generará al cerrar la Fase 03* | Pendiente | Bienestar/Hábitos diarios y Gestor de Tratamientos/Fármacos *Offline-First*. |
| **Fase 04** | *Se generará al cerrar la Fase 04* | Pendiente | Etapas 1 y 2: Ciclo de 4 fases, Adolescencia + PIN, SOP/Endometriosis y alertas FIGO. |
| **Fase 05** | *Se generará al cerrar la Fase 05* | Pendiente | Etapa 3: Fertilidad sintotérmica (TBC, moco cervical, LH) y preparación preconcepcional. |
| **Fase 06** | *Se generará al cerrar la Fase 06* | Pendiente | Etapa 4: Embarazo semanal, alertas ACOG (preeclampsia/DG), contracciones y patadas. |
| **Fase 07** | *Se generará al cerrar la Fase 07* | Pendiente | Etapa 5: Recuperación posparto, lactancia/banco de leche y tamizaje EPDS. |
| **Fase 08** | *Se generará al cerrar la Fase 08* | Pendiente | Etapas 6 y 7: Transición STRAW+10, sofocos, TRH, salud ósea/caídas y tema WCAG AAA. |
| **Fase 09** | *Se generará al cerrar la Fase 09* | Pendiente | Carpeta Clínica Digital, vacunas, Cloudflare R2 y reportes *Doctor-Ready PDF*. |
| **Fase 10** | *Se generará al cerrar la Fase 10* | Pendiente | Biblioteca clínica curada, búsqueda `pgvector` HNSW, triaje determinista y chat RAG. |
| **Fase 11** | *Se generará al cerrar la Fase 11* | Pendiente | *Partner View* selectivo, SQLCipher, biometría, icono camuflable y purga GDPR. |
| **Fase 12** | *Se generará al cerrar la Fase 12* | Pendiente | Suite E2E completa, auditoría de seguridad BOLA/RAG, benchmarks y Release CD. |
