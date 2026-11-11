# Reporte de Cierre — Fase 09: Carpeta Clínica Digital, Cloudflare R2 y Doctor-Ready PDF

**Fecha de Ejecución:** 10 de Noviembre de 2026  
**Rama:** `main`  
**Repositorio Público:** `eduardoevz/Cora`  
**Estado:** ✅ Completada y Verificada

---

## 1. Resumen Ejecutivo de la Fase

La **Fase 09** construyó e integró el 7.° contexto acotado de la plataforma Cora: el módulo transversal **`medical_records`** en el backend FastAPI y su funcionalidad correspondiente **`records`** en la aplicación móvil Flutter.

### Logros Clave:
1. **Carpeta Clínica Digital con Cloudflare R2:** Almacenamiento seguro y aislado de documentos médicos, citologías, análisis de laboratorio y ecografías obstétricas/mamarias mediante el puerto `IFileStorage` y el adaptador `CloudflareR2StorageAdapter`, con generación de URLs prefirmadas de subida y descarga con expiración estricta $\le 900$ segundos (15 minutos) y validación de tipos MIME (`PDF`, `JPEG`, `PNG`, `WebP`) y tamaño máximo ($\le 15\,\text{MB}$).
2. **Defensa Estricta Anti-IDOR (Insecure Direct Object Reference):** Toda solicitud de descarga de estudios médicos verifica la doble pertenencia `(id == exam_id, user_id == auth_user.id)`. La consulta de un recurso ajeno devuelve inmediatamente `404 Not Found` en lugar de `403 Forbidden`, ocultando la existencia misma del archivo.
3. **Calendario Preventivo Clínico Proyectado:** Servicio determinista (`PreventiveScreeningCalendarService`) que calcula tamizajes preventivos según edad (16 a 80+ años), etapa biológica y antecedentes diagnósticos (SOP, embarazo, antecedentes familiares), marcando urgencias (`due_now`, `upcoming`, `up_to_date`) según exámenes previos registrados.
4. **Cartilla de Vacunación y Directorio Médico:** Registro de dosis administradas (VPH, Tdap, Influenza, SRP, Herpes Zóster) y gestión de especialistas médicos de confianza con marcación telefónica directa y favoritos.
5. **Reportes Clínicos Exportables *Doctor-Ready PDF*:** Generador documental con `WeasyPrint` y plantillas paginadas Jinja2 (`autoescape=True`) que condensa el historial del ciclo (últimos 6 meses), adherencia terapéutica, signos vitales y notas del especialista en 1 a 2 páginas A4 estandarizadas para consulta médica rápida (< 60 segundos), protegido contra SSRF mediante `safe_local_url_fetcher` y con fallback determinista.
6. **Persistencia y SDD:** Migración Alembic `0009` aplicada en Neon PostgreSQL en vivo, contrato OpenAPI sincronizado con 0% de deriva y base Drift local actualizada a la versión 9 con mutaciones idempotentes `SyncOutboxService`.

---

## 2. Arquitectura, Módulos y Archivos Implementados

```
backend/
├── alembic/versions/
│   └── 0009_create_medical_records_tables.py
├── app/
│   ├── main.py (registro de medical_records_router)
│   └── modules/medical_records/
│       ├── domain/
│       │   ├── exceptions/medical_records_exceptions.py
│       │   ├── models/medical_record_and_vaccine.py
│       │   ├── services/preventive_screening_calendar_service.py
│       │   └── value_objects/record_metadata.py
│       ├── application/
│       │   ├── dtos/doctor_report_dtos.py
│       │   ├── ports/clinical_report_renderer_port.py
│       │   ├── ports/file_storage_port.py
│       │   ├── ports/medical_records_repository_port.py
│       │   ├── use_cases/generate_doctor_ready_pdf_use_case.py
│       │   └── use_cases/medical_records_use_cases.py
│       └── infrastructure/
│           ├── adapters/
│           │   ├── cloudflare_r2_storage_adapter.py
│           │   ├── postgres_medical_records_repository.py
│           │   └── weasyprint_report_renderer.py
│           ├── entrypoints/
│           │   ├── medical_records_router.py
│           │   └── medical_records_schemas.py
│           ├── orm/medical_records_orm.py
│           └── templates/
│               ├── doctor_ready_report.css
│               └── doctor_ready_report.html.j2
└── tests/
    ├── unit/medical_records/
    │   ├── test_doctor_ready_pdf_and_r2_security.py
    │   └── test_preventive_calendar_and_validation.py
    └── integration/medical_records/
        └── test_medical_records_api.py

mobile/
├── lib/
│   ├── core/database/
│   │   ├── app_database.dart (schemaVersion 9 + MedicalExamEntries, VaccinationEntries, SpecialistEntries)
│   │   └── app_database.g.dart
│   └── features/
│       ├── dashboard/presentation/pages/dynamic_home_dashboard_page.dart (atajos a carpeta y PDF)
│       └── records/
│           ├── data/medical_records_repository_impl.dart
│           ├── domain/models/
│           │   ├── medical_exam_record.dart
│           │   ├── preventive_screening_item.dart
│           │   ├── specialist_entry.dart
│           │   └── vaccination_record.dart
│           └── presentation/
│               ├── pages/
│               │   ├── doctor_report_export_page.dart
│               │   ├── medical_folder_hub_page.dart
│               │   └── vaccinations_and_specialists_page.dart
│               └── providers/medical_records_providers.dart
└── test/features/records/
    └── medical_folder_and_pdf_export_test.dart
```

---

## 3. Decisiones Técnicas y Reglas Clínicas Aplicadas

### 3.1. Aislamiento Criptográfico y Defensa Anti-IDOR en R2
- **Estructura de llaves S3:** `users/{user_id}/records/{record_id}/{safe_filename}`.
- Ningún archivo se expone a través de URLs públicas directas; se generan firmas temporales SigV4 con expiración estricta de 900 segundos.
- Si un usuario malintencionado intenta consultar `GET /exams/{exam_id}/download-url` con un identificador ajeno, la consulta a base de datos filtra por `user_id = auth_user.id`, levantando `MedicalRecordNotFoundError` que se traduce a `404 Not Found`, previniendo enumeración de registros.

### 3.2. Calendario Preventivo Adaptativo Multietapa
- **Adolescencia (< 26 años):** Vacunación completa contra VPH.
- **Adultas jóvenes (21–29 años):** Citología cervical (Papanicolau) cada 3 años; autoexploración mamaria mensual.
- **Etapa fértil (30–39 años):** Co-test VPH + Citología cada 5 años; tamizaje preconcepcional o metabólico según antecedentes.
- **Embarazo:** Ultrasonidos de 1.°, 2.° y 3.er trimestre, curva de tolerancia a la glucosa oral (CTGO) semana 24–28, y refuerzo vacunal Tdap a partir de semana 27.
- **Perimenopausia (40–49 años):** Mamografía bilateral anual/bianual, perfil cardiometabólico y citología.
- **Adulta mayor (>= 65 años):** Densitometría ósea axial (DEXA) para prevención de osteoporosis/fracturas, vacuna contra Herpes Zóster y monitoreo metabólico anual.

### 3.3. Seguridad Anti-SSRF y Sanitización en WeasyPrint
- La renderización de notas médicas en `doctor_ready_report.html.j2` opera bajo Jinja2 con `autoescape=True`.
- El `url_fetcher` de WeasyPrint (`safe_local_url_fetcher`) rechaza cualquier esquema `http://` o `https://`, permitiendo únicamente esquemas en memoria o rutas de assets locales aprobados, erradicando vectores de Server-Side Request Forgery.
- En sistemas host donde las bibliotecas nativas C (Pango/Cairo) no estén disponibles, el renderizador activa un generador fallback determinista que emite un flujo binario PDF válido (`%PDF-1.4` ... `%%EOF`).

---

## 4. Pruebas Ejecutadas y Validación CI/CD

### 4.1. Suite Backend (Pytest)
- **Tests Unitarios de Dominio y Seguridad:**
  - `test_preventive_calendar_and_validation.py`: 12 pruebas aprobadas (validación de MIME, extensiones, límites de 15 MB, path traversal y recomendaciones según edad).
  - `test_doctor_ready_pdf_and_r2_security.py`: 6 pruebas aprobadas (expiración de URLs en R2, protección SSRF, escape XSS en Jinja2 y generación de PDF válido).
- **Tests de Integración REST:**
  - `test_medical_records_api.py`: 5 pruebas aprobadas (ciclo de vida de examen, carga/descarga con R2, anti-IDOR estricto 404, calendario preventivo, cartilla de vacunas, especialistas y endpoint de descarga PDF).
- **Contrato OpenAPI y Suite Global:**
  - 0% de deriva en `contracts/openapi.json` verificado en `test_openapi_drift.py`.
  - **Total suite backend:** **199 pruebas en verde en 20.40s**.
  - **Linter y tipado estricto:** `ruff check` (0 errores) y `mypy --strict app/modules/medical_records` (18 archivos fuente sin observaciones).

### 4.2. Suite Móvil (Flutter)
- **Tests Unitarios y de Widgets:**
  - `medical_folder_and_pdf_export_test.dart`: 5 pruebas aprobadas en 5s.
- **Suite Global Móvil:**
  - **62 pruebas aprobadas en 17s**.
  - **Análisis estático:** `flutter analyze --fatal-infos` finalizado con **0 problemas**.

---

## 5. Secuencia de Commits Realizados

1. `91e480a` — `feat(medical-records): implement preventive screening calendar, vaccine records, and attachment validation`
2. `d088d8b` — `feat(medical-records): add Cloudflare R2 adapter and SSRF-safe WeasyPrint Doctor-Ready PDF generator`
3. `504115f` — `feat(medical-records): expose digital medical folder, vaccinations, and Doctor-Ready PDF REST endpoints`
4. `c85cc25` — `feat(mobile-ui): add digital medical folder, vaccination card, specialist directory, and PDF exporter`
5. `a650534` — `docs(plan): mark phase 09 tasks completed in phase spec and roadmap`

---

## 6. Estado para la Siguiente Fase

Con el cierre exitoso de la **Fase 09**:
- La carpeta clínica y los reportes PDF quedan completamente operativos y listos para integrarse con la biblioteca educativa y el asistente RAG en la **Fase 10** (`education_content` y `rag_assistant`).
- La purga de prefijos de usuario en Cloudflare R2 (`delete_user_prefix`) queda disponible para su reutilización en el protocolo de borrado irreversible GDPR de la **Fase 11**.
