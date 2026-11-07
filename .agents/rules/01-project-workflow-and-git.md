---
trigger: always_on
description: Flujo de trabajo por fases en Antigravity, disciplina de commits atomicos ordenados y seguridad en el repositorio publico Cora.
---

# Regla 01 — Flujo por Fases, Git y Commits Atómicos

## 1. Gestión del Repositorio Público (`eduardoevz/Cora`)

- El repositorio remoto en GitHub es **público**. Antes de cualquier `git commit`, ejecuta siempre `git status` y `git diff --staged` para confirmar que no se incluyan archivos `.env`, credenciales JSON de Firebase, secretos de Cloudflare R2, API keys de Gemini, bases SQLite locales ni reportes PDF generados en pruebas manuales.
- Nunca uses `git add .` o `git add -A` de forma indiscriminada; añade explícitamente las rutas de los archivos correspondientes a la unidad lógica que estás confirmando (`git add <ruta1> <ruta2>`).

## 2. Política de Commits Atómicos y Descriptivos

El historial de Git debe narrar con claridad qué se construyó en cada etapa. **No importa que existan muchos commits**; se prefiere una secuencia limpia de commits pequeños y auto-contenidos sobre commits masivos.

### Formato Obligatorio (Conventional Commits)

```text
<tipo>(<alcance>): <verbo imperativo + qué se hizo con precisión>
```

#### Tipos permitidos:
- `feat`: Nueva funcionalidad de dominio, caso de uso, endpoint o pantalla móvil.
- `test`: Adición o ampliación de pruebas unitarias, de integración, contrato o widgets.
- `fix`: Corrección de un defecto verificado con su test de regresión.
- `refactor`: Mejora estructural sin cambio de comportamiento observable (con tests en verde).
- `db`: Nueva migración reversible de Alembic o esquema local de Drift.
- `ci`: Creación o ajuste de pipelines en `.github/workflows/` o configuración Docker.
- `docs`: Actualización de especificaciones, planes en `docs/phases/`, `README.md` o reglas.
- `chore`: Configuración de herramientas, linters, dependencias o scripts de generación SDD.

#### Alcances recomendados (`<alcance>`):
`repo`, `specs`, `rules`, `plan`, `core`, `identity`, `clinical-tracking`, `maternal-care`, `mature-health`, `treatments`, `medical-records`, `education`, `rag-assistant`, `partner-sharing`, `mobile-core`, `mobile-sync`, `mobile-ui`, `ci`.

### Orden Lógico de Commits Dentro de una Funcionalidad

Al implementar una feature en cualquier fase, divide los commits siguiendo este orden natural:
1. `test(<modulo>): add failing unit tests for <regla clinica / value object>` + `feat(<modulo>): implement <entidad / motor de dominio>` (o el par TDD ya en verde tras verificar el fallo inicial).
2. `db(<modulo>): add alembic migration and orm mapping for <tabla>`
3. `feat(<modulo>): expose <endpoint> and update openapi contract`
4. `test(<modulo>): add integration tests for <endpoint / repository>`
5. `feat(mobile-<feature>): add drift tables, sync outbox adapter, and riverpod providers`
6. `feat(mobile-<feature>): build <pantalla / widget> with widget tests`
7. `docs(plan): mark completed tasks in phase-XX plan`

## 3. Regla de Árbol Verde

- Cada commit subido a `main` (o a un Pull Request de fase) debe dejar el árbol compilando y pasando las pruebas existentes.
- Antes de cerrar una sesión de Antigravity, actualiza las casillas `- [x]` de la fase activa en `docs/phases/phase-XX-*.md` y su estado en `docs/phases/README.md`.
