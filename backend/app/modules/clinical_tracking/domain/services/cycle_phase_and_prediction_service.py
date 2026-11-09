import statistics
from datetime import date, timedelta

from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    MenstrualCycle,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    CyclePhase,
    CycleStatusSnapshot,
    PatientCycleContext,
)
from app.modules.identity.domain.value_objects.life_stage import LifeStage


class CyclePhaseAndPredictionService:
    """Clinical domain service computing cycle phases and predictions.

    Adapted to the user's biological life stage, hormonal methods, and diagnosed
    conditions.
    """

    def compute_status(
        self,
        cycles: list[MenstrualCycle],
        context: PatientCycleContext,
        reference_date: date,
    ) -> CycleStatusSnapshot:
        if not cycles:
            return CycleStatusSnapshot(
                current_cycle_id=None,
                day_in_cycle=None,
                current_phase=CyclePhase.FOLLICULAR,
                predicted_next_period=None,
                fertile_window_start=None,
                fertile_window_end=None,
                ovulation_date=None,
                is_hormonally_managed=context.is_hormonally_suppressed,
                has_extended_uncertainty=(
                    context.life_stage == LifeStage.ADOLESCENCE or context.has_pcos
                ),
                phase_description_es=(
                    "Sin ciclos registrados aún. "
                    "Registra tu sangrado para iniciar el seguimiento."
                ),
                daily_tip_es=(
                    "Bienvenida a Cora. "
                    "Registra tus síntomas diarios para calibrar tus algoritmos."
                ),
            )

        # Sort cycles chronologically
        sorted_cycles = sorted(cycles, key=lambda c: c.start_date)

        # Identify current active cycle (either explicitly current or latest start)
        current_cycle = next(
            (c for c in reversed(sorted_cycles) if c.is_current),
            sorted_cycles[-1],
        )

        day_in_cycle = max(1, (reference_date - current_cycle.start_date).days + 1)

        # Estimate cycle length from historical completed cycles
        completed_lengths = [
            c.cycle_length_days
            for c in sorted_cycles
            if c.cycle_length_days is not None and c.cycle_length_days > 0
        ]

        if completed_lengths:
            median_length = int(round(statistics.median(completed_lengths)))
        else:
            median_length = (
                32
                if (context.life_stage == LifeStage.ADOLESCENCE or context.has_pcos)
                else 28
            )

        bleeding_duration = current_cycle.bleeding_duration_days or 5

        # 1. Hormonally Managed Cycle
        if context.is_hormonally_suppressed:
            predicted_next = current_cycle.start_date + timedelta(days=median_length)
            return CycleStatusSnapshot(
                current_cycle_id=current_cycle.id,
                day_in_cycle=day_in_cycle,
                current_phase=CyclePhase.HORMONALLY_MANAGED,
                predicted_next_period=predicted_next,
                fertile_window_start=None,
                fertile_window_end=None,
                ovulation_date=None,
                is_hormonally_managed=True,
                has_extended_uncertainty=False,
                phase_description_es=(
                    "Ciclo bajo gestión hormonal. La ovulación natural está suspendida "
                    "y el sangrado corresponde a hemorragia por deprivación "
                    "o manchado esperado."
                ),
                daily_tip_es=(
                    "Mantén la toma o aplicación de tu tratamiento en el "
                    "horario habitual para asegurar máxima eficacia."
                ),
            )

        # 2. Natural Cycle Predictions
        has_extended_uncertainty = (
            context.life_stage == LifeStage.ADOLESCENCE or context.has_pcos
        )

        # Luteal phase standard is ~14 days; ovulation is cycle_length - 14
        ovulation_day = max(bleeding_duration + 2, median_length - 14)
        ovulation_date = current_cycle.start_date + timedelta(days=ovulation_day - 1)
        fertile_start = ovulation_date - timedelta(days=5)
        fertile_end = ovulation_date + timedelta(days=1)
        predicted_next = current_cycle.start_date + timedelta(days=median_length)

        # Determine phase based on day_in_cycle
        if day_in_cycle <= bleeding_duration:
            current_phase = CyclePhase.MENSTRUAL
            phase_desc = (
                "Fase menstrual activa. Tu cuerpo está renovando el endometrio."
            )
            daily_tip = (
                "Prioriza descanso, hidratación tibia y alimentos ricos en hierro."
            )
        elif day_in_cycle < (ovulation_day - 1):
            current_phase = CyclePhase.FOLLICULAR
            phase_desc = (
                "Fase folicular. Los estrógenos comienzan a elevarse, "
                "aumentando tu energía y vitalidad."
            )
            daily_tip = (
                "Excelente momento para proyectos creativos, "
                "actividad física y aprendizaje."
            )
        elif day_in_cycle <= (ovulation_day + 1):
            current_phase = CyclePhase.OVULATORY
            phase_desc = (
                "Fase ovulatoria y ventana fértil. "
                "Ocurre el pico de LH y liberación del óvulo."
            )
            daily_tip = "Tu vitalidad y comunicación social alcanzan su punto óptimo."
        else:
            current_phase = CyclePhase.LUTEAL
            phase_desc = (
                "Fase lútea. La progesterona predomina preparando "
                "tu cuerpo para el nuevo ciclo."
            )
            daily_tip = (
                "Favorece actividades tranquilas, magnesio y descanso reparador."
            )

        # Adapt descriptions for Adolescence & PCOS
        if context.life_stage == LifeStage.ADOLESCENCE:
            phase_desc += (
                " Durante los primeros años de desarrollo tras la menarquia, "
                "la variabilidad del ciclo es fisiológicamente normal."
            )

        if context.has_pcos:
            daily_tip = (
                "Con diagnóstico de SOP, la ovulación variable es habitual; "
                "enfócate en balance glucémico y hábitos antiinflamatorios."
            )

        return CycleStatusSnapshot(
            current_cycle_id=current_cycle.id,
            day_in_cycle=day_in_cycle,
            current_phase=current_phase,
            predicted_next_period=predicted_next,
            fertile_window_start=fertile_start,
            fertile_window_end=fertile_end,
            ovulation_date=ovulation_date,
            is_hormonally_managed=False,
            has_extended_uncertainty=has_extended_uncertainty,
            phase_description_es=phase_desc,
            daily_tip_es=daily_tip,
        )
