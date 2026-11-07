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
`repo`, `specs`, `rules`, `plan`, `documentacion`, `core`, `identity`, `clinical-tracking`, `maternal-care`, `mature-health`, `treatments`, `medical-records`, `education`, `rag-assistant`, `partner-sharing`, `mobile-core`, `mobile-sync`, `mobile-ui`, `ci`.

### Orden Lógico de Commits Dentro de una Funcionalidad

Al implementar una feature en cualquier fase, divide los commits siguiendo este orden natural:
1. `test(<modulo>): add failing unit tests for <regla clinica / value object>` + `feat(<modulo>): implement <entidad / motor de dominio>` (o el par TDD ya en verde tras verificar el fallo inicial).
2. `db(<modulo>): add alembic migration and orm mapping for <tabla>`
3. `feat(<modulo>): expose <endpoint> and update openapi contract`
4. `test(<modulo>): add integration tests for <endpoint / repository>`
5. `feat(mobile-<feature>): add drift tables, sync outbox adapter, and riverpod providers`
6. `feat(mobile-<feature>): build <pantalla / widget> with widget tests`
7. `docs(plan): mark completed tasks in phase-XX plan`
8. `docs(documentacion): add phase-XX completion report in documentacion/`

## 3. Regla de Árbol Verde

- Cada commit subido a `main` (o a un Pull Request de fase) debe dejar el árbol compilando y pasando las pruebas existentes.
- Antes de cerrar una sesión de Antigravity, actualiza las casillas `- [x]` de la fase activa en `docs/phases/phase-XX-*.md` y su estado en `docs/phases/README.md`.

## 4. Documentación Obligatoria de Cierre por Fase (`documentacion/`)

Al finalizar **cada fase** (sin excepción, antes de dar por terminada la sesión en Antigravity):
1. Crear en la carpeta raíz `documentacion/` un archivo detallado llamado `documentacion/fase-XX-<nombre>.md` documentando todo lo que se hizo en esa fase: resumen ejecutivo, módulos/archivos y migraciones creadas, decisiones técnicas y reglas clínicas implementadas, pruebas ejecutadas y resultados CI/CD, listado de commits realizados y qué queda listo para la siguiente fase.
2. Actualizar la tabla de índice en `documentacion/README.md` enlazando el nuevo reporte de la fase completada.
3. Confirmar estos archivos en un commit atómico dedicado (`docs(documentacion): add phase-XX completion report in documentacion/`) y hacer `git push` a `eduardoevz/Cora`.
