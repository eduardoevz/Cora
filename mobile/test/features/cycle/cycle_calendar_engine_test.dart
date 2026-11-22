import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/domain/services/cycle_calendar_engine.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';

void main() {
  group('CycleCalendarEngine clinical parity tests', () {
    const engine = CycleCalendarEngine();

    test(
        'calibrates 31-day regular cycle from 2 initial periods (no hardcoded 28)',
        () {
      final cycles = [
        MenstrualCycleEntity(
          id: 'c1',
          userId: 'u1',
          startDate: DateTime.utc(2026, 9, 10),
          endDate: DateTime.utc(2026, 10, 10),
          cycleLengthDays: 31,
          bleedingDurationDays: 5,
          isCurrent: false,
        ),
        MenstrualCycleEntity(
          id: 'c2',
          userId: 'u1',
          startDate: DateTime.utc(2026, 10, 11),
          bleedingDurationDays: 5,
          isCurrent: true,
        ),
      ];

      final status = engine.computeStatus(
        cycles: cycles,
        lifeStage: LifeStage.regularAdult,
        hormonalMethod: HormonalMethod.none,
        diagnosedConditions: const [DiagnosedCondition.none],
        cycleRegularity: CycleRegularity.regular,
        typicalCycleLengthDays: 31,
        typicalBleedingDurationDays: 5,
        referenceDate: DateTime.utc(2026, 10, 27),
      );

      expect(status.currentPhase, 'ovulatory');
      expect(status.dayInCycle, 17);
      expect(status.ovulationDate, DateTime.utc(2026, 10, 27));
      expect(status.fertileWindowStart, DateTime.utc(2026, 10, 22));
      expect(status.fertileWindowEnd, DateTime.utc(2026, 10, 28));
      expect(status.predictedNextPeriod, DateTime.utc(2026, 11, 11));
      expect(status.hasExtendedUncertainty, isFalse);

      final nov = engine.projectMonth(
        year: 2026,
        month: 11,
        cycles: cycles,
        symptomLogs: const [],
        lifeStage: LifeStage.regularAdult,
        hormonalMethod: HormonalMethod.none,
        diagnosedConditions: const [DiagnosedCondition.none],
        cycleRegularity: CycleRegularity.regular,
        typicalCycleLengthDays: 31,
        typicalBleedingDurationDays: 5,
        referenceDate: DateTime.utc(2026, 10, 27),
      );

      expect(nov.estimatedCycleLengthDays, 31);
      final day11 = nov.days.firstWhere((d) => d.date.day == 11);
      expect(day11.dayMarker, CalendarDayMarker.predictedPeriod);
    });

    test('supports 26-day and 33-day baseline cycles accurately', () {
      for (final len in [26, 33]) {
        final cycleStart = DateTime.utc(2026, 10, 1);
        final cycles = [
          MenstrualCycleEntity(
            id: 'c-$len',
            userId: 'u1',
            startDate: cycleStart,
            bleedingDurationDays: 4,
            isCurrent: true,
          ),
        ];

        final proj = engine.projectMonth(
          year: 2026,
          month: 10,
          cycles: cycles,
          symptomLogs: const [],
          lifeStage: LifeStage.regularAdult,
          hormonalMethod: HormonalMethod.none,
          diagnosedConditions: const [DiagnosedCondition.none],
          cycleRegularity: CycleRegularity.regular,
          typicalCycleLengthDays: len,
          typicalBleedingDurationDays: 4,
          referenceDate: DateTime.utc(2026, 10, 10),
        );

        expect(proj.estimatedCycleLengthDays, len);
        expect(proj.predictedNextPeriod, cycleStart.add(Duration(days: len)));
        expect(
          proj.ovulationDate,
          cycleStart.add(Duration(days: (len - 14) - 1)),
        );
      }
    });

    test('sets extended uncertainty for irregular, adolescence, and PCOS', () {
      final cycles = [
        MenstrualCycleEntity(
          id: 'c-u',
          userId: 'u1',
          startDate: DateTime.utc(2026, 10, 1),
          bleedingDurationDays: 5,
          isCurrent: true,
        ),
      ];

      final irregular = engine.projectMonth(
        year: 2026,
        month: 10,
        cycles: cycles,
        symptomLogs: const [],
        lifeStage: LifeStage.regularAdult,
        hormonalMethod: HormonalMethod.none,
        diagnosedConditions: const [DiagnosedCondition.none],
        cycleRegularity: CycleRegularity.irregular,
        typicalCycleLengthDays: 35,
        referenceDate: DateTime.utc(2026, 10, 10),
      );
      expect(irregular.hasExtendedUncertainty, isTrue);

      final teen = engine.projectMonth(
        year: 2026,
        month: 10,
        cycles: cycles,
        symptomLogs: const [],
        lifeStage: LifeStage.adolescence,
        hormonalMethod: HormonalMethod.none,
        diagnosedConditions: const [DiagnosedCondition.none],
        cycleRegularity: CycleRegularity.regular,
        referenceDate: DateTime.utc(2026, 10, 10),
      );
      expect(teen.displayMode, CalendarDisplayMode.adolescenceFlexible);
      expect(teen.hasExtendedUncertainty, isTrue);

      final pcos = engine.projectMonth(
        year: 2026,
        month: 10,
        cycles: cycles,
        symptomLogs: const [],
        lifeStage: LifeStage.regularAdult,
        hormonalMethod: HormonalMethod.none,
        diagnosedConditions: const [DiagnosedCondition.pcos],
        cycleRegularity: CycleRegularity.regular,
        referenceDate: DateTime.utc(2026, 10, 10),
      );
      expect(pcos.hasExtendedUncertainty, isTrue);
    });

    test('suppresses ovulation under hormonal contraception', () {
      final cycles = [
        MenstrualCycleEntity(
          id: 'c-h',
          userId: 'u1',
          startDate: DateTime.utc(2026, 10, 1),
          bleedingDurationDays: 4,
          isCurrent: true,
        ),
      ];

      final proj = engine.projectMonth(
        year: 2026,
        month: 10,
        cycles: cycles,
        symptomLogs: const [],
        lifeStage: LifeStage.regularAdult,
        hormonalMethod: HormonalMethod.combinedOralPill,
        diagnosedConditions: const [DiagnosedCondition.none],
        cycleRegularity: CycleRegularity.regular,
        typicalCycleLengthDays: 28,
        referenceDate: DateTime.utc(2026, 10, 14),
      );

      expect(proj.displayMode, CalendarDisplayMode.hormonallyManaged);
      expect(proj.isHormonallyManaged, isTrue);
      expect(proj.ovulationDate, isNull);
      expect(
        proj.days
            .any((d) => d.dayMarker == CalendarDayMarker.predictedOvulation),
        isFalse,
      );
    });

    test(
        'adapts across pregnancy, postpartum, perimenopause, and senior stages',
        () {
      final preg = engine.projectMonth(
        year: 2026,
        month: 10,
        cycles: const [],
        symptomLogs: const [],
        lifeStage: LifeStage.pregnancy,
        hormonalMethod: HormonalMethod.none,
        cycleRegularity: CycleRegularity.notApplicable,
        referenceDate: DateTime.utc(2026, 10, 10),
      );
      expect(preg.displayMode, CalendarDisplayMode.pregnancyGestational);
      expect(preg.ovulationDate, isNull);
      expect(preg.currentPhase, isNull);

      final pp = engine.projectMonth(
        year: 2026,
        month: 10,
        cycles: const [],
        symptomLogs: const [],
        lifeStage: LifeStage.postpartum,
        hormonalMethod: HormonalMethod.none,
        cycleRegularity: CycleRegularity.notApplicable,
        referenceDate: DateTime.utc(2026, 10, 10),
      );
      expect(pp.displayMode, CalendarDisplayMode.postpartumRecovery);

      final peri = engine.projectMonth(
        year: 2026,
        month: 10,
        cycles: [
          MenstrualCycleEntity(
            id: 'c-p',
            userId: 'u1',
            startDate: DateTime.utc(2026, 10, 1),
            bleedingDurationDays: 5,
            isCurrent: true,
          ),
        ],
        symptomLogs: const [],
        lifeStage: LifeStage.perimenopause,
        hormonalMethod: HormonalMethod.none,
        cycleRegularity: CycleRegularity.irregular,
        referenceDate: DateTime.utc(2026, 10, 10),
      );
      expect(peri.displayMode, CalendarDisplayMode.perimenopauseStraw10);
      expect(peri.hasExtendedUncertainty, isTrue);

      final senior = engine.projectMonth(
        year: 2026,
        month: 10,
        cycles: const [],
        symptomLogs: const [],
        lifeStage: LifeStage.seniorVitality,
        hormonalMethod: HormonalMethod.none,
        cycleRegularity: CycleRegularity.notApplicable,
        referenceDate: DateTime.utc(2026, 10, 10),
      );
      expect(senior.displayMode, CalendarDisplayMode.seniorPreventive);
      expect(senior.ovulationDate, isNull);
    });
  });
}
