"""PII-free UserClinicalMemoryAssembler and deterministic cycle correlations."""

from collections import defaultdict
from dataclasses import dataclass, field
from datetime import UTC, datetime

from app.modules.rag_assistant.domain.entities import AssembledClinicalMemory


@dataclass(frozen=True)
class CycleDaySymptomPoint:
    """Single symptom observation mapped to a relative cycle index and cycle day."""

    cycle_index: int
    cycle_day: int
    symptom: str


@dataclass(frozen=True)
class RawUserClinicalSnapshot:
    """Raw longitudinal user data (may include PII that MUST be stripped)."""

    first_name: str = ""
    last_name: str = ""
    email: str = ""
    birth_year: int = 1995
    current_life_stage: str = "regular_adult"
    diagnosed_conditions: list[str] = field(default_factory=list)
    hormonal_method: str = "none"
    recent_cycle_lengths: list[int] = field(default_factory=list)
    current_cycle_day: int | None = None
    current_cycle_phase: str | None = None
    symptom_points: list[CycleDaySymptomPoint] = field(default_factory=list)
    active_treatments: list[str] = field(default_factory=list)
    stage_specific_notes: str = ""


class UserClinicalMemoryAssembler:
    """Builds an anonymized clinical memory summary and cycle-day correlations."""

    def __init__(self, reference_year: int | None = None) -> None:
        self._reference_year = reference_year or datetime.now(UTC).year

    def assemble(self, snapshot: RawUserClinicalSnapshot) -> AssembledClinicalMemory:
        """Assemble PII-free longitudinal clinical context for RAG prompting."""
        age_years = max(10, min(100, self._reference_year - snapshot.birth_year))
        clean_conditions = [
            c for c in snapshot.diagnosed_conditions if c and c != "none"
        ]

        if snapshot.recent_cycle_lengths:
            avg_len = round(
                sum(snapshot.recent_cycle_lengths) / len(snapshot.recent_cycle_lengths)
            )
            min_len = min(snapshot.recent_cycle_lengths)
            max_len = max(snapshot.recent_cycle_lengths)
            cycle_summary = (
                f"Longitud media {avg_len} días (rango {min_len}–{max_len} días "
                f"en {len(snapshot.recent_cycle_lengths)} ciclos)."
            )
        else:
            cycle_summary = "Sin ciclos cerrados suficientes aún."

        if snapshot.current_cycle_day is not None:
            phase_label = snapshot.current_cycle_phase or "en curso"
            cycle_summary += (
                f" Día actual del ciclo: {snapshot.current_cycle_day} "
                f"(fase: {phase_label})."
            )

        correlations = self._detect_cycle_day_correlations(snapshot.symptom_points)

        return AssembledClinicalMemory(
            life_stage=snapshot.current_life_stage,
            age_years=age_years,
            diagnosed_conditions=clean_conditions,
            hormonal_method=snapshot.hormonal_method,
            cycle_summary=cycle_summary,
            detected_correlations=correlations,
            active_treatments=list(snapshot.active_treatments),
            stage_specific_summary=snapshot.stage_specific_notes,
        )

    @staticmethod
    def _detect_cycle_day_correlations(
        points: list[CycleDaySymptomPoint],
    ) -> list[str]:
        """Detect symptoms occurring in >= 2 distinct cycles within a narrow window."""
        by_symptom: dict[str, list[CycleDaySymptomPoint]] = defaultdict(list)
        for pt in points:
            norm_sym = pt.symptom.strip().lower()
            if norm_sym:
                by_symptom[norm_sym].append(pt)

        insights: list[str] = []
        for symptom, occurrences in sorted(by_symptom.items()):
            distinct_cycles = {o.cycle_index for o in occurrences}
            if len(distinct_cycles) >= 2:
                days = [o.cycle_day for o in occurrences]
                min_day = min(days)
                max_day = max(days)
                if max_day - min_day <= 6:
                    insights.append(
                        f"Patrón recurrente de '{symptom}' registrado entre los "
                        f"días {min_day} y {max_day} del ciclo en "
                        f"{len(distinct_cycles)} ciclos."
                    )
        return insights
