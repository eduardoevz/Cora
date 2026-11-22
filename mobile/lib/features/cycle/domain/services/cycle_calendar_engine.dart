import 'dart:math' as math;

import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';

class _ProjectedWindow {
  final DateTime startDate;
  final int cycleLengthDays;
  final int bleedingDurationDays;
  final bool isRecordedCycle;

  const _ProjectedWindow({
    required this.startDate,
    required this.cycleLengthDays,
    required this.bleedingDurationDays,
    required this.isRecordedCycle,
  });
}

/// Pure Dart biological cycle & monthly calendar projection engine.
/// Mirrors backend `CyclePhaseAndPredictionService` and
/// `CycleCalendarProjectionService` without framework dependencies.
class CycleCalendarEngine {
  const CycleCalendarEngine();

  static DateTime normalizeDate(DateTime dt) =>
      DateTime.utc(dt.year, dt.month, dt.day);

  static bool isHormonallySuppressed(HormonalMethod? method) {
    return method == HormonalMethod.combinedOralPill ||
        method == HormonalMethod.progestinOnlyPill ||
        method == HormonalMethod.hormonalIud ||
        method == HormonalMethod.subdermalImplant ||
        method == HormonalMethod.transdermalPatch ||
        method == HormonalMethod.injectable ||
        method == HormonalMethod.hormoneReplacementTherapy;
  }

  static bool hasUncertainty({
    required LifeStage lifeStage,
    required List<DiagnosedCondition> diagnosedConditions,
    required CycleRegularity cycleRegularity,
  }) {
    return lifeStage == LifeStage.adolescence ||
        lifeStage == LifeStage.perimenopause ||
        diagnosedConditions.contains(DiagnosedCondition.pcos) ||
        cycleRegularity == CycleRegularity.irregular;
  }

  int estimateCycleLength({
    required List<MenstrualCycleEntity> cycles,
    required LifeStage lifeStage,
    required List<DiagnosedCondition> diagnosedConditions,
    int? typicalCycleLengthDays,
  }) {
    final completedLengths = cycles
        .where((c) =>
            c.cycleLengthDays != null &&
            c.cycleLengthDays! >= 15 &&
            c.cycleLengthDays! <= 90)
        .map((c) => c.cycleLengthDays!)
        .toList()
      ..sort();

    if (completedLengths.length >= 2) {
      final mid = completedLengths.length ~/ 2;
      if (completedLengths.length.isOdd) {
        return completedLengths[mid];
      }
      return ((completedLengths[mid - 1] + completedLengths[mid]) / 2.0)
          .round();
    }
    if (completedLengths.length == 1) {
      return completedLengths.first;
    }
    if (typicalCycleLengthDays != null &&
        typicalCycleLengthDays >= 15 &&
        typicalCycleLengthDays <= 90) {
      return typicalCycleLengthDays;
    }
    final hasPcos = diagnosedConditions.contains(DiagnosedCondition.pcos);
    return (lifeStage == LifeStage.adolescence || hasPcos) ? 32 : 28;
  }

  static CalendarDisplayMode resolveDisplayMode({
    required LifeStage lifeStage,
    HormonalMethod? hormonalMethod,
  }) {
    if (lifeStage == LifeStage.pregnancy) {
      return CalendarDisplayMode.pregnancyGestational;
    }
    if (lifeStage == LifeStage.seniorVitality) {
      return CalendarDisplayMode.seniorPreventive;
    }
    if (lifeStage == LifeStage.postpartum) {
      return CalendarDisplayMode.postpartumRecovery;
    }
    if (isHormonallySuppressed(hormonalMethod)) {
      return CalendarDisplayMode.hormonallyManaged;
    }
    if (lifeStage == LifeStage.adolescence) {
      return CalendarDisplayMode.adolescenceFlexible;
    }
    if (lifeStage == LifeStage.conceptionSearch) {
      return CalendarDisplayMode.conceptionFertility;
    }
    if (lifeStage == LifeStage.perimenopause) {
      return CalendarDisplayMode.perimenopauseStraw10;
    }
    return CalendarDisplayMode.standardCycle;
  }

  CycleStatusEntity computeStatus({
    required List<MenstrualCycleEntity> cycles,
    required LifeStage lifeStage,
    HormonalMethod? hormonalMethod,
    List<DiagnosedCondition> diagnosedConditions = const [],
    CycleRegularity cycleRegularity = CycleRegularity.unsure,
    int? typicalCycleLengthDays,
    int? typicalBleedingDurationDays,
    DateTime? referenceDate,
  }) {
    final refDate = normalizeDate(referenceDate ?? DateTime.now());
    final suppressed = isHormonallySuppressed(hormonalMethod);
    final uncertainty = hasUncertainty(
      lifeStage: lifeStage,
      diagnosedConditions: diagnosedConditions,
      cycleRegularity: cycleRegularity,
    );

    if (lifeStage == LifeStage.pregnancy) {
      return const CycleStatusEntity(
        currentPhase: 'hormonally_managed',
        isHormonallyManaged: true,
        hasExtendedUncertainty: false,
        phaseDescriptionEs:
            'Etapa de gestación activa. El ciclo menstrual y la ovulación '
            'permanecen fisiológicamente pausados durante el embarazo.',
        dailyTipEs:
            'Registra tu presión arterial y síntomas maternos en tu Hub '
            'Maternal para tu seguimiento ACOG.',
      );
    }

    if (lifeStage == LifeStage.seniorVitality) {
      return const CycleStatusEntity(
        currentPhase: 'hormonally_managed',
        isHormonallyManaged: false,
        hasExtendedUncertainty: false,
        phaseDescriptionEs:
            'Etapa de plenitud posmenopáusica. Tus recordatorios están '
            'enfocados en prevención cardiovascular, ósea y chequeos anuales.',
        dailyTipEs: 'Mantén hidratación, fuerza muscular suave y tus controles '
            'preventivos al día.',
      );
    }

    if (cycles.isEmpty) {
      if (lifeStage == LifeStage.postpartum) {
        return const CycleStatusEntity(
          currentPhase: 'hormonally_managed',
          isHormonallyManaged: true,
          hasExtendedUncertainty: true,
          phaseDescriptionEs:
              'Etapa de posparto y lactancia. El retorno menstrual es '
              'gradual y variable tras el nacimiento.',
          dailyTipEs:
              'Prioriza descanso, hidratación y registro de recuperación y '
              'bienestar emocional EPDS.',
        );
      }
      return CycleStatusEntity(
        currentPhase: 'follicular',
        isHormonallyManaged: suppressed,
        hasExtendedUncertainty: uncertainty,
        phaseDescriptionEs:
            'Sin ciclos registrados aún. Registra tu sangrado o últimos '
            'periodos para iniciar.',
        dailyTipEs:
            'Bienvenida a Cora. Registra tus síntomas diarios para calibrar '
            'tus algoritmos.',
      );
    }

    final sortedCycles = [...cycles]..sort((a, b) =>
        normalizeDate(a.startDate).compareTo(normalizeDate(b.startDate)));

    final currentCycle = sortedCycles.lastWhere(
      (c) => c.isCurrent,
      orElse: () => sortedCycles.last,
    );

    final currentStart = normalizeDate(currentCycle.startDate);
    final dayInCycle = math.max(1, refDate.difference(currentStart).inDays + 1);
    final estimatedLen = estimateCycleLength(
      cycles: sortedCycles,
      lifeStage: lifeStage,
      diagnosedConditions: diagnosedConditions,
      typicalCycleLengthDays: typicalCycleLengthDays,
    );
    final bleedingDuration =
        currentCycle.bleedingDurationDays ?? typicalBleedingDurationDays ?? 5;

    if (suppressed) {
      return CycleStatusEntity(
        currentCycleId: currentCycle.id,
        dayInCycle: dayInCycle,
        currentPhase: 'hormonally_managed',
        predictedNextPeriod: currentStart.add(Duration(days: estimatedLen)),
        isHormonallyManaged: true,
        hasExtendedUncertainty: false,
        phaseDescriptionEs:
            'Ciclo bajo gestión hormonal. La ovulación natural está '
            'suspendida y el sangrado corresponde a hemorragia por '
            'deprivación o manchado esperado.',
        dailyTipEs:
            'Mantén la toma o aplicación de tu tratamiento en el horario '
            'habitual para asegurar máxima eficacia.',
      );
    }

    final ovulationDay = math.max(bleedingDuration + 2, estimatedLen - 14);
    final ovulationDate = currentStart.add(Duration(days: ovulationDay - 1));
    final fertileStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDate.add(const Duration(days: 1));
    final predictedNext = currentStart.add(Duration(days: estimatedLen));

    late final String currentPhase;
    late String phaseDesc;
    late String dailyTip;

    if (dayInCycle <= bleedingDuration) {
      currentPhase = 'menstrual';
      phaseDesc =
          'Fase menstrual activa. Tu cuerpo está renovando el endometrio.';
      dailyTip =
          'Prioriza descanso, hidratación tibia y alimentos ricos en hierro.';
    } else if (dayInCycle < ovulationDay - 1) {
      currentPhase = 'follicular';
      phaseDesc =
          'Fase folicular. Los estrógenos comienzan a elevarse, aumentando tu '
          'energía y vitalidad.';
      dailyTip =
          'Excelente momento para proyectos creativos, actividad física y '
          'aprendizaje.';
    } else if (dayInCycle <= ovulationDay + 1) {
      currentPhase = 'ovulatory';
      phaseDesc = 'Fase ovulatoria y ventana fértil. Ocurre el pico de LH y '
          'liberación del óvulo.';
      dailyTip = 'Tu vitalidad y comunicación social alcanzan su punto óptimo.';
    } else {
      currentPhase = 'luteal';
      phaseDesc =
          'Fase lútea. La progesterona predomina preparando tu cuerpo para '
          'el nuevo ciclo.';
      dailyTip =
          'Favorece actividades tranquilas, magnesio y descanso reparador.';
    }

    if (lifeStage == LifeStage.adolescence) {
      phaseDesc = '$phaseDesc Durante los primeros años de desarrollo tras la '
          'menarquia, la variabilidad del ciclo es fisiológicamente normal.';
    }
    if (diagnosedConditions.contains(DiagnosedCondition.pcos)) {
      dailyTip =
          'Con diagnóstico de SOP, la ovulación variable es habitual; enfócate '
          'en balance glucémico y hábitos antiinflamatorios.';
    }

    return CycleStatusEntity(
      currentCycleId: currentCycle.id,
      dayInCycle: dayInCycle,
      currentPhase: currentPhase,
      predictedNextPeriod: predictedNext,
      fertileWindowStart: fertileStart,
      fertileWindowEnd: fertileEnd,
      ovulationDate: ovulationDate,
      isHormonallyManaged: false,
      hasExtendedUncertainty: uncertainty,
      phaseDescriptionEs: phaseDesc,
      dailyTipEs: dailyTip,
    );
  }

  CalendarMonthProjectionEntity projectMonth({
    required int year,
    required int month,
    required List<MenstrualCycleEntity> cycles,
    required List<CycleSymptomEntity> symptomLogs,
    required LifeStage lifeStage,
    HormonalMethod? hormonalMethod,
    List<DiagnosedCondition> diagnosedConditions = const [],
    CycleRegularity cycleRegularity = CycleRegularity.unsure,
    int? typicalCycleLengthDays,
    int? typicalBleedingDurationDays,
    DateTime? referenceDate,
  }) {
    final refToday = normalizeDate(referenceDate ?? DateTime.now());
    final suppressed = isHormonallySuppressed(hormonalMethod);
    final displayMode = resolveDisplayMode(
      lifeStage: lifeStage,
      hormonalMethod: hormonalMethod,
    );
    final sortedCycles = [...cycles]..sort((a, b) =>
        normalizeDate(a.startDate).compareTo(normalizeDate(b.startDate)));

    final estimatedCycleLen = estimateCycleLength(
      cycles: sortedCycles,
      lifeStage: lifeStage,
      diagnosedConditions: diagnosedConditions,
      typicalCycleLengthDays: typicalCycleLengthDays,
    );
    final estimatedBleedingLen = typicalBleedingDurationDays ??
        (sortedCycles.isNotEmpty
            ? (sortedCycles.last.bleedingDurationDays ?? 5)
            : 5);

    final status = computeStatus(
      cycles: sortedCycles,
      lifeStage: lifeStage,
      hormonalMethod: hormonalMethod,
      diagnosedConditions: diagnosedConditions,
      cycleRegularity: cycleRegularity,
      typicalCycleLengthDays: typicalCycleLengthDays,
      typicalBleedingDurationDays: typicalBleedingDurationDays,
      referenceDate: refToday,
    );

    final numDays = DateTime.utc(year, month + 1, 0).day;
    final monthEnd = DateTime.utc(year, month, numDays);

    final logsByDate = <DateTime, CycleSymptomEntity>{};
    for (final log in symptomLogs) {
      logsByDate[normalizeDate(log.logDate)] = log;
    }

    final recordedPeriodDates = <DateTime>{};
    for (final c in sortedCycles) {
      final bleedLen = c.bleedingDurationDays ?? estimatedBleedingLen;
      final cStart = normalizeDate(c.startDate);
      for (var offset = 0; offset < bleedLen; offset++) {
        recordedPeriodDates.add(cStart.add(Duration(days: offset)));
      }
    }

    final isNonMenstrualStage = lifeStage == LifeStage.pregnancy ||
        lifeStage == LifeStage.seniorVitality ||
        (lifeStage == LifeStage.postpartum && sortedCycles.isEmpty);

    final windows = <_ProjectedWindow>[];
    if (!isNonMenstrualStage && sortedCycles.isNotEmpty) {
      for (var i = 0; i < sortedCycles.length; i++) {
        final c = sortedCycles[i];
        final cStart = normalizeDate(c.startDate);
        final cBleed = c.bleedingDurationDays ?? estimatedBleedingLen;
        if (i + 1 < sortedCycles.length) {
          final nextStart = normalizeDate(sortedCycles[i + 1].startDate);
          final len = math.max(15, nextStart.difference(cStart).inDays);
          windows.add(
            _ProjectedWindow(
              startDate: cStart,
              cycleLengthDays: len,
              bleedingDurationDays: cBleed,
              isRecordedCycle: true,
            ),
          );
        } else {
          windows.add(
            _ProjectedWindow(
              startDate: cStart,
              cycleLengthDays: estimatedCycleLen,
              bleedingDurationDays: cBleed,
              isRecordedCycle: true,
            ),
          );
          for (var step = 1; step <= 12; step++) {
            final futureStart =
                cStart.add(Duration(days: estimatedCycleLen * step));
            if (futureStart.isAfter(monthEnd)) break;
            windows.add(
              _ProjectedWindow(
                startDate: futureStart,
                cycleLengthDays: estimatedCycleLen,
                bleedingDurationDays: estimatedBleedingLen,
                isRecordedCycle: false,
              ),
            );
          }
        }
      }
    }

    final daysOut = <CalendarDayProjectionEntity>[];
    for (var dayNum = 1; dayNum <= numDays; dayNum++) {
      final curDate = DateTime.utc(year, month, dayNum);
      final log = logsByDate[curDate];
      final flow = log?.bleedingFlow ?? 'none';
      final isMenstrualBleeding =
          flow == 'light' || flow == 'medium' || flow == 'heavy';
      final hasSymptoms = log != null &&
          (log.pelvicPain != null ||
              log.dysmenorrhea != null ||
              log.fatigueLevel != null ||
              log.acneSeverity != null ||
              log.giSymptoms.isNotEmpty ||
              (log.notes != null && log.notes!.isNotEmpty) ||
              flow != 'none');

      int? dayInCycle;
      String? phase;
      var marker = CalendarDayMarker.none;
      var fertility = FertilityProbability.none;
      var dailySummary = 'Sin evento menstrual proyectado.';

      if (isNonMenstrualStage) {
        phase =
            lifeStage == LifeStage.seniorVitality ? null : 'hormonally_managed';
        dailySummary = status.phaseDescriptionEs;
      } else if (windows.isNotEmpty) {
        final matching = _findWindowForDate(curDate, windows);
        if (matching != null) {
          dayInCycle = curDate.difference(matching.startDate).inDays + 1;
          final cBleed = matching.bleedingDurationDays;
          final cLen = matching.cycleLengthDays;
          final ovulDay = math.max(cBleed + 2, cLen - 14);

          if (suppressed) {
            phase = 'hormonally_managed';
            if (recordedPeriodDates.contains(curDate) || isMenstrualBleeding) {
              marker = CalendarDayMarker.recordedPeriod;
              dailySummary = 'Día $dayInCycle: sangrado registrado.';
            } else if (!matching.isRecordedCycle && dayInCycle <= cBleed) {
              marker = CalendarDayMarker.predictedPeriod;
              dailySummary =
                  'Día $dayInCycle: sangrado por deprivación estimado.';
            } else if (flow == 'spotting') {
              marker = CalendarDayMarker.spotting;
              dailySummary =
                  'Día $dayInCycle: manchado intermenstrual registrado.';
            } else {
              dailySummary = 'Día $dayInCycle bajo gestión hormonal.';
            }
          } else {
            if (dayInCycle <= cBleed) {
              phase = 'menstrual';
            } else if (dayInCycle < ovulDay - 1) {
              phase = 'follicular';
            } else if (dayInCycle <= ovulDay + 1) {
              phase = 'ovulatory';
            } else {
              phase = 'luteal';
            }

            if (recordedPeriodDates.contains(curDate) || isMenstrualBleeding) {
              marker = CalendarDayMarker.recordedPeriod;
              fertility = FertilityProbability.low;
              dailySummary = 'Día $dayInCycle: menstruación registrada.';
            } else if (flow == 'spotting') {
              marker = CalendarDayMarker.spotting;
              fertility = (dayInCycle - ovulDay).abs() <= 4
                  ? FertilityProbability.medium
                  : FertilityProbability.low;
              dailySummary = 'Día $dayInCycle: manchado leve registrado.';
            } else if (!matching.isRecordedCycle && dayInCycle <= cBleed) {
              marker = CalendarDayMarker.predictedPeriod;
              fertility = FertilityProbability.low;
              dailySummary =
                  'Día $dayInCycle: inicio estimado de tu próximo periodo.';
            } else if (dayInCycle == ovulDay) {
              marker = CalendarDayMarker.predictedOvulation;
              fertility = FertilityProbability.high;
              dailySummary = 'Día $dayInCycle: día estimado de ovulación.';
            } else if (dayInCycle >= ovulDay - 5 && dayInCycle <= ovulDay + 1) {
              marker = CalendarDayMarker.fertileWindow;
              fertility = dayInCycle == ovulDay - 1
                  ? FertilityProbability.high
                  : FertilityProbability.medium;
              dailySummary = 'Día $dayInCycle: ventana fértil estimada.';
            } else {
              fertility = FertilityProbability.low;
              dailySummary = 'Día $dayInCycle del ciclo.';
            }
          }
        }
      }

      if (marker == CalendarDayMarker.none) {
        if (recordedPeriodDates.contains(curDate) || isMenstrualBleeding) {
          marker = CalendarDayMarker.recordedPeriod;
          dailySummary = 'Menstruación registrada.';
        } else if (flow == 'spotting') {
          marker = CalendarDayMarker.spotting;
          dailySummary = 'Manchado registrado.';
        }
      }

      daysOut.add(
        CalendarDayProjectionEntity(
          date: curDate,
          dayInCycle: dayInCycle,
          phase: phase,
          dayMarker: marker,
          fertilityProbability: fertility,
          hasLoggedSymptoms: hasSymptoms,
          bleedingFlow: flow,
          pelvicPain: log?.pelvicPain,
          dailySummaryEs: dailySummary,
          phaseEducationEs: _phaseEducation(phase, lifeStage),
        ),
      );
    }

    return CalendarMonthProjectionEntity(
      year: year,
      month: month,
      displayMode: displayMode,
      estimatedCycleLengthDays: estimatedCycleLen,
      estimatedBleedingDurationDays: estimatedBleedingLen,
      isHormonallyManaged: status.isHormonallyManaged,
      hasExtendedUncertainty: status.hasExtendedUncertainty,
      currentCycleDay: status.dayInCycle,
      currentPhase: isNonMenstrualStage ? null : status.currentPhase,
      predictedNextPeriod: status.predictedNextPeriod,
      ovulationDate: status.ovulationDate,
      fertileWindowStart: status.fertileWindowStart,
      fertileWindowEnd: status.fertileWindowEnd,
      days: daysOut,
    );
  }

  static _ProjectedWindow? _findWindowForDate(
    DateTime curDate,
    List<_ProjectedWindow> windows,
  ) {
    for (var i = 0; i < windows.length; i++) {
      final w = windows[i];
      if (curDate.isBefore(w.startDate)) continue;
      final nextStart = i + 1 < windows.length
          ? windows[i + 1].startDate
          : w.startDate.add(Duration(days: w.cycleLengthDays));
      if (!curDate.isBefore(w.startDate) && curDate.isBefore(nextStart)) {
        return w;
      }
    }
    return null;
  }

  static String _phaseEducation(String? phase, LifeStage stage) {
    if (stage == LifeStage.pregnancy) {
      return 'Seguimiento gestacional ACOG: monitorea movimientos fetales, '
          'tensión arterial y próximas citas prenatales.';
    }
    if (stage == LifeStage.seniorVitality) {
      return 'Calendario preventivo integral: enfocado en vitalidad ósea, '
          'salud cardiovascular y controles médicos periódicos.';
    }
    switch (phase) {
      case 'menstrual':
        return 'Fase menstrual: el endometrio se renueva de forma fisiológica. '
            'Prioriza descanso, hidratación tibia y aportes de hierro.';
      case 'follicular':
        return 'Fase folicular: los estrógenos aumentan progresivamente, '
            'favoreciendo tu energía física, enfoque y vitalidad.';
      case 'ovulatory':
        return 'Fase ovulatoria: pico hormonal de LH y mayor probabilidad fértil '
            'en torno a la liberación del óvulo.';
      case 'luteal':
        return 'Fase lútea: predomina la progesterona. Es habitual notar mayor '
            'necesidad de calma, hidratación y sueño reparador.';
      case 'hormonally_managed':
        return 'Ciclo modulado por tratamiento hormonal: las fluctuaciones '
            'ovulatorias naturales permanecen en reposo.';
      default:
        return 'Registra tus fechas o síntomas diarios para construir tu mapa '
            'biológico personalizado.';
    }
  }
}
