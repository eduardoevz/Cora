# Documento de Especificación de Producto: Cora

**Cora** es una plataforma móvil para el cuidado integral y preventivo de la salud femenina, diseñada para acompañar a la mujer de manera continua, adaptativa y personalizada a lo largo de todas las etapas biológicas de su vida.

---

## 1. Onboarding Progresivo y Calibración Inicial

El flujo de bienvenida prioriza la empatía, la baja fricción y el consentimiento informado. Se recogen los datos básicos de perfil (nombre, apellido) y tres capas de contextualización:

### Capa 1: Calibración de Etapa (Requerida)

> *"¿En qué etapa de tu vida te encuentras actualmente?"*

* Adolescencia / Primeros ciclos
* Juventud y vida adulta regular
* Búsqueda de embarazo / Fertilidad
* Embarazo actual
* Posparto / Lactancia
* Perimenopausia / Menopausia
* Plenitud / Adulta mayor

**Objetivo:** Configura el motor de la app, el tono de comunicación y activa los módulos pertinentes.

> *"¿Cuál es tu año de nacimiento?" (o rango de edad)*

**Objetivo:** Parametrizar factores de riesgo, calendarios preventivos y metas metabólicas según la edad cronológica.

---

### Capa 2: Intención Principal (Requerida - Selección múltiple, máx. 3)

> *"¿Qué te gustaría priorizar en Cora hoy?"*

* Seguir y predecir mi ciclo menstrual y síntomas
* Planificación familiar (quedar o evitar embarazo)
* Acompañamiento en mi embarazo semana a semana
* Manejar cambios hormonales, sofocos o sueño
* Monitoreo de salud preventiva (estudios ginecológicos, mamografías, chequeos)
* Bienestar general (nutrición, energía, ejercicio adaptado)

**Objetivo:** Personalizar la vista del Home Dashboard desde la primera sesión.

---

### Capa 3: Contexto Clínico Base (Opcional / "Responder después")

* **"¿Utilizas algún método anticonceptivo o tratamiento hormonal?"**  
  *Opciones:* Ninguno, pastillas combinadas, DIU (hormonal o cobre), implante subdérmico, parches, inyectable, Terapia de Reemplazo Hormonal (TRH), etc.
* **"¿Tienes alguna condición diagnosticada que debamos considerar?"**  
  *Opciones:* Síndrome de Ovario Poliquístico (SOP), Endometriosis, Alteraciones tiroideas, Resistencia a la insulina / Diabetes, Ninguna / Omitir.

**Objetivo:** Ajustar los algoritmos predictivos evitando falsas alarmas ante ciclos naturalmente atípicos por patología de base.

---

## 2. Experiencia de Navegación y Flexibilidad

* **Conmutador de Etapa de Vida (*Life-Stage Switcher*):** Disponible en los ajustes de perfil. Permite transicionar manualmente o mediante detección guiada (ej. de búsqueda de embarazo a gestación confirmada) preservando todo el historial longitudinal sin sobreescribir datos pasados.
* **Dashboards Dinámicos:** La interfaz adapta sus tarjetas principales, accesos directos y widgets según la etapa activa y los objetivos seleccionados.
* **Modularidad a la Carta:** La usuaria tiene autonomía para activar, pausar u ocultar módulos secundarios desde el gestor de preferencias.

---

## 3. Matriz Modular del Sistema

### 3.1. Módulos Transversales (Núcleo Permanente)

* **Carpeta Clínica Digital:** Almacenamiento y calendarización de exámenes médicos (Papanicolaou, ecografías mamarias/pélvicas, mamografías, citologías, densitometría ósea), cartilla de vacunación (VPH, tétanos, etc.) y directorio de especialistas.
* **Asistente de Bienestar y Hábitos:** Registro cuantitativo y cualitativo de calidad de sueño, energía subjetiva, hidratación, actividad física y estados de ánimo.
* **Gestor de Tratamientos y Fármacos:** Recordatorios inteligentes para anticonceptivos, suplementación (ácido fólico, hierro, calcio, magnesio, vitamina D) y medicación crónica.
* **Espacio de Aprendizaje & Comunidad Segura:** Biblioteca de divulgación médica basada en evidencia, categorizada por etapa y revisada clínicamente.

---

### 3.2. Módulos Especializados por Etapa de Vida

| Etapa de Vida | Módulos Específicos | Enfoque y Funcionalidades Clave |
| :--- | :--- | :--- |
| **1. Adolescencia**<br>(~10 a 19 años) | • Mi Primer Periodo<br>• Guía de Cambios Corporales<br>• Modo Privacidad Segura | • Educación sin estigmas sobre menarquia y cambios biológicos.<br>• Algoritmo tolerante a irregularidades ovulatorias propias de la edad.<br>• Registro de acné, cólicos (dismenorrea) y variaciones anímicas.<br>• Acceso rápido protegido por PIN independiente. |
| **2. Juventud y Edad Reproductiva**<br>(~20 a 39 años) | • Monitor Ciclo & Fases Hormonales<br>• Planificación & Anticoncepción<br>• Condiciones Ginecológicas Crónicas | • Mapeo integral de 4 fases (menstrual, folicular, ovulatoria, lútea).<br>• Alertas de adherencia anticonceptiva y recordatorios de recambio (DIU/implante).<br>• Herramientas de seguimiento adaptadas a SOP y endometriosis. |
| **3. Búsqueda de Concepción**<br>(Optativa) | • Ventana Fértil & Ovulación Avanzada<br>• Seguimiento Biomédico<br>• Preparación Preconcepcional | • Registro de temperatura basal corporal, moco cervical y pruebas de LH.<br>• Checklists de hábitos preconcepcionales y nutrición folicular.<br>• Consolidación de datos clínicos para especialistas en fertilidad. |
| **4. Embarazo**<br>(Gestación) | • Semana a Semana Fetal<br>• Monitor Materno & Síntomas<br>• Plan de Parto y Citas | • Seguimiento biométrico del desarrollo fetal con hitos anatómicos.<br>• Registro de presión arterial, curva de peso y glucosa (descarte de preeclampsia y diabetes gestacional).<br>• Contador de contracciones, monitor de patadas y agenda prenatal. |
| **5. Posparto y Crianza Inicial**<br>(Puerperio) | • Recuperación Posparto (Cuarto Trimestre)<br>• Apoyo a la Lactancia<br>• Salud Mental Materna | • Monitoreo de loquios, evolución de cicatrices (cesárea/episiotomía) y suelo pélvico.<br>• Registro de tomas de leche, extracción, volumen y almacenamiento.<br>• Escala de despistaje preventivo de depresión posparto (EPDS). |
| **6. Perimenopausia y Menopausia**<br>(~40 a 55+ años) | • Registro de Transición Hormonal<br>• Gestor de Sofocos y Síntomas<br>• Salud Metabólica y Cardiovascular | • Seguimiento de irregularidades en la transición a la menopausia.<br>• Mapeo de sofocos diurnos/nocturnos, insomnio, sequedad y niebla mental.<br>• Control del impacto de Terapias de Reemplazo Hormonal (TRH) y marcadores lipídicos/cardiovasculares. |
| **7. Plenitud / Adulta Mayor**<br>(Etapa Sénior) | • Salud Ósea y Muscular<br>• Salud Uroginecológica<br>• Vitalidad & Prevención Integral | • Detección y prevención de osteopenia/osteoporosis y riesgo de caídas.<br>• Monitoreo de continencia urinaria y fortalecimiento del suelo pélvico.<br>• Interfaz de alta legibilidad (contrastes y tipografía escalable) y botón de contacto de soporte/familiar. |

---

## 4. Capacidades Diferenciales y Valor Agregado

* **Asistente Conversacional Inteligente con Memoria Contextual (RAG):**
  * Consultas en lenguaje natural cruzando el historial privado de la usuaria (*"¿En qué días de mi ciclo me suele dar migraña?"*).
  * Respuestas médicas con atribución y citas directas de literatura científica validada (ACOG, OMS, guías ginecológicas internacionales).

* **Reportes Clínicos Exportables (*Doctor-Ready PDF*):**
  * Generación de informes resumidos de 1 a 2 páginas con tablas de correlación de síntomas, variabilidad de ciclo, esquemas de medicación y registros de presión/temperatura listos para revisión médica en consulta.

* **Detección Preventiva de Patrones Atípicos:**
  * Alertas contextuales no alarmistas ante sangrados intermenstruales, polimenorrea, oligomenorrea prolongada o dolor pélvico incapacitante recurrente, sugiriendo valoración profesional oportuna.

* **Modo Acompañante / Pareja (*Partner View*):**
  * Enlace bidireccional seguro y selectivo donde la usuaria elige qué datos compartir (hitos de embarazo, ventanas fértiles o contexto emocional/físico para fomentar apoyo mutuo).

* **Privacidad Robusta y Modo Discreto:**
  * Cifrado de datos de grado médico en tránsito y en reposo.
  * Autenticación biométrica (Face ID / Huella) obligatoria para acceso a registros íntimos.
  * Icono de aplicación camuflable y enmascaramiento de textos en notificaciones push.
  * Opción de exportación completa y purga irreversible de la cuenta.