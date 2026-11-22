import calendar
from datetime import date, timedelta

from app.modules.clinical_tracking.domain.models.menstrual_cycle import (
    CycleSymptomLog,
    MenstrualCycle,
)
from app.modules.clinical_tracking.domain.services.cycle_phase_and_prediction_service import (  # noqa: E501
    CyclePhaseAndPredictionService,
)
from app.modules.clinical_tracking.domain.value_objects.bleeding_and_symptoms import (
    BleedingFlow,
    CalendarDayMarker,
    CalendarDayProjection,
    CalendarDisplayMode,
    CalendarMonthProjection,
    CyclePhase,
    FertilityProbability,
    PatientCycleContext,
)
from app.modules.identity.domain.value_objects.life_stage import LifeStage


class CycleCalendarProjectionService:
    """Pure domain service projecting a calendar month with biological markers.

    Supports historical recorded periods, multi-month projected periods,
    fertile windows, predicted ovulation, symptom overlays, and adaptation across
    all 7 biological life stages.
    """

    def __init__(
        self,
        prediction_service: CyclePhaseAndPredictionService | None = None,
    ) -> None:
        self._prediction_service = (
            prediction_service or CyclePhaseAndPredictionService()
        )

    @staticmethod
    def resolve_display_mode(context: PatientCycleContext) -> CalendarDisplayMode:
        """Select display mode adapted to the user's active stage & hormonal state."""
        if context.life_stage == LifeStage.PREGNANCY:
            return CalendarDisplayMode.PREGNANCY_GESTATIONAL
        if context.life_stage == LifeStage.SENIOR_VITALITY:
            return CalendarDisplayMode.SENIOR_PREVENTIVE
        if context.life_stage == LifeStage.POSTPARTUM:
            return CalendarDisplayMode.POSTPARTUM_RECOVERY
        if context.is_hormonally_suppressed:
            return CalendarDisplayMode.HORMONALLY_MANAGED
        if context.life_stage == LifeStage.ADOLESCENCE:
            return CalendarDisplayMode.ADOLESCENCE_FLEXIBLE
        if context.life_stage == LifeStage.CONCEPTION_SEARCH:
            return CalendarDisplayMode.CONCEPTION_FERTILITY
        if context.life_stage == LifeStage.PERIMENOPAUSE:
            return CalendarDisplayMode.PERIMENOPAUSE_STRAW10
        return CalendarDisplayMode.STANDARD_CYCLE

    @staticmethod
    def _phase_education(phase: CyclePhase | None, stage: LifeStage) -> str:
        if stage == LifeStage.PREGNANCY:
            return (
                "Seguimiento gestacional ACOG: monitorea movimientos fetales, "
                "tensión arterial y próximas citas prenatales."
            )
        if stage == LifeStage.SENIOR_VITALITY:
            return (
                "Calendario preventivo integral: enfocado en vitalidad ósea, "
                "salud cardiovascular y controles médicos periódicos."
            )
        if phase == CyclePhase.MENSTRUAL:
            return (
                "Fase menstrual: el endometrio se renueva de forma fisiológica. "
                "Prioriza descanso, hidratación tibia y aportes de hierro."
            )
        if phase == CyclePhase.FOLLICULAR:
            return (
                "Fase folicular: los estrógenos aumentan progresivamente, "
                "favoreciendo tu energía física, enfoque y vitalidad."
            )
        if phase == CyclePhase.OVULATORY:
            return (
                "Fase ovulatoria: pico hormonal de LH y mayor probabilidad fértil "
                "en torno a la liberación del óvulo."
            )
        if phase == CyclePhase.LUTEAL:
            return (
                "Fase lútea: predomina la progesterona. Es habitual notar mayor "
                "necesidad de calma, hidratación y sueño reparador."
            )
        if phase == CyclePhase.HORMONALLY_MANAGED:
            return (
                "Ciclo modulado por tratamiento hormonal: las fluctuaciones "
                "ovulatorias naturales permanecen en reposo."
            )
        return (
            "Registra tus fechas o síntomas diarios para construir tu mapa "
            "biológico personalizado."
        )

    def project_month(
        self,
        *,
        year: int,
        month: int,
        cycles: list[MenstrualCycle],
        symptom_logs: list[CycleSymptomLog],
        context: PatientCycleContext,
        today: date | None = None,
    ) -> CalendarMonthProjection:
        ref_today = today or date.today()
        display_mode = self.resolve_display_mode(context)
        sorted_cycles = sorted(cycles, key=lambda c: c.start_date)
        estimated_cycle_len = self._prediction_service.estimate_cycle_length(
            sorted_cycles, context
        )
        estimated_bleeding_len = context.typical_bleeding_duration_days or (
            sorted_cycles[-1].bleeding_duration_days
            if sorted_cycles and sorted_cycles[-1].bleeding_duration_days
            else 5
        )
        status = self._prediction_service.compute_status(
            cycles=sorted_cycles,
            context=context,
            reference_date=ref_today,
        )

        _, num_days = calendar.monthrange(year, month)
        month_start = date(year, month, 1)
        month_end = date(year, month, num_days)

        logs_by_date: dict[date, CycleSymptomLog] = {
            log.log_date: log for log in symptom_logs
        }

        # Precompute recorded menstrual bleeding dates from cycle aggregates
        recorded_period_dates: set[date] = set()
        for cycle in sorted_cycles:
            bleed_len = cycle.bleeding_duration_days or estimated_bleeding_len
            for offset in range(bleed_len):
                recorded_period_dates.add(cycle.start_date + timedelta(days=offset))

        is_non_menstrual_stage = context.life_stage in (
            LifeStage.PREGNANCY,
            LifeStage.SENIOR_VITALITY,
        ) or (context.life_stage == LifeStage.POSTPARTUM and not sorted_cycles)

        # Build cycle intervals covering past, active, and up to 12 projected cycles
        projected_windows: list[tuple[date, int, int, bool]] = []
        if not is_non_menstrual_stage and sorted_cycles:
            for idx, cycle in enumerate(sorted_cycles):
                cycle_bleed = cycle.bleeding_duration_days or estimated_bleeding_len
                if idx + 1 < len(sorted_cycles):
                    next_start = sorted_cycles[idx + 1].start_date
                    cycle_len = max(15, (next_start - cycle.start_date).days)
                    projected_windows.append(
                        (cycle.start_date, cycle_len, cycle_bleed, True)
                    )
                else:
                    # Active / latest recorded cycle followed by future predictions
                    projected_windows.append(
                        (cycle.start_date, estimated_cycle_len, cycle_bleed, True)
                    )
                    cursor = cycle.start_date
                    for step in range(1, 13):
                        future_start = cursor + timedelta(
                            days=estimated_cycle_len * step
                        )
                        if future_start > month_end:
                            break
                        projected_windows.append(
                            (
                                future_start,
                                estimated_cycle_len,
                                estimated_bleeding_len,
                                False,
                            )
                        )

        days_out: list[CalendarDayProjection] = []
        for day_num in range(1, num_days + 1):
            cur_date = date(year, month, day_num)
            log = logs_by_date.get(cur_date)
            flow = log.bleeding_flow if log else BleedingFlow.NONE
            has_symptoms = log is not None and (
                log.pelvic_pain is not None
                or log.dysmenorrhea is not None
                or log.fatigue_level is not None
                or log.acne_severity is not None
                or bool(log.gi_symptoms)
                or bool(log.notes)
                or flow != BleedingFlow.NONE
            )

            day_in_cycle: int | None = None
            phase: CyclePhase | None = None
            marker = CalendarDayMarker.NONE
            fertility = FertilityProbability.NONE
            daily_summary = "Sin evento menstrual proyectado."

            if is_non_menstrual_stage:
                phase = (
                    CyclePhase.HORMONALLY_MANAGED
                    if context.life_stage != LifeStage.SENIOR_VITALITY
                    else None
                )
                daily_summary = status.phase_description_es
            elif projected_windows:
                matching = self._find_window_for_date(
                    cur_date=cur_date,
                    windows=projected_windows,
                    month_start=month_start,
                )
                if matching is not None:
                    c_start, c_len, c_bleed, is_recorded_cycle = matching
                    day_in_cycle = (cur_date - c_start).days + 1
                    ovul_day = max(c_bleed + 2, c_len - 14)

                    if context.is_hormonally_suppressed:
                        phase = CyclePhase.HORMONALLY_MANAGED
                        if (
                            cur_date in recorded_period_dates
                            or flow.is_menstrual_bleeding
                        ):
                            marker = CalendarDayMarker.RECORDED_PERIOD
                            daily_summary = f"Día {day_in_cycle}: sangrado registrado."
                        elif not is_recorded_cycle and day_in_cycle <= c_bleed:
                            marker = CalendarDayMarker.PREDICTED_PERIOD
                            daily_summary = (
                                f"Día {day_in_cycle}: "
                                "sangrado por deprivación estimado."
                            )
                        elif flow == BleedingFlow.SPOTTING:
                            marker = CalendarDayMarker.SPOTTING
                            daily_summary = (
                                f"Día {day_in_cycle}: "
                                "manchado intermenstrual registrado."
                            )
                        else:
                            daily_summary = f"Día {day_in_cycle} bajo gestión hormonal."
                    else:
                        if day_in_cycle <= c_bleed:
                            phase = CyclePhase.MENSTRUAL
                        elif day_in_cycle < (ovul_day - 1):
                            phase = CyclePhase.FOLLICULAR
                        elif day_in_cycle <= (ovul_day + 1):
                            phase = CyclePhase.OVULATORY
                        else:
                            phase = CyclePhase.LUTEAL

                        if (
                            cur_date in recorded_period_dates
                            or flow.is_menstrual_bleeding
                        ):
                            marker = CalendarDayMarker.RECORDED_PERIOD
                            fertility = FertilityProbability.LOW
                            daily_summary = (
                                f"Día {day_in_cycle}: menstruación registrada."
                            )
                        elif flow == BleedingFlow.SPOTTING:
                            marker = CalendarDayMarker.SPOTTING
                            fertility = (
                                FertilityProbability.MEDIUM
                                if abs(day_in_cycle - ovul_day) <= 4
                                else FertilityProbability.LOW
                            )
                            daily_summary = (
                                f"Día {day_in_cycle}: manchado leve registrado."
                            )
                        elif not is_recorded_cycle and day_in_cycle <= c_bleed:
                            marker = CalendarDayMarker.PREDICTED_PERIOD
                            fertility = FertilityProbability.LOW
                            daily_summary = (
                                f"Día {day_in_cycle}: inicio estimado de tu próximo "
                                "periodo."
                            )
                        elif day_in_cycle == ovul_day:
                            marker = CalendarDayMarker.PREDICTED_OVULATION
                            fertility = FertilityProbability.HIGH
                            daily_summary = (
                                f"Día {day_in_cycle}: día estimado de ovulación."
                            )
                        elif (ovul_day - 5) <= day_in_cycle <= (ovul_day + 1):
                            marker = CalendarDayMarker.FERTILE_WINDOW
                            fertility = (
                                FertilityProbability.HIGH
                                if day_in_cycle == (ovul_day - 1)
                                else FertilityProbability.MEDIUM
                            )
                            daily_summary = (
                                f"Día {day_in_cycle}: ventana fértil estimada."
                            )
                        else:
                            fertility = FertilityProbability.LOW
                            daily_summary = f"Día {day_in_cycle} del ciclo."

            # Override explicitly logged period/spotting even before any cycle exists
            if marker == CalendarDayMarker.NONE:
                if cur_date in recorded_period_dates or flow.is_menstrual_bleeding:
                    marker = CalendarDayMarker.RECORDED_PERIOD
                    daily_summary = "Menstruación registrada."
                elif flow == BleedingFlow.SPOTTING:
                    marker = CalendarDayMarker.SPOTTING
                    daily_summary = "Manchado registrado."

            days_out.append(
                CalendarDayProjection(
                    date=cur_date,
                    day_in_cycle=day_in_cycle,
                    phase=phase,
                    day_marker=marker,
                    fertility_probability=fertility,
                    has_logged_symptoms=has_symptoms,
                    bleeding_flow=flow,
                    pelvic_pain=log.pelvic_pain if log else None,
                    daily_summary_es=daily_summary,
                    phase_education_es=self._phase_education(phase, context.life_stage),
                )
            )

        return CalendarMonthProjection(
            year=year,
            month=month,
            display_mode=display_mode,
            estimated_cycle_length_days=estimated_cycle_len,
            estimated_bleeding_duration_days=estimated_bleeding_len,
            is_hormonally_managed=status.is_hormonally_managed,
            has_extended_uncertainty=status.has_extended_uncertainty,
            current_cycle_day=status.day_in_cycle,
            current_phase=None if is_non_menstrual_stage else status.current_phase,
            predicted_next_period=status.predicted_next_period,
            ovulation_date=status.ovulation_date,
            fertile_window_start=status.fertile_window_start,
            fertile_window_end=status.fertile_window_end,
            days=tuple(days_out),
        )

    @staticmethod
    def _find_window_for_date(
        *,
        cur_date: date,
        windows: list[tuple[date, int, int, bool]],
        month_start: date,
    ) -> tuple[date, int, int, bool] | None:
        del month_start
        for idx, (c_start, c_len, c_bleed, is_recorded) in enumerate(windows):
            if cur_date < c_start:
                continue
            next_start = (
                windows[idx + 1][0]
                if idx + 1 < len(windows)
                else c_start + timedelta(days=c_len)
            )
            if c_start <= cur_date < next_start:
                return (c_start, c_len, c_bleed, is_recorded)
        return None
