import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/cycle/data/cycle_repository_impl.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/presentation/providers/cycle_providers.dart';
import 'package:mobile/features/cycle/presentation/providers/menstrual_calendar_providers.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

void main() {
  late AppDatabase db;
  late SyncCoordinator syncCoordinator;
  late CycleRepositoryImpl cycleRepo;

  UserProfileEntity buildProfile({
    LifeStage stage = LifeStage.regularAdult,
    HormonalMethod hormonalMethod = HormonalMethod.none,
    List<DiagnosedCondition> conditions = const [DiagnosedCondition.none],
    CycleRegularity regularity = CycleRegularity.regular,
    int? typicalCycleLen = 31,
    int? typicalBleedLen = 5,
  }) {
    return UserProfileEntity(
      id: 'user-cal-1',
      firebaseUid: 'uid-cal-1',
      firstName: 'Valeria',
      lastName: 'Ríos',
      currentLifeStage: stage,
      onboardingCompleted: true,
      onboardingContext: OnboardingContextEntity(
        birthYear: 1995,
        primaryIntents: const [PrimaryIntent.cycleAndSymptoms],
        hormonalMethod: hormonalMethod,
        diagnosedConditions: conditions,
        cycleRegularity: regularity,
        typicalCycleLengthDays: typicalCycleLen,
        typicalBleedingDurationDays: typicalBleedLen,
        clinicalContextCompleted: true,
      ),
      enabledModules: const ['cycle_tracking'],
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 1),
    );
  }

  ProviderContainer createContainer({
    required UserProfileEntity profile,
    required DateTime referenceToday,
  }) {
    return ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        syncCoordinatorProvider.overrideWithValue(syncCoordinator),
        cycleRepositoryProvider.overrideWithValue(cycleRepo),
        activeUserProfileProvider.overrideWith((ref) => profile),
        calendarReferenceTodayProvider.overrideWith((ref) => referenceToday),
      ],
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncCoordinator = SyncCoordinator(db);
    cycleRepo = CycleRepositoryImpl(db, syncCoordinator);
  });

  tearDown(() async {
    await db.close();
  });

  test(
      'projects current month from 2 seeded initial periods and exposes selected day details',
      () async {
    final profile = buildProfile();
    final refToday = DateTime.utc(2026, 10, 27);

    await cycleRepo.seedInitialPeriods(
      userId: profile.id,
      periods: [
        InitialPeriodRangeEntity(
          startDate: DateTime.utc(2026, 9, 10),
          endDate: DateTime.utc(2026, 9, 14),
        ),
        InitialPeriodRangeEntity(
          startDate: DateTime.utc(2026, 10, 11),
          endDate: DateTime.utc(2026, 10, 15),
        ),
      ],
      cycleRegularity: CycleRegularity.regular,
      typicalCycleLengthDays: 31,
      typicalBleedingDurationDays: 5,
      syncRemote: false,
    );

    final container = createContainer(
      profile: profile,
      referenceToday: refToday,
    );
    addTearDown(container.dispose);

    final monthProjection =
        await container.read(activeCalendarMonthProjectionProvider.future);

    expect(monthProjection.year, 2026);
    expect(monthProjection.month, 10);
    expect(monthProjection.estimatedCycleLengthDays, 31);
    expect(monthProjection.currentCycleDay, 17);
    expect(monthProjection.ovulationDate, DateTime.utc(2026, 10, 27));
    expect(monthProjection.predictedNextPeriod, DateTime.utc(2026, 11, 11));

    final selectedDay =
        container.read(selectedCalendarDayProjectionProvider).valueOrNull;
    expect(selectedDay, isNotNull);
    expect(selectedDay!.date, DateTime.utc(2026, 10, 27));
    expect(selectedDay.dayInCycle, 17);
    expect(selectedDay.dayMarker, CalendarDayMarker.predictedOvulation);
    expect(selectedDay.fertilityProbability, FertilityProbability.high);
  });

  test('handles month navigation and day selection reactively', () async {
    final profile = buildProfile();
    final refToday = DateTime.utc(2026, 10, 27);

    await cycleRepo.seedInitialPeriods(
      userId: profile.id,
      periods: [
        InitialPeriodRangeEntity(
          startDate: DateTime.utc(2026, 9, 10),
          endDate: DateTime.utc(2026, 9, 14),
        ),
        InitialPeriodRangeEntity(
          startDate: DateTime.utc(2026, 10, 11),
          endDate: DateTime.utc(2026, 10, 15),
        ),
      ],
      syncRemote: false,
    );

    final container = createContainer(
      profile: profile,
      referenceToday: refToday,
    );
    addTearDown(container.dispose);

    await container.read(activeCalendarMonthProjectionProvider.future);
    final controller = container.read(menstrualCalendarControllerProvider);

    // Select day 12 in October (recorded period)
    controller.selectDate(DateTime.utc(2026, 10, 12));
    final oct12 =
        container.read(selectedCalendarDayProjectionProvider).valueOrNull;
    expect(oct12, isNotNull);
    expect(oct12!.dayInCycle, 2);
    expect(oct12.dayMarker, CalendarDayMarker.recordedPeriod);

    // Navigate to next month (November 2026)
    controller.nextMonth();
    expect(
      container.read(selectedCalendarMonthProvider),
      (year: 2026, month: 11),
    );
    final novProjection =
        await container.read(activeCalendarMonthProjectionProvider.future);
    expect(novProjection.year, 2026);
    expect(novProjection.month, 11);

    controller.selectDate(DateTime.utc(2026, 11, 11));
    final nov11 =
        container.read(selectedCalendarDayProjectionProvider).valueOrNull;
    expect(nov11, isNotNull);
    expect(nov11!.dayMarker, CalendarDayMarker.predictedPeriod);

    // Navigate to previous month twice -> September 2026
    controller.previousMonth();
    controller.previousMonth();
    expect(
      container.read(selectedCalendarMonthProvider),
      (year: 2026, month: 9),
    );
    final sepProjection =
        await container.read(activeCalendarMonthProjectionProvider.future);
    final sep10 = sepProjection.days.firstWhere((d) => d.date.day == 10);
    expect(sep10.dayMarker, CalendarDayMarker.recordedPeriod);

    // Jump back to today
    controller.goToToday();
    expect(
      container.read(selectedCalendarMonthProvider),
      (year: 2026, month: 10),
    );
    expect(container.read(selectedCalendarDateProvider), refToday);
  });

  test(
      'recalculates predictions and symptom state immediately after logging bleeding or symptoms on any date',
      () async {
    final profile = buildProfile();
    final refToday = DateTime.utc(2026, 10, 27);

    await cycleRepo.seedInitialPeriods(
      userId: profile.id,
      periods: [
        InitialPeriodRangeEntity(
          startDate: DateTime.utc(2026, 9, 10),
          endDate: DateTime.utc(2026, 9, 14),
        ),
        InitialPeriodRangeEntity(
          startDate: DateTime.utc(2026, 10, 11),
          endDate: DateTime.utc(2026, 10, 15),
        ),
      ],
      syncRemote: false,
    );

    final container = createContainer(
      profile: profile,
      referenceToday: refToday,
    );
    addTearDown(container.dispose);

    final controller = container.read(menstrualCalendarControllerProvider);

    // 1. Log symptoms on Oct 20
    final oct20 = DateTime.utc(2026, 10, 20);
    await controller.saveDayLog(
      date: oct20,
      bleedingFlow: 'none',
      pelvicPain: 6,
      fatigueLevel: 5,
      giSymptoms: const ['Hinchazón'],
      notes: 'Sensación de distensión leve',
    );

    await container.read(activeCalendarMonthProjectionProvider.future);
    await container.read(calendarSymptomLogsByDateProvider.future);

    controller.selectDate(oct20);
    final oct20Proj =
        container.read(selectedCalendarDayProjectionProvider).valueOrNull;
    expect(oct20Proj, isNotNull);
    expect(oct20Proj!.hasLoggedSymptoms, isTrue);
    expect(oct20Proj.pelvicPain, 6);

    final oct20Log = container.read(selectedDaySymptomLogProvider);
    expect(oct20Log, isNotNull);
    expect(oct20Log!.fatigueLevel, 5);
    expect(oct20Log.giSymptoms, contains('Hinchazón'));
    expect(oct20Log.notes, 'Sensación de distensión leve');

    // 2. Navigate to November 2026 and log start of a new period on Nov 9 (2 days early)
    controller.nextMonth();
    final nov9 = DateTime.utc(2026, 11, 9);
    await controller.saveDayLog(
      date: nov9,
      bleedingFlow: 'heavy',
      pelvicPain: 4,
    );

    final novProj =
        await container.read(activeCalendarMonthProjectionProvider.future);
    controller.selectDate(nov9);
    final nov9Proj =
        container.read(selectedCalendarDayProjectionProvider).valueOrNull;
    expect(nov9Proj, isNotNull);
    expect(nov9Proj!.dayMarker, CalendarDayMarker.recordedPeriod);
    expect(nov9Proj.dayInCycle, 1);
    expect(nov9Proj.bleedingFlow, 'heavy');

    // Next predicted period is now anchored from Nov 9 instead of Oct 11
    expect(novProj.predictedNextPeriod!.isAfter(DateTime.utc(2026, 12, 1)),
        isTrue);

    // Verify SyncOutbox recorded the offline mutations
    final outboxRows = await db.select(db.syncOutboxEntries).get();
    expect(
      outboxRows.where((r) => r.entityType == 'cycle_symptoms').length,
      greaterThanOrEqualTo(2),
    );
  });

  test('adapts calendar projection mode across all 7 biological life stages',
      () async {
    final refToday = DateTime.utc(2026, 10, 27);
    final container = createContainer(
      profile: buildProfile(stage: LifeStage.adolescence),
      referenceToday: refToday,
    );
    addTearDown(container.dispose);

    final expectations = <(LifeStage, CalendarDisplayMode)>[
      (LifeStage.adolescence, CalendarDisplayMode.adolescenceFlexible),
      (LifeStage.regularAdult, CalendarDisplayMode.standardCycle),
      (LifeStage.conceptionSearch, CalendarDisplayMode.conceptionFertility),
      (LifeStage.pregnancy, CalendarDisplayMode.pregnancyGestational),
      (LifeStage.postpartum, CalendarDisplayMode.postpartumRecovery),
      (LifeStage.perimenopause, CalendarDisplayMode.perimenopauseStraw10),
      (LifeStage.seniorVitality, CalendarDisplayMode.seniorPreventive),
    ];

    for (final pair in expectations) {
      container.read(activeUserProfileProvider.notifier).state =
          buildProfile(stage: pair.$1);
      final proj =
          await container.read(activeCalendarMonthProjectionProvider.future);
      expect(proj.displayMode, pair.$2);
    }
  });
}
