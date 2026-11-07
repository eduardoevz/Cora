---
trigger: model_decision
description: Activar al trabajar en rag_assistant, ingesta vectorial de education_content, embeddings en pgvector o integraciones con Google Gemini API.
---

# Regla 06 — Estándares de IA Clínica y RAG con Google Gemini API

## 1. SDK y Modelos Vigentes Obligatorios

- **SDK exclusivo en Python:** `google-genai >= 2.30.1` (`from google import genai`).
- **Prohibido usar SDKs o modelos deprecados:** Nunca instalar ni importar `google-generativeai`, ni usar `text-embedding-004`, `gemini-1.5-*`, `gemini-2.0-*` o `gemini-2.5-*`.
- **Modelos autorizados en Cora:**
  - **Generación conversacional y síntesis clínica RAG:** `gemini-3.8-flash` (o `gemini-4-argon` únicamente para evaluaciones offline complejas si se requiere explícitamente).
  - **Embeddings semánticos (texto y documentos PDF clínicos):** `gemini-embedding-2` (o `gemini-embedding-001` solo para texto corto si se configura explícitamente), truncado y auto-normalizado a `768` (o `1536`) dimensiones consistentes con la columna `vector(768)` en Neon `pgvector`.
- Antes de escribir o actualizar código del adaptador de Gemini, consultar la documentación vigente mediante las herramientas MCP `gemini_search_docs` / `gemini_get_doc` y la skill `gemini-api-dev`.

## 2. Privacidad Médica Estricta en la API de Interacciones (`store=False`)

En el SDK `google-genai`, `client.interactions.create(...)` almacena las interacciones por defecto en el servidor (`store=True`). Por tratarse de datos íntimos de salud femenina (PHI):

```python
interaction = client.interactions.create(
    model="gemini-3.8-flash",
    system_instruction=CLINICAL_RAG_SYSTEM_PROMPT,
    input=grounded_prompt,
    store=False,  # INNEGOCIABLE: cero retención externa de conversaciones clínicas
)
```

- **Regla inquebrantable:** Todas las llamadas desde `GeminiClinicalAssistantAdapter` deben fijar `store=False` (controlado y verificado mediante test unitario en el adaptador).
- El historial de conversación relevante se recupera de forma cifrada y acotada desde la base de datos propia de Cora, minimizando datos identificables directos (nombre/apellido/email nunca se envían en el prompt al LLM).

## 3. Arquitectura del Pipeline RAG Clínico

Toda consulta en `rag_assistant` ejecuta estrictamente estas 4 etapas secuenciales:

1. **Etapa 1 — `DeterministicSafetyInterceptor` (`< 5 ms`):** Evalúa reglas y patrones deterministas de urgencia médica o crisis de salud mental. Si hay coincidencia, **aborta inmediatamente la llamada al LLM** y retorna el protocolo de emergencia.
2. **Etapa 2 — Recuperación Dual Controlada:**
   - **Contexto Personal Autorizado:** Resumen estructurado de los últimos ciclos, etapa de vida activa, tratamientos actuales y correlaciones de síntomas de la propia usuaria (`WHERE user_id = :auth_user_id`).
   - **Evidencia Científica Verificada:** Top-K fragmentos (`k = 4..6`) recuperados mediante similitud coseno (`<=>`) sobre índice **HNSW** en `pgvector` filtrados por la etapa de vida activa y fuentes aprobadas (**ACOG, OMS, FIGO, NICE, NAMS/The Menopause Society**).
3. **Etapa 3 — Generación Anclada (*Grounded Generation*):** El `system_instruction` prohíbe responder afirmaciones clínicas no respaldadas por los fragmentos recuperados y prohíbe emitir diagnósticos o prescribir/suspender fármacos.
4. **Etapa 4 — Respuesta Estructurada con Atribución:** La respuesta devuelta al cliente incluye `answer_markdown`, `citations: list[ClinicalCitation]` (título de guía, organización autora, año, identificador de sección) y `disclaimer_level`.
