# AGENTS.md — Reglas Maestras del Proyecto Cora

Bienvenido al repositorio de **Cora**, plataforma móvil *Offline-First* para el cuidado integral, longitudinal y preventivo de la salud femenina a lo largo de sus 7 etapas biológicas.

Toda sesión de desarrollo en Antigravity debe respetar estrictamente este archivo y las reglas especializadas en `.agents/rules/`.

---

## 1. Fuentes de Verdad del Proyecto

1. **Especificación Funcional:** `docs/SPECS.MD` (las 7 etapas de vida, onboarding de 3 capas, módulos transversales, RAG clínico, *Doctor-Ready PDF*, *Partner View* y Modo Discreto).
2. **Especificación Arquitectónica:** `docs/desarrollo.md` (Monolito Modular Hexagonal en FastAPI + Clean Architecture Feature-First en Flutter con Riverpod y Drift *Offline-First*).
3. **Hoja de Ruta por Sesiones:** `docs/phases/README.md` y `docs/phases/phase-01-*.md` ... `phase-12-*.md`.
4. **Reglas Operativas Modulares:** `.agents/rules/01-*.md` a `07-*.md`.

---

## 2. Protocolo de Trabajo por Fase (1 Sesión = 1 Fase)

Cuando el usuario solicite avanzar con una fase en Antigravity:

1. **Leer antes de actuar:** Abrir `docs/phases/README.md` y el documento completo `docs/phases/phase-XX-<nombre>.md` correspondiente, además de verificar el estado actual con `git status` y `git log -n 5 --oneline`.
2. **Activar las skills pertinentes:**
   - Proceso y ejecución: `executing-plans` o `subagent-driven-development`, `test-driven-development`, `verification-before-completion`.
   - Dominio técnico según la tarea: `gemini-api-dev` (para `rag_assistant` / `education_content`), `firebase-auth-basics` (para autenticación JWT).
3. **Ejecutar tarea por tarea con TDD y Commits Atómicos:**
   - Completar cada tarea del plan siguiendo el ciclo **Red → Green → Refactor**.
   - Ejecutar linters y tests reales antes de cada commit.
   - Realizar **commits granulares, ordenados y descriptivos** por cada unidad funcional completada (nunca acumular toda una fase en un solo mega-commit).
   - Marcar los checkboxes (`- [x]`) completados en el archivo `docs/phases/phase-XX-*.md` y actualizar el estado en `docs/phases/README.md` al cerrar la fase.
4. **Sincronizar con GitHub (`eduardoevz/Cora`):** Empujar (`git push`) los commits verificados y comprobar que los workflows de GitHub Actions permanezcan en verde.

---

## 3. Invariantes Innegociables

- **Repositorio Público Seguro:** `eduardoevz/Cora` es público. Prohibido versionar `.env`, llaves privadas, `firebase_service_account.json`, tokens o datos clínicos reales.
- **Pureza Hexagonal:** `backend/app/modules/<mod>/domain/` jamás importa FastAPI, SQLAlchemy, HTTP clients ni SDKs de terceros.
- **Offline-First Real:** En `mobile/`, toda acción de escritura persiste primero en **Drift (SQLite)** y encola una mutación idempotente (`client_mutation_id`) antes de intentar sincronizar con FastAPI.
- **Seguridad Clínica e IA:**
  - Toda regla biomédica (FIGO, ACOG, STRAW+10, EPDS, fertilidad) se escribe con tests unitarios parametrizados **antes** de su implementación.
  - Toda consulta al asistente RAG pasa primero por el `DeterministicSafetyInterceptor`; las llamadas a `google-genai` usan `gemini-3.8-flash` con **`store=False`** y `gemini-embedding-2`.
