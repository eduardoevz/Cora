# Fase 09 — Carpeta Clínica Digital, Cloudflare R2 y Reportes *Doctor-Ready PDF* Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir el módulo hexagonal `medical_records` y su experiencia móvil en Flutter: almacenamiento seguro de estudios clínicos y ecografías en **Cloudflare R2** (`IFileStorage`), calendario preventivo parametrizado por edad/etapa, cartilla de vacunación, directorio de especialistas y generación de **Reportes Clínicos Exportables (*Doctor-Ready PDF* de 1–2 páginas)** con **WeasyPrint + Jinja2**.

**Architecture:** `medical_records` desacopla el almacenamiento binario mediante el puerto `IFileStorage` (`CloudflareR2StorageAdapter` con URLs prefirmadas `<= 15 min` y llaves aisladas `users/{user_id}/records/{record_id}`) y desacopla el motor documental mediante `IClinicalReportRenderer` (`WeasyPrintReportRenderer`), recopilando resúmenes de `identity`, `clinical_tracking`, `maternal_care`, `mature_health` y `treatments` a través de sus puertos públicos.

**Tech Stack:** Python 3.12+, FastAPI, SQLAlchemy 2.0 Async, `boto3` / S3-compatible R2, `Jinja2`, `WeasyPrint`, Flutter, Riverpod, Drift, visor/compartición segura de PDFs.

**Spec:** `docs/SPECS.MD` (Sección 3.1 Carpeta Clínica Digital; Sección 4 Reportes Clínicos Exportables), `docs/desarrollo.md` (Secciones 1 y 4.4), `.agents/rules/04-backend-python-fastapi.md`

## Global Constraints

- Prohibido servir documentos médicos desde URLs públicas estáticas; toda carga/descarga usa **Presigned URLs firmadas con expiración `<= 900` segundos** verificando propiedad (`record.user_id == auth_user.user_id`).
- Tipos de archivo permitidos exclusivamente: `application/pdf`, `image/jpeg`, `image/png`, `image/webp` con tamaño máximo `15 MB`.
- El reporte **Doctor-Ready PDF** se diseña estrictamente para **1 a 2 páginas A4** de lectura médica rápida (< 60 segundos en consulta): encabezado clínico, etapa activa, variabilidad de últimos 6 ciclos, tabla de correlación de síntomas frecuentes, adherencia farmacológica, curva resumida de signos vitales pertinentes y notas para el especialista.

## Review Focus

1. **Acceso cruzado (IDOR) a estudios médicos en R2:** Solicitar URL de descarga de un `record_id` perteneciente a otra usuaria debe devolver `404 Not Found` sin revelar siquiera que el estudio existe.
2. **Inyección HTML/XSS en plantillas Jinja2 -> WeasyPrint:** Las notas libres ingresadas por la usuaria deben renderizarse con `autoescape=True` estricto y bloqueo total de recursos de red externos (`url_fetcher` restringido únicamente a assets locales embebidos para impedir SSRF desde WeasyPrint).
3. **Calendario preventivo adaptado por edad y etapa:** Parametrizar recordatorios orientativos basados en guías preventivas (citología/PAP y test VPH, ecografía/mamografía por rango etario, Tdap en embarazo, densitometría ósea en menopausia/plenitud).
4. **Reporte PDF con datos escasos (usuaria recién registrada):** Si una usuaria genera el PDF en su primera semana, renderizar secciones limpias con indicador *"Sin registros suficientes en el periodo"* sin tablas rotas ni páginas en blanco extra.
5. **Cola de subida diferida para adjuntos médicos offline:** Permitir registrar el metadato del examen y su recordatorio sin conexión, subiendo el archivo adjunto cuando regrese la red Wi-Fi/datos.

---

### Task 1: Dominio de `medical_records` — Estudios, Vacunas, Directorio y Calendario Preventivo por Edad/Etapa (TDD)

**Files:**
- Create: `backend/app/modules/medical_records/domain/value_objects/record_metadata.py`
- Create: `backend/app/modules/medical_records/domain/models/medical_record_and_vaccine.py`
- Create: `backend/app/modules/medical_records/domain/services/preventive_screening_calendar_service.py`
- Test: `backend/tests/unit/medical_records/test_preventive_calendar_and_validation.py`

**Interfaces:**
- Consumes: `LifeStage` (`identity`), `DomainError`
- Produces:
  - `ExamType` (`PAP_SMEAR`, `HPV_TEST`, `PELVIC_ULTRASOUND`, `BREAST_ULTRASOUND`, `MAMMOGRAM`, `BONE_DENSITOMETRY_DEXA`, `BLOOD_PANEL`, `PRENATAL_ULTRASOUND`)
  - `AttachmentSpec` (validación MIME, extensión y límite `<= 15 MB`)
  - `MedicalExamRecord`, `VaccinationEntry` (`HPV`, `TDAP`, `RUBELLA`, `INFLUENZA`, `SHINGLES`), `SpecialistContact`
  - `PreventiveScreeningCalendarService.compute_due_screenings(...) -> list[PreventiveScreeningItem]`

- [ ] **Step 1: Escribir tests TDD parametrizados validando rechazo de MIME ejecutable/HTML o tamaño `> 15 MB`, clave de objeto aislada `users/{user_id}/records/{record_id}` y calendario preventivo según edad (`16`, `27`, `32 embarazada`, `48`, `67` años)**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/unit/medical_records/test_preventive_calendar_and_validation.py -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar Value Objects, entidades y `PreventiveScreeningCalendarService`**
- [ ] **Step 4: Verificar pase en `< 50 ms` y `mypy --strict`**
  - Run: `mypy --strict backend/app && pytest backend/tests/unit/medical_records -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/app/modules/medical_records/domain backend/tests/unit/medical_records`
  - `git commit -m "feat(medical-records): implement preventive screening calendar, vaccine records, and attachment validation"`

---

### Task 2: Adaptadores `CloudflareR2StorageAdapter` (`IFileStorage`) y `WeasyPrintReportRenderer` (*Doctor-Ready PDF*)

**Files:**
- Create: `backend/app/modules/medical_records/application/ports/file_storage_port.py`
- Create: `backend/app/modules/medical_records/application/ports/clinical_report_renderer_port.py`
- Create: `backend/app/modules/medical_records/application/use_cases/generate_doctor_ready_pdf_use_case.py`
- Create: `backend/app/modules/medical_records/infrastructure/adapters/cloudflare_r2_storage_adapter.py`
- Create: `backend/app/modules/medical_records/infrastructure/adapters/weasyprint_report_renderer.py`
- Create: `backend/app/modules/medical_records/infrastructure/templates/doctor_ready_report.html.j2`
- Create: `backend/app/modules/medical_records/infrastructure/templates/doctor_ready_report.css`
- Test: `backend/tests/unit/medical_records/test_doctor_ready_pdf_and_r2_security.py`

**Interfaces:**
- Consumes: Puertos de lectura de `identity`, `clinical_tracking`, `maternal_care`, `mature_health`, `treatments`
- Produces:
  - `IFileStorage` (`create_presigned_upload_url`, `create_presigned_download_url`, `delete_user_prefix` — este último reutilizado en purga GDPR de Fase 11)
  - `IClinicalReportRenderer.render_pdf(summary: DoctorReportData) -> bytes`

- [ ] **Step 1: Escribir tests verificando: expiración `<= 900s` en URLs prefirmadas de R2, escape automático de etiquetas `<script>`/`<img src="http://...">` en Jinja2, bloqueo SSRF en `url_fetcher` de WeasyPrint, y generación de PDF válido (`%PDF-`) de `1–2` páginas tanto con historial rico como con perfil recién creado**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/unit/medical_records/test_doctor_ready_pdf_and_r2_security.py -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar `CloudflareR2StorageAdapter`, plantilla clínica HTML/CSS paginada (`@page { size: A4; }`), `WeasyPrintReportRenderer` con `safe_local_url_fetcher` y `GenerateDoctorReadyPdfUseCase`**
- [ ] **Step 4: Verificar tests y `mypy --strict`**
  - Run: `ruff check backend && mypy --strict backend/app && pytest backend/tests/unit/medical_records -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/app/modules/medical_records backend/tests/unit/medical_records/test_doctor_ready_pdf_and_r2_security.py`
  - `git commit -m "feat(medical-records): add Cloudflare R2 adapter and SSRF-safe WeasyPrint Doctor-Ready PDF generator"`

---

### Task 3: Persistencia PostgreSQL y Endpoints REST de Carpeta Clínica y Exportación PDF

**Files:**
- Create: `backend/alembic/versions/0009_create_medical_records_tables.py`
- Create: `backend/app/modules/medical_records/application/ports/medical_records_repository_port.py`
- Create: `backend/app/modules/medical_records/infrastructure/orm/medical_records_orm.py`
- Create: `backend/app/modules/medical_records/infrastructure/adapters/postgres_medical_records_repository.py`
- Create: `backend/app/modules/medical_records/infrastructure/entrypoints/medical_records_router.py`
- Modify: `backend/app/main.py`
- Modify: `contracts/openapi.json`
- Test: `backend/tests/integration/medical_records/test_medical_records_api.py`

**Interfaces:**
- Consumes: Servicios y adaptadores de Tasks 1 y 2
- Produces:
  - `POST /api/v1/medical-records/exams`, `POST /api/v1/medical-records/exams/{exam_id}/upload-url`, `GET /api/v1/medical-records/exams/{exam_id}/download-url`, `GET /api/v1/medical-records/preventive-calendar`, `POST /api/v1/medical-records/vaccinations`, `POST /api/v1/medical-records/specialists`, `POST /api/v1/medical-records/doctor-report/pdf`

- [ ] **Step 1: Escribir tests de integración HTTP verificando flujo completo de examen + URL prefirmada, test anti-IDOR (`404` cuando Usuario B pide descarga de examen de Usuario A) y descarga de `application/pdf` en `/doctor-report/pdf`**
- [ ] **Step 2: Ejecutar pytest y confirmar fallo**
  - Run: `pytest backend/tests/integration/medical_records/test_medical_records_api.py -v`
  - Expected: FAIL
- [ ] **Step 3: Implementar migración `0009`, ORM, repositorio, router y actualizar `contracts/openapi.json`**
- [ ] **Step 4: Verificar toda la suite backend**
  - Run: `python backend/scripts/export_openapi.py && pytest backend/tests -v`
  - Expected: PASS
- [ ] **Step 5: Commit**
  - `git add backend/alembic/versions/0009_create_medical_records_tables.py backend/app/modules/medical_records backend/app/main.py contracts/openapi.json backend/tests/integration/medical_records/test_medical_records_api.py`
  - `git commit -m "feat(medical-records): expose digital medical folder, vaccinations, and Doctor-Ready PDF REST endpoints"`

---

### Task 4: Carpeta Clínica Móvil en Flutter — Estudios, Vacunas, Directorio Médico y Vista Previa/Exportación de PDF

**Files:**
- Create: `mobile/lib/features/records/domain/entities/medical_record_entities.dart`
- Create: `mobile/lib/features/records/data/medical_records_repository_impl.dart`
- Create: `mobile/lib/features/records/presentation/pages/medical_folder_hub_page.dart`
- Create: `mobile/lib/features/records/presentation/pages/vaccinations_and_specialists_page.dart`
- Create: `mobile/lib/features/records/presentation/pages/doctor_report_export_page.dart`
- Modify: `mobile/lib/core/database/app_database.dart`
- Modify: `mobile/lib/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart`
- Test: `mobile/test/features/records/medical_folder_and_pdf_export_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `SyncCoordinator`, `CoraApiClient`, `DiscreetNotificationService`
- Produces: Módulo transversal móvil completo de Carpeta Clínica Digital

- [ ] **Step 1: Escribir tests en Flutter verificando creación offline de examen/vacuna/especialista, cola diferida de archivo adjunto y selector de rango de fechas (`3`, `6`, `12` meses) para generar el *Doctor-Ready PDF***
- [ ] **Step 2: Ejecutar `flutter test` y confirmar fallo**
  - Run: `cd mobile && flutter test test/features/records`
  - Expected: FAIL
- [ ] **Step 3: Implementar tablas Drift de carpeta médica, subida por URL prefirmada hacia R2 y pantallas de Carpeta Clínica y exportación PDF**
- [ ] **Step 4: Ejecutar `build_runner`, `flutter analyze` y `flutter test`**
  - Run: `cd mobile && dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-infos && flutter test`
  - Expected: PASS
- [ ] **Step 5: Commits finales y cierre de Fase 09**
  - `git add mobile`
  - `git commit -m "feat(mobile-ui): add digital medical folder, vaccination card, specialist directory, and PDF exporter"`
  - `git add docs/phases/phase-09-medical-records-r2-pdf.md docs/phases/README.md`
  - `git commit -m "docs(plan): mark phase 09 tasks completed"`
