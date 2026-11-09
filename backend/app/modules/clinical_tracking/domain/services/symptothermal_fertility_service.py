from datetime import date, timedelta
from decimal import Decimal

from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    MenstrualCycle,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    PatientCycleContext,
)
from app.modules.clinical_tracking.domain.value_objects.fertility_biomarkers import (
    CervicalMucusType,
    DailyFertilityLog,
    FertilityStatus,
    FertilityWindowAssessment,
    LhStripResult,
)

MIN_THERMAL_SHIFT_DELTA = Decimal("0.20")


class SymptothermalFertilityService:
    """Clinical domain service evaluating cycle fertility window and ovulatory shift.

    Combines basal body temperature ('3 over 6' rule), cervical fluid patterns,
    urinary LH strip results, and individual patient context (PCOS, age).
    """

    def evaluate_cycle_fertility(
        self,
        current_cycle: MenstrualCycle,
        daily_logs: list[DailyFertilityLog],
        patient_context: PatientCycleContext,
        reference_date: date,
        active_seeking_months: int = 0,
    ) -> FertilityWindowAssessment:
        # Filter and sort logs for the active cycle up to reference_date
        cycle_logs = sorted(
            [
                log
                for log in daily_logs
                if current_cycle.start_date <= log.log_date <= reference_date
            ],
            key=lambda item: item.log_date,
        )

        # 1. Prospective fertile window estimation
        cycle_len = current_cycle.cycle_length_days or 28
        estimated_ovulation_offset = max(10, cycle_len - 14)
        prospective_ovulation_date = current_cycle.start_date + timedelta(
            days=estimated_ovulation_offset - 1
        )
        fertile_start = prospective_ovulation_date - timedelta(days=5)
        fertile_end = prospective_ovulation_date + timedelta(days=1)

        # 2. Extract valid undisturbed BBT readings
        valid_bbt_entries = [
            (log.log_date, log.bbt.celsius)
            for log in cycle_logs
            if log.bbt is not None and not log.bbt.is_disturbed and not log.bbt.is_fever
        ]

        # 3. Apply the symptothermal "3 over 6" rule
        # Need at least 6 low base readings + 3 elevated readings (total 9)
        shift_detected = False
        coverline: Decimal | None = None
        confirmed_ovulation_date: date | None = None

        if len(valid_bbt_entries) >= 9:
            for i in range(6, len(valid_bbt_entries) - 2):
                baseline_temps = [temp for _, temp in valid_bbt_entries[i - 6 : i]]
                cand_coverline = max(baseline_temps)

                t1 = valid_bbt_entries[i][1]
                t2 = valid_bbt_entries[i + 1][1]
                t3 = valid_bbt_entries[i + 2][1]

                if (
                    t1 > cand_coverline
                    and t2 > cand_coverline
                    and t3 > cand_coverline
                    and (t3 - cand_coverline) >= MIN_THERMAL_SHIFT_DELTA
                ):
                    shift_detected = True
                    coverline = cand_coverline
                    # Ovulation is pinpointed to the last day of low baseline
                    confirmed_ovulation_date = valid_bbt_entries[i - 1][0]
                    break

        # 4. Biomarkers on reference date or last 2 days (LH peak / fertile mucus)
        recent_logs = [
            log
            for log in cycle_logs
            if (reference_date - timedelta(days=2)) <= log.log_date <= reference_date
        ]

        has_lh_peak = any(log.lh_result == LhStripResult.PEAK for log in recent_logs)
        has_lh_high = any(log.lh_result == LhStripResult.HIGH for log in recent_logs)
        has_egg_white = any(
            log.cervical_mucus == CervicalMucusType.EGG_WHITE for log in recent_logs
        )
        has_watery = any(
            log.cervical_mucus == CervicalMucusType.WATERY for log in recent_logs
        )

        # 5. Determine FertilityStatus
        if shift_detected:
            status = FertilityStatus.OVULATION_CONFIRMED
            notes = (
                f"Salto térmico bifásico confirmado mediante regla 3 sobre 6 "
                f"(Línea base: {coverline} °C). "
                f"Ovulación confirmada retrospectivamente alrededor de "
                f"{confirmed_ovulation_date}."
            )
        elif has_lh_peak or has_egg_white:
            status = FertilityStatus.PEAK_FERTILITY
            if patient_context.has_pcos:
                notes = (
                    "Detectado pico de biomarcadores (LH pico / moco elástico). "
                    "En usuarias con SOP pueden presentarse oleadas múltiples de LH; "
                    "la confirmación requiere el ascenso térmico basal."
                )
            else:
                notes = (
                    "Ventana de fertilidad óptima detectada por biomarcadores "
                    "(pico de LH o moco cervical fértil)."
                )
        elif has_lh_high or has_watery:
            status = FertilityStatus.HIGH
            notes = "Fertilidad alta. Moco lubricante o incremento en niveles de LH."
        elif fertile_start <= reference_date <= fertile_end:
            status = FertilityStatus.HIGH
            notes = (
                f"Ventana fértil calculada del {fertile_start} al {fertile_end}. "
                "Registra moco cervical y LH para calibrar con mayor exactitud."
            )
        else:
            status = FertilityStatus.LOW
            notes = "Probabilidad de concepción baja en este momento del ciclo."

        # 6. Age and duration based medical guidance
        user_age = reference_date.year - patient_context.birth_year
        guidance_es: str | None = None
        if user_age < 35 and active_seeking_months >= 12:
            guidance_es = (
                "Has registrado 12 meses o más de búsqueda activa. "
                "Las guías clínicas internacionales (ACOG/OMS) recomiendan acudir a un "
                "especialista en fertilidad para una valoración preventiva integral."
            )
        elif user_age >= 35 and active_seeking_months >= 6:
            guidance_es = (
                "Has registrado 6 meses o más de búsqueda activa. "
                "A partir de los 35 años, las guías clínicas aconsejan solicitar una "
                "valoración con un especialista para optimizar tiempos y reserva."
            )

        return FertilityWindowAssessment(
            status=status,
            coverline_celsius=coverline,
            ovulation_confirmed_date=confirmed_ovulation_date,
            fertile_window_start=fertile_start,
            fertile_window_end=fertile_end,
            is_biphasic_shift_detected=shift_detected,
            evaluation_notes_es=notes,
            active_seeking_guidance_es=guidance_es,
        )
