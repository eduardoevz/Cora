"""Gemini 3.8 Flash clinical assistant adapter enforcing store=False."""

import json
from typing import Any, Literal

from google import genai
from pydantic import BaseModel, Field

from app.modules.education_content.domain.entities import ClinicalEvidenceChunk
from app.modules.rag_assistant.domain.entities import (
    AssembledClinicalMemory,
    ClinicalCitation,
    GroundedAssistantResult,
)

CLINICAL_SYSTEM_INSTRUCTION = (
    "Eres Cora, asistente de orientación educativa en salud femenina integral "
    "basada en evidencia científica (OMS, ACOG, FIGO, NAMS, ESHRE). "
    "REGLAS INQUEBRANTABLES:\n"
    "1. Tono empático, cálido, claro, en español y nunca alarmista.\n"
    "2. NO emitas diagnósticos médicos definitivos ni prescribas ni modifiques "
    "dosis de medicamentos. Orienta siempre a consultar con su profesional de salud.\n"
    "3. Fundamenta tu respuesta ÚNICAMENTE en los fragmentos de evidencia clínica "
    "numerados [1]..[N] y en el contexto longitudinal anónimo proporcionado.\n"
    "4. Si detectas correlaciones en el registro de la usuaria (ej. síntomas en "
    "días específicos del ciclo), explícalas de forma orientativa vinculándolas "
    "con la evidencia fisiológica recuperada."
)


class StructuredLLMOutputSchema(BaseModel):
    """JSON schema enforced on Gemini 3.8 Flash interactions output."""

    answer_markdown: str = Field(
        ...,
        description="Respuesta educativa empática en Markdown con citas [1], [2].",
    )
    cited_chunk_indices: list[int] = Field(
        default_factory=list,
        description="Índices 1-based de los fragmentos de evidencia utilizados.",
    )
    disclaimer_level: Literal["STANDARD", "RECOMMEND_CONSULTATION"] = Field(
        default="STANDARD",
        description="Nivel de descargo médico recomendado.",
    )
    suggested_follow_ups: list[str] = Field(
        default_factory=list,
        description="2 a 3 preguntas de seguimiento sugeridas.",
    )


class GeminiClinicalAssistantAdapter:
    """Grounded clinical assistant using google-genai (gemini-3.8-flash)."""

    def __init__(
        self,
        client: Any | None = None,
        api_key: str | None = None,
        model_name: str = "gemini-3.8-flash",
    ) -> None:
        self._model_name = model_name
        if client is not None:
            self._client = client
        elif api_key and not api_key.startswith("mock-"):
            self._client = genai.Client(api_key=api_key)
        else:
            self._client = None

    def generate_grounded_answer(
        self,
        *,
        user_query: str,
        clinical_memory: AssembledClinicalMemory,
        evidence_chunks: list[ClinicalEvidenceChunk],
    ) -> GroundedAssistantResult:
        """Call client.interactions.create with store=False and build citations."""
        prompt = self._build_grounded_prompt(
            user_query=user_query,
            clinical_memory=clinical_memory,
            evidence_chunks=evidence_chunks,
        )

        if self._client is not None:
            interaction = self._client.interactions.create(
                model=self._model_name,
                input=prompt,
                system_instruction=CLINICAL_SYSTEM_INSTRUCTION,
                response_format=StructuredLLMOutputSchema.model_json_schema(),
                response_mime_type="application/json",
                store=False,
            )
            raw_text = self._extract_text(interaction)
            if raw_text:
                return self._parse_structured_response(
                    raw_text=raw_text,
                    evidence_chunks=evidence_chunks,
                )

        return self._build_deterministic_grounded_fallback(
            user_query=user_query,
            clinical_memory=clinical_memory,
            evidence_chunks=evidence_chunks,
        )

    @staticmethod
    def _build_grounded_prompt(
        *,
        user_query: str,
        clinical_memory: AssembledClinicalMemory,
        evidence_chunks: list[ClinicalEvidenceChunk],
    ) -> str:
        evidence_lines: list[str] = ["### Evidencia Científica Recuperada"]
        for idx, chunk in enumerate(evidence_chunks, start=1):
            evidence_lines.append(
                f"[{idx}] Fuente: {chunk.scientific_source} | "
                f"Artículo: {chunk.article_title} ({chunk.section_heading})\n"
                f"Contenido: {chunk.content_text}"
            )
        return (
            f"{clinical_memory.to_prompt_block()}\n\n"
            f"{'\n\n'.join(evidence_lines)}\n\n"
            f"### Consulta de la Usuaria\n{user_query.strip()}"
        )

    @staticmethod
    def _extract_text(interaction: Any) -> str:
        direct_text = getattr(interaction, "text", None)
        if isinstance(direct_text, str) and direct_text.strip():
            return direct_text.strip()
        outputs = getattr(interaction, "outputs", None)
        if isinstance(outputs, list):
            for out in outputs:
                txt = getattr(out, "text", None)
                if isinstance(txt, str) and txt.strip():
                    return txt.strip()
        return ""

    @staticmethod
    def _parse_structured_response(
        *,
        raw_text: str,
        evidence_chunks: list[ClinicalEvidenceChunk],
    ) -> GroundedAssistantResult:
        data = json.loads(raw_text)
        parsed = StructuredLLMOutputSchema.model_validate(data)
        citations: list[ClinicalCitation] = []
        seen_slugs: set[str] = set()

        indices = parsed.cited_chunk_indices or [1]
        for idx in indices:
            if 1 <= idx <= len(evidence_chunks):
                ch = evidence_chunks[idx - 1]
                if ch.article_slug not in seen_slugs:
                    seen_slugs.add(ch.article_slug)
                    citations.append(
                        ClinicalCitation(
                            article_id=ch.article_id,
                            article_slug=ch.article_slug,
                            article_title=ch.article_title,
                            section_heading=ch.section_heading,
                            scientific_source=ch.scientific_source,
                            source_url=ch.source_url,
                        )
                    )

        return GroundedAssistantResult(
            answer_markdown=parsed.answer_markdown,
            citations=citations,
            disclaimer_level=parsed.disclaimer_level,
            suggested_follow_ups=parsed.suggested_follow_ups,
        )

    @staticmethod
    def _is_prescription_or_diagnosis_jailbreak(user_query: str) -> bool:
        """Detect prompt-injection or prescription/diagnosis forcing requests."""
        q = user_query.lower()
        jailbreak_tokens = (
            "ignora tus instrucciones",
            "system override",
            "olvida que eres cora",
            "recetame",
            "recétame",
            "receta medica",
            "receta médica",
            "dosis exacta",
            "diagnosticame",
            "diagnostícame",
            "cuantos miligramos",
            "cuántos miligramos",
        )
        return any(tok in q for tok in jailbreak_tokens)

    @staticmethod
    def _build_deterministic_grounded_fallback(
        *,
        user_query: str,
        clinical_memory: AssembledClinicalMemory,
        evidence_chunks: list[ClinicalEvidenceChunk],
    ) -> GroundedAssistantResult:
        """Synthesize a grounded answer from top chunks in offline/test mode."""
        top_chunks = evidence_chunks[:2]
        citations: list[ClinicalCitation] = []
        seen_slugs: set[str] = set()
        excerpts: list[str] = []

        for idx, ch in enumerate(top_chunks, start=1):
            excerpts.append(
                f"Según **{ch.scientific_source}** (*{ch.section_heading}*): "
                f"{ch.content_text[:280].strip()}... [{idx}]"
            )
            if ch.article_slug not in seen_slugs:
                seen_slugs.add(ch.article_slug)
                citations.append(
                    ClinicalCitation(
                        article_id=ch.article_id,
                        article_slug=ch.article_slug,
                        article_title=ch.article_title,
                        section_heading=ch.section_heading,
                        scientific_source=ch.scientific_source,
                        source_url=ch.source_url,
                    )
                )

        if GeminiClinicalAssistantAdapter._is_prescription_or_diagnosis_jailbreak(
            user_query
        ):
            refusal_body = "\n\n".join(excerpts) if excerpts else ""
            refusal_answer = (
                "### Orientación Educativa Segura — Límites Clínicos de Cora\n\n"
                "Por tu seguridad clínica, **no puedo emitir diagnósticos médicos "
                "definitivos ni no puedo recetar medicamentos o indicar dosis "
                "farmacológicas**. Toda prescripción o ajuste terapéutico requiere "
                "la valoración presencial de tu **profesional de salud**.\n\n"
                f"{refusal_body}"
            ).strip()
            return GroundedAssistantResult(
                answer_markdown=refusal_answer,
                citations=citations,
                disclaimer_level="RECOMMEND_CONSULTATION",
                suggested_follow_ups=[
                    "¿Qué síntomas debo anotar para llevar a mi consulta médica?",
                    "¿Cómo generar mi reporte PDF para mi especialista?",
                ],
            )

        correlation_note = ""
        if clinical_memory.detected_correlations:
            correlation_note = (
                "\n\n**Patrón observado en tu registro longitudinal:**\n- "
                + "\n- ".join(clinical_memory.detected_correlations)
            )

        body = (
            "\n\n".join(excerpts)
            if excerpts
            else ("Hemos revisado tu contexto de etapa actual para orientarte.")
        )
        answer = (
            f"### Orientación Basada en Evidencia ({clinical_memory.life_stage})\n\n"
            f"{body}"
            f"{correlation_note}\n\n"
            "*Recuerda que esta orientación es educativa y preventiva; te "
            "recomendamos compartir tu reporte clínico con tu especialista.*"
        )
        return GroundedAssistantResult(
            answer_markdown=answer,
            citations=citations,
            disclaimer_level="STANDARD",
            suggested_follow_ups=[
                "¿Qué señales indican que debo agendar consulta médica?",
                "¿Cómo puedo exportar esta evolución en mi reporte PDF?",
            ],
        )
