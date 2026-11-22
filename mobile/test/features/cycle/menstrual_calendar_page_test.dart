import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/cycle/data/cycle_repository_impl.dart';
import 'package:mobile/features/cycle/presentation/pages/cycle_monitor_page.dart';
import 'package:mobile/features/cycle/presentation/pages/menstrual_calendar_page.dart';
import 'package:mobile/features/cycle/presentation/providers/cycle_providers.dart';
import 'package:mobile/features/cycle/presentation/providers/menstrual_calendar_providers.dart';
import 'package:mobile/features/cycle/presentation/widgets/cycle_wheel_painter.dart';
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
      id: 'user-page-1',
      firebaseUid: 'uid-page-1',
      firstName: 'Lucía',
      lastName: 'Morales',
      currentLifeStage: stage,
      onboardingCompleted: true,
      onboardingContext: OnboardingContextEntity(
        birthYear: 1994,
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

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncCoordinator = SyncCoordinator(db);
    cycleRepo = CycleRepositoryImpl(db, syncCoordinator);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
      'displays 2 seeded periods, predicted next period, fertile window, ovulation, month navigation and daily detail panel',
      (tester) async {
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncCoordinatorProvider.overrideWithValue(syncCoordinator),
          cycleRepositoryProvider.overrideWithValue(cycleRepo),
          activeUserProfileProvider.overrideWith((ref) => profile),
          calendarReferenceTodayProvider.overrideWith((ref) => refToday),
        ],
        child: MaterialApp(
          theme: CoraTheme.standard(),
          home: const MenstrualCalendarPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and context pills
    expect(find.text('Octubre 2026'), findsOneWidget);
    expect(find.text('Ciclo de 31 días'), findsOneWidget);
    expect(find.text('Día 17 del ciclo actual'), findsOneWidget);

    // Verify dual-encoded markers in October 2026:
    // Oct 11..15 recorded period, Oct 22..28 fertile window, Oct 27 predicted ovulation
    expect(find.byKey(const Key('marker_recorded_2026_10_11')), findsOneWidget);
    expect(find.byKey(const Key('marker_fertile_2026_10_23')), findsOneWidget);
    expect(
        find.byKey(const Key('marker_ovulation_2026_10_27')), findsOneWidget);

    // Detail panel initially shows Oct 27 (ovulation day, day 17)
    expect(find.text('DETALLE DEL REGISTRO'), findsOneWidget);
    expect(find.text('27 de Octubre, 2026'), findsOneWidget);
    expect(find.text('Fase Ovulatoria'), findsAtLeastNWidgets(1));
    expect(find.text('Probabilidad fértil: Alta'), findsOneWidget);

    // Tap Oct 12 (recorded menstrual day) and verify detail panel updates
    final oct12Cell = find.byKey(const Key('calendar_day_2026_10_12'));
    await tester.ensureVisible(oct12Cell);
    await tester.pumpAndSettle();
    await tester.tap(oct12Cell);
    await tester.pumpAndSettle();

    expect(find.text('12 de Octubre, 2026'), findsOneWidget);
    expect(find.text('Día 2 del ciclo'), findsOneWidget);
    expect(find.text('Fase Menstrual'), findsAtLeastNWidgets(1));

    // Navigate to November 2026 and verify predicted next period on Nov 11
    final nextMonthBtn = find.byKey(const Key('calendar_next_month_button'));
    await tester.ensureVisible(nextMonthBtn);
    await tester.pumpAndSettle();
    await tester.tap(nextMonthBtn);
    await tester.pumpAndSettle();

    expect(find.text('Noviembre 2026'), findsOneWidget);
    expect(
        find.byKey(const Key('marker_predicted_2026_11_11')), findsOneWidget);

    // Navigate back twice to September 2026 and verify first seeded period (Sep 10..14)
    final prevMonthBtn = find.byKey(const Key('calendar_prev_month_button'));
    await tester.tap(prevMonthBtn);
    await tester.pumpAndSettle();
    await tester.tap(prevMonthBtn);
    await tester.pumpAndSettle();

    expect(find.text('Septiembre 2026'), findsOneWidget);
    expect(find.byKey(const Key('marker_recorded_2026_9_10')), findsOneWidget);
  });

  testWidgets(
      'logs bleeding and symptoms on any calendar date and recalculates predictions live',
      (tester) async {
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncCoordinatorProvider.overrideWithValue(syncCoordinator),
          cycleRepositoryProvider.overrideWithValue(cycleRepo),
          activeUserProfileProvider.overrideWith((ref) => profile),
          calendarReferenceTodayProvider.overrideWith((ref) => refToday),
        ],
        child: MaterialApp(
          theme: CoraTheme.standard(),
          home: const MenstrualCalendarPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Oct 20 and open the daily log bottom sheet
    final oct20Cell = find.byKey(const Key('calendar_day_2026_10_20'));
    await tester.ensureVisible(oct20Cell);
    await tester.pumpAndSettle();
    await tester.tap(oct20Cell);
    await tester.pumpAndSettle();

    final openLogBtn = find.byKey(const Key('calendar_open_log_sheet_button'));
    await tester.ensureVisible(openLogBtn);
    await tester.pumpAndSettle();
    await tester.tap(openLogBtn);
    await tester.pumpAndSettle();

    // Select spotting, increase pelvic pain twice, select GI symptom 'Hinchazón', enter notes
    await tester.tap(find.byKey(const Key('log_flow_spotting')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('log_pain_plus')));
    await tester.tap(find.byKey(const Key('log_pain_plus')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('log_gi_Hinchazón')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('log_notes_input')),
      'Manchado leve a mitad de ciclo',
    );

    final saveBtn = find.byKey(const Key('log_save_button'));
    await tester.ensureVisible(saveBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Detail panel and calendar cell immediately reflect the logged biomarkers
    expect(
        find.byKey(const Key('marker_symptom_dot_2026_10_20')), findsOneWidget);
    expect(find.text('Sangrado: Manchado'), findsOneWidget);
    expect(find.text('Dolor pélvico: 2/10'), findsOneWidget);
    expect(find.text('Hinchazón'), findsOneWidget);
    expect(find.text('Manchado leve a mitad de ciclo'), findsOneWidget);
  });

  testWidgets('adapts UI and clinical context across all 7 biological stages',
      (tester) async {
    final refToday = DateTime.utc(2026, 10, 27);
    final stageCases = <(LifeStage, String)>[
      (
        LifeStage.adolescence,
        'Ciclo en Adolescencia (Tolerancia FIGO 21–45 días)'
      ),
      (LifeStage.regularAdult, 'Seguimiento Cíclico de 4 Fases'),
      (LifeStage.conceptionSearch, 'Ventana Fértil y Concepción Sintotérmica'),
      (
        LifeStage.pregnancy,
        'Seguimiento Gestacional ACOG (Sin predicción menstrual)'
      ),
      (
        LifeStage.postpartum,
        'Recuperación Posparto, Lactancia y Bienestar EPDS'
      ),
      (
        LifeStage.perimenopause,
        'Transición Hormonal STRAW+10 (Variabilidad >= 7 días)'
      ),
      (
        LifeStage.seniorVitality,
        'Calendario Preventivo de Plenitud (Alta Legibilidad WCAG AAA)'
      ),
    ];

    for (final testCase in stageCases) {
      final stage = testCase.$1;
      final expectedBannerTitle = testCase.$2;

      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey('scope_${stage.value}'),
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            syncCoordinatorProvider.overrideWithValue(syncCoordinator),
            cycleRepositoryProvider.overrideWithValue(cycleRepo),
            activeUserProfileProvider.overrideWith(
              (ref) => buildProfile(stage: stage),
            ),
            calendarReferenceTodayProvider.overrideWith((ref) => refToday),
          ],
          child: MaterialApp(
            theme: CoraTheme.standard(),
            home: const MenstrualCalendarPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('calendar_stage_banner_${stage.value}')),
        findsOneWidget,
      );
      expect(find.text(expectedBannerTitle), findsOneWidget);
    }
  });

  testWidgets(
      'CycleMonitorPage uses dynamic cycle length in CycleWheelPainter and navigates to MenstrualCalendarPage',
      (tester) async {
    final profile = buildProfile(typicalCycleLen: 33);
    final refToday = DateTime.utc(2026, 10, 27);

    await cycleRepo.seedInitialPeriods(
      userId: profile.id,
      periods: [
        InitialPeriodRangeEntity(
          startDate: DateTime.utc(2026, 9, 8),
          endDate: DateTime.utc(2026, 9, 12),
        ),
        InitialPeriodRangeEntity(
          startDate: DateTime.utc(2026, 10, 11),
          endDate: DateTime.utc(2026, 10, 15),
        ),
      ],
      typicalCycleLengthDays: 33,
      syncRemote: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncCoordinatorProvider.overrideWithValue(syncCoordinator),
          cycleRepositoryProvider.overrideWithValue(cycleRepo),
          activeUserProfileProvider.overrideWith((ref) => profile),
          calendarReferenceTodayProvider.overrideWith((ref) => refToday),
        ],
        child: MaterialApp(
          theme: CoraTheme.standard(),
          home: const CycleMonitorPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final customPaint = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .firstWhere((w) => w.painter is CycleWheelPainter);
    final wheelPainter = customPaint.painter! as CycleWheelPainter;
    expect(wheelPainter.totalDays, 33);

    await tester.tap(find.byKey(const Key('open_menstrual_calendar_button')));
    await tester.pumpAndSettle();

    expect(find.byType(MenstrualCalendarPage), findsOneWidget);
  });

  testWidgets(
      'passes WCAG TextScaler.linear(2.0) and High Legibility theme without RenderFlex overflow',
      (tester) async {
    final prevHandler = FlutterError.onError;
    final capturedErrors = <FlutterErrorDetails>[];
    FlutterError.onError = (details) {
      capturedErrors.add(details);
    };
    addTearDown(() => FlutterError.onError = prevHandler);

    final profile = buildProfile(stage: LifeStage.seniorVitality);
    final refToday = DateTime.utc(2026, 10, 27);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncCoordinatorProvider.overrideWithValue(syncCoordinator),
          cycleRepositoryProvider.overrideWithValue(cycleRepo),
          activeUserProfileProvider.overrideWith((ref) => profile),
          calendarReferenceTodayProvider.overrideWith((ref) => refToday),
        ],
        child: MaterialApp(
          theme: CoraTheme.highLegibility(),
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(360, 780),
              textScaler: TextScaler.linear(2.0),
            ),
            child: MenstrualCalendarPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Calendario Preventivo de Plenitud (Alta Legibilidad WCAG AAA)'),
      findsOneWidget,
    );
    expect(capturedErrors, isEmpty);
  });
}
