import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/cycle/data/cycle_repository_impl.dart';
import 'package:mobile/features/cycle/presentation/pages/menstrual_calendar_page.dart';
import 'package:mobile/features/cycle/presentation/providers/cycle_providers.dart';
import 'package:mobile/features/cycle/presentation/providers/menstrual_calendar_providers.dart';
import 'package:mobile/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart';
import 'package:mobile/features/dashboard/presentation/widgets/cora_navigation_drawer.dart';
import 'package:mobile/features/dashboard/presentation/widgets/home_cycle_hero_card.dart';
import 'package:mobile/features/dashboard/presentation/widgets/home_phase_education_card.dart';
import 'package:mobile/features/dashboard/presentation/widgets/home_week_calendar_strip.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/wellness/presentation/pages/wellness_tracker_page.dart';

void main() {
  late AppDatabase db;
  late SyncCoordinator syncCoordinator;
  late CycleRepositoryImpl cycleRepo;

  UserProfileEntity buildProfile({
    String firstName = 'Camila',
    LifeStage stage = LifeStage.regularAdult,
    int? typicalCycleLen = 31,
  }) {
    return UserProfileEntity(
      id: 'home-user-1',
      firebaseUid: 'uid-home-1',
      firstName: firstName,
      lastName: 'Torres',
      currentLifeStage: stage,
      onboardingCompleted: true,
      onboardingContext: OnboardingContextEntity(
        birthYear: 1995,
        primaryIntents: const [PrimaryIntent.cycleAndSymptoms],
        cycleRegularity: CycleRegularity.regular,
        typicalCycleLengthDays: typicalCycleLen,
        typicalBleedingDurationDays: 5,
        clinicalContextCompleted: true,
      ),
      enabledModules: const ['cycle_tracking', 'wellness'],
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
      'renders clean Home v2 with Hero cycle card, week strip, phase education card and navigates to MenstrualCalendarPage',
      (tester) async {
    final profile = buildProfile(firstName: 'Camila');
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
      typicalCycleLengthDays: 31,
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
          home: const DynamicHomeDashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Clean Home structure: Hero + Week Strip + Phase Education Card
    expect(find.text('Hola, Camila'), findsOneWidget);
    expect(find.byType(HomeCycleHeroCard), findsOneWidget);
    expect(find.byType(HomeWeekCalendarStrip), findsOneWidget);
    expect(find.byType(HomePhaseEducationCard), findsOneWidget);
    expect(find.text('Día 17'), findsOneWidget);
    expect(find.text('de 31 días'), findsOneWidget);
    expect(find.text('Acerca de tu periodo y fase actual'), findsOneWidget);

    // 2. Tap a day on the weekly calendar strip -> navigates to MenstrualCalendarPage
    final weekDayCell = find.byKey(const Key('home_week_day_2026_10_27'));
    await tester.ensureVisible(weekDayCell);
    await tester.pumpAndSettle();
    await tester.tap(weekDayCell);
    await tester.pumpAndSettle();

    expect(find.byType(MenstrualCalendarPage), findsOneWidget);
  });

  testWidgets(
      'opens CoraNavigationDrawer and navigates cleanly to categorized modules',
      (tester) async {
    final profile = buildProfile(firstName: 'Valeria');
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
          theme: CoraTheme.standard(),
          home: const DynamicHomeDashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Drawer via hamburger menu button
    await tester.tap(find.byKey(const Key('open_navigation_drawer_button')));
    await tester.pumpAndSettle();

    expect(find.byType(CoraNavigationDrawer), findsOneWidget);
    expect(find.text('Valeria Torres'), findsOneWidget);
    expect(find.text('MI SALUD DIARIA'), findsOneWidget);
    expect(find.text('EXPEDIENTE E INTELIGENCIA CLÍNICA'), findsOneWidget);
    expect(find.text('PERSONALIZACIÓN Y PRIVACIDAD'), findsOneWidget);

    // Tap Bienestar Diario in Drawer
    final wellnessItem = find.byKey(const Key('drawer_item_wellness'));
    await tester.ensureVisible(wellnessItem);
    await tester.pumpAndSettle();
    await tester.tap(wellnessItem);
    await tester.pumpAndSettle();

    expect(find.byType(WellnessTrackerPage), findsOneWidget);
  });

  testWidgets(
      'Dynamic Home Dashboard adapts Hero card in pregnancy and senior vitality stages without overflow at 2.0x TextScaler',
      (tester) async {
    final pregnancyProfile = buildProfile(
      firstName: 'Camila',
      stage: LifeStage.pregnancy,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncCoordinatorProvider.overrideWithValue(syncCoordinator),
          cycleRepositoryProvider.overrideWithValue(cycleRepo),
          activeUserProfileProvider.overrideWith((ref) => pregnancyProfile),
        ],
        child: MaterialApp(
          theme: CoraTheme.standard(),
          home: const DynamicHomeDashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hola, Camila'), findsOneWidget);
    expect(find.text('Embarazo Actual'), findsOneWidget);
    expect(
        find.byKey(const Key('dashboard_pregnancy_hub_card')), findsOneWidget);

    final seniorProfile = buildProfile(
      firstName: 'Elena',
      stage: LifeStage.seniorVitality,
    );

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('senior_scope'),
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncCoordinatorProvider.overrideWithValue(syncCoordinator),
          cycleRepositoryProvider.overrideWithValue(cycleRepo),
          activeUserProfileProvider.overrideWith((ref) => seniorProfile),
        ],
        child: MaterialApp(
          theme: CoraTheme.highLegibility(),
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(360, 780),
              textScaler: TextScaler.linear(2.0),
            ),
            child: DynamicHomeDashboardPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hola, Elena'), findsOneWidget);
    expect(find.text('Plenitud / Adulta Mayor'), findsOneWidget);
    expect(find.byKey(const Key('dashboard_senior_vitality_card')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
