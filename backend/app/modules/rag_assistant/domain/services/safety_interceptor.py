"""Deterministic clinical safety interceptor (< 5 ms, 0 LLM calls on red flags)."""

import re
import unicodedata
from dataclasses import dataclass
from enum import StrEnum


class SafetyTriageCategory(StrEnum):
    """Critical clinical red-flag categories that bypass the LLM immediately."""

    NONE = "NONE"
    HEMORRHAGE_EMERGENCY = "HEMORRHAGE_EMERGENCY"
    ECTOPIC_OR_ACUTE_PELVIC_EMERGENCY = "ECTOPIC_OR_ACUTE_PELVIC_EMERGENCY"
    OBSTETRIC_PREECLAMPSIA_EMERGENCY = "OBSTETRIC_PREECLAMPSIA_EMERGENCY"
    FETAL_MOVEMENT_EMERGENCY = "FETAL_MOVEMENT_EMERGENCY"
    POSTPARTUM_INFECTION_EMERGENCY = "POSTPARTUM_INFECTION_EMERGENCY"
    CARDIORESPIRATORY_THROMBOSIS_EMERGENCY = "CARDIORESPIRATORY_THROMBOSIS_EMERGENCY"
    MENTAL_HEALTH_CRISIS = "MENTAL_HEALTH_CRISIS"


@dataclass(frozen=True)
class SafetyTriageResult:
    """Outcome of deterministic clinical safety triage."""

    is_emergency: bool
    category: SafetyTriageCategory
    urgent_response_markdown: str
    disclaimer_level: str
    emergency_numbers: list[str]


_CATEGORY_DIRECTIVES: dict[SafetyTriageCategory, str] = {
    SafetyTriageCategory.MENTAL_HEALTH_CRISIS: (
        "### Apoyo Prioritario e Inmediato — No Estás Sola\n\n"
        "Notamos que estás atravesando un momento de profundo malestar emocional. "
        "**Tu vida y tu bienestar son lo más importante.** Cora no reemplaza la "
        "atención en crisis, pero queremos acompañarte a recibir ayuda humana "
        "profesional ahora mismo:\n\n"
        "- **Línea de la Vida / Prevención del Suicidio (24/7):** Llama al **988** "
        "o al **800-911-2000** (gratuito y confidencial).\n"
        "- **Emergencias Generales:** Llama al **911** o acude al servicio de "
        "urgencias más cercano.\n"
        "- Por favor comunícate en este momento con un familiar, pareja o "
        "profesional de confianza."
    ),
    SafetyTriageCategory.HEMORRHAGE_EMERGENCY: (
        "### Alerta Clínica de Urgencia — Sangrado Uterino Severo\n\n"
        "Los síntomas que describes (empapar una o más toallas/tampones por hora "
        "de forma continua o sangrado abundante con mareo/desmayo) constituyen un "
        "**signo de alarma de hemorragia aguda**.\n\n"
        "- **Acción inmediata:** Acude ahora mismo al **servicio de urgencias "
        "ginecológicas u hospitalarias más cercano** o llama al **911**.\n"
        "- No conduzcas por tu cuenta; pide a alguien que te acompañe de inmediato."
    ),
    SafetyTriageCategory.ECTOPIC_OR_ACUTE_PELVIC_EMERGENCY: (
        "### Alerta Clínica de Urgencia — Dolor Pélvico o Abdominal Agudo\n\n"
        "Un dolor pélvico o abdominal bajo súbito, desgarrador o unilateral "
        "(especialmente si se acompaña de sangrado en embarazo temprano, mareo o "
        "desmayo) requiere **descartar de inmediato una urgencia ginecológica o "
        "embarazo ectópico**.\n\n"
        "- **Acción inmediata:** Dirígete sin demora a **urgencias médicas** o "
        "comunícate al **911**."
    ),
    SafetyTriageCategory.OBSTETRIC_PREECLAMPSIA_EMERGENCY: (
        "### Alerta Obstétrica Inmediata — Signos de Alarma de Preeclampsia\n\n"
        "La presencia de presión arterial severamente elevada (`>= 160/110 mmHg`) "
        "o síntomas como dolor de cabeza intenso, alteraciones visuales (luces, "
        "visión borrosa, escotomas), dolor en la boca del estómago o hinchazón "
        "súbita requieren **valoración obstétrica hospitalaria inmediata** según "
        "las guías ACOG.\n\n"
        "- **Acción inmediata:** Acude a **urgencias maternales/obstétricas** "
        "ahora mismo o llama al **911**."
    ),
    SafetyTriageCategory.FETAL_MOVEMENT_EMERGENCY: (
        "### Alerta Obstétrica Inmediata — Disminución de Movimientos Fetales\n\n"
        "Notar una disminución marcada o ausencia de los movimientos habituales "
        "de tu bebé requiere **monitoreo fetal electrónico y valoración obstétrica "
        "inmediata**.\n\n"
        "- **Acción inmediata:** Acude hoy mismo, sin esperar, al **servicio de "
        "urgencias obstétricas** o contacta a tu obstetra de guardia."
    ),
    SafetyTriageCategory.POSTPARTUM_INFECTION_EMERGENCY: (
        "### Alerta Clínica en el Puerperio — Fiebre o Signos de Infección\n\n"
        "La fiebre en el posparto (`>= 38.0 °C`) acompañada de loquios con olor "
        "fétido, escalofríos o secreción purulenta en la herida quirúrgica es un "
        "signo de alarma que requiere **evaluación médica urgente para descartar "
        "endometritis o infección puerperal**.\n\n"
        "- **Acción inmediata:** Acude a **urgencias gineco-obstétricas** para "
        "valoración y tratamiento antibiótico oportuno."
    ),
    SafetyTriageCategory.CARDIORESPIRATORY_THROMBOSIS_EMERGENCY: (
        "### Alerta Médica Crítica — Síntomas Cardiorrespiratorios o Trombosis\n\n"
        "El dolor opresivo en el pecho, la falta súbita de aire (disnea) o la "
        "hinchazón dolorosa y caliente en una sola pierna/pantorrilla requieren "
        "**atención médica de emergencia inmediata** para descartar "
        "tromboembolismo.\n\n"
        "- **Acción inmediata:** Llama al **911** o acude a la **sala de "
        "urgencias más cercana** de inmediato."
    ),
}


def _normalize(text: str) -> str:
    """Lowercase and strip accents/diacritics for fast deterministic matching."""
    decomposed = unicodedata.normalize("NFD", text.lower())
    without_accents = "".join(
        ch for ch in decomposed if unicodedata.category(ch) != "Mn"
    )
    return re.sub(r"\s+", " ", without_accents).strip()


_COMPILED_RULES: list[tuple[SafetyTriageCategory, list[re.Pattern[str]]]] = [
    (
        SafetyTriageCategory.MENTAL_HEALTH_CRISIS,
        [
            re.compile(
                r"\b(no quiero vivir|quitarme la vida|terminar con mi vida|"
                r"suicid\w*|hacerme dano|hacerle dano al bebe|"
                r"hacerle dano a mi bebe|mejor sin mi|quiero morir)\b"
            ),
        ],
    ),
    (
        SafetyTriageCategory.FETAL_MOVEMENT_EMERGENCY,
        [
            re.compile(
                r"\b(bebe|bebita|feto)\s+(ya\s+)?(no se mueve|dejo de moverse)\b"
            ),
            re.compile(
                r"\b(no siento|sin|ausencia de|disminucion marcada de)\s+"
                r"(los\s+)?movimientos(\s+fetales|\s+de mi bebe)?\b"
            ),
        ],
    ),
    (
        SafetyTriageCategory.OBSTETRIC_PREECLAMPSIA_EMERGENCY,
        [
            re.compile(r"\b(1[6-9]\d|2\d\d)\s*/\s*(1[1-4]\d)\b"),
            re.compile(
                r"\b(cefalea|dolor de cabeza).{0,55}"
                r"(luces|lucecitas|borros\w*|escotomas|manchas negras|zumbido)\b"
            ),
            re.compile(
                r"\b(escotomas|vision borrosa|veo luces|veo lucecitas).{0,55}"
                r"(embaraz\w*|epigastri\w*|boca del estomago|cefalea|cabeza)\b"
            ),
        ],
    ),
    (
        SafetyTriageCategory.HEMORRHAGE_EMERGENCY,
        [
            re.compile(
                r"\b(empap\w+|lleno|cambio).{0,45}"
                r"(toalla\w*|tampon\w*).{0,35}"
                r"(cada hora|por hora|40 minutos|30 minutos)\b"
            ),
            re.compile(
                r"\b(hemorragia|sangrado\s+(muy\s+)?fuerte|coagulos\s+gigantes).{0,50}"
                r"(desmay\w*|maread\w*|borroso)\b"
            ),
        ],
    ),
    (
        SafetyTriageCategory.ECTOPIC_OR_ACUTE_PELVIC_EMERGENCY,
        [
            re.compile(
                r"\b(dolor\s+(pelvico|abdominal(\s+bajo)?)|punzada\s+abdominal).{0,45}"
                r"(subito|insoportable|desgarrador\w*|unilateral|"
                r"no me deja ni caminar)\b"
            ),
            re.compile(
                r"\bembaraz\w*.{0,45}sangrado.{0,35}dolor\s+agudo\s+unilateral\b"
            ),
        ],
    ),
    (
        SafetyTriageCategory.POSTPARTUM_INFECTION_EMERGENCY,
        [
            re.compile(
                r"\b(fiebre|38\.\d|39(\.\d)?).{0,55}"
                r"(loquios.{0,20}mal|olor\s+fetido|pus|cesarea)\b"
            ),
            re.compile(
                r"\b(cesarea|posparto).{0,55}(pus|olor\s+fetido|loquios\s+huelen\s+muy\s+mal)\b"
            ),
        ],
    ),
    (
        SafetyTriageCategory.CARDIORESPIRATORY_THROMBOSIS_EMERGENCY,
        [
            re.compile(
                r"\b(dolor\s+en\s+el\s+pecho|dolor\s+toracico|disnea\s+subita|"
                r"me\s+falta\s+el\s+aire\s+de\s+repente|no\s+puedo\s+respirar)\b"
            ),
            re.compile(
                r"\b(pierna|pantorrilla).{0,45}(hinchada|roja).{0,30}caliente\b"
            ),
        ],
    ),
]


class DeterministicSafetyInterceptor:
    """Evaluates free-text clinical queries in < 5ms before any LLM call."""

    def evaluate(
        self,
        query_text: str,
        life_stage: str | None = None,
    ) -> SafetyTriageResult:
        """Return immediate emergency directive if any clinical red flag matches."""
        normalized = _normalize(query_text)
        for category, patterns in _COMPILED_RULES:
            for pattern in patterns:
                if pattern.search(normalized):
                    return SafetyTriageResult(
                        is_emergency=True,
                        category=category,
                        urgent_response_markdown=_CATEGORY_DIRECTIVES[category],
                        disclaimer_level="EMERGENCY_URGENT",
                        emergency_numbers=["911", "988", "800-911-2000"],
                    )

        return SafetyTriageResult(
            is_emergency=False,
            category=SafetyTriageCategory.NONE,
            urgent_response_markdown="",
            disclaimer_level="STANDARD",
            emergency_numbers=[],
        )
