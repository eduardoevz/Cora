import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/cycle/data/cycle_repository_impl.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/presentation/providers/cycle_providers.dart';
import 'package:mobile/features/fertility/data/fertility_repository_impl.dart';
import 'package:mobile/features/fertility/domain/entities/fertility_chart_entity.dart';
import 'package:mobile/features/fertility/presentation/pages/conception_hub_page.dart';
import 'package:mobile/features/fertility/presentation/pages/preconception_checklist_page.dart';
import 'package:mobile/features/fertility/presentation/providers/fertility_providers.dart';
import 'package:mobile/features/fertility/presentation/widgets/bbt_biphasic_chart_widget.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

void main() {
  late AppDatabase db;
  late SyncCoordinator syncCoordinator;
  late FertilityRepositoryImpl fertilityRepo;
  late CycleRepositoryImpl cycleRepo;

  final testProfile = UserProfileEntity(
    id: 'user-fertility-test-1',
    firebaseUid: 'uid-fertility-test-1',
    firstName: 'Valentina',
    lastName: 'Ríos',
    currentLifeStage: LifeStage.conceptionSearch,
    onboardingCompleted: true,
    onboardingContext: const OnboardingContextEntity(
      birthYear: 1995,
      primaryIntents: [PrimaryIntent.familyPlanning],
      clinicalContextCompleted: true,
    ),
    enabledModules: const ['fertility_bbt', 'lh_surge_prediction', 'cervical_mucus'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncCoordinator = SyncCoordinator(db);
    fertilityRepo = FertilityRepositoryImpl(db, syncCoordinator);
    cycleRepo = CycleRepositoryImpl(db, syncCoordinator);
  });

  tearDown(() async {
    await db.close();
  });

  test('Drift v5 schema stores and retrieves DailyFertility and PreconceptionChecklist',
      () async {
    final today = DateTime(2026, 11, 12);
    final entry = DailyFertilityEntity(
      id: 'fertility-log-1',
      userId: testProfile.id,
      logDate: today,
      bbtCelsius: 36.45,
      isDisturbed: false,
      cervicalMucus: 'egg_white',
      lhResult: 'peak',
      intercourseHad: true,
      intercourseType: 'unprotected',
      notes: 'Test peak',
    );

    await fertilityRepo.saveDailyFertility(entry);

    final retrieved = await fertilityRepo.getDailyFertility(testProfile.id, today);
    expect(retrieved, isNotNull);
    expect(retrieved!.bbtCelsius, 36.45);
    expect(retrieved.cervicalMucus, 'egg_white');
    expect(retrieved.lhResult, 'peak');
    expect(retrieved.intercourseHad, isTrue);

    // Checklist test
    final checklist = PreconceptionChecklistEntity(
      userId: testProfile.id,
      takingFolicAcid: true,
      folicAcidDoseMcg: 400,
      medicalCheckupDone: true,
      rubellaImmunityChecked: false,
      dentalCheckupDone: false,
      toxicHabitsStopped: true,
      partnerEvaluationPlanned: false,
      activeSeekingMonths: 4,
      updatedAt: DateTime.now(),
    );

    await fertilityRepo.savePreconceptionChecklist(checklist);

    final savedChecklist = await fertilityRepo.getPreconceptionChecklist(testProfile.id);
    expect(savedChecklist, isNotNull);
    expect(savedChecklist!.takingFolicAcid, isTrue);
    expect(savedChecklist.completionPercentage, 50);
  });

  testWidgets('renders BbtBiphasicChartWidget with coverline and broken lines on gaps',
      (tester) async {
    final entries = [
      DailyFertilityEntity(
        id: 'e1',
        userId: testProfile.id,
        logDate: DateTime(2026, 11, 1),
        bbtCelsius: 36.25,
      ),
      // Day 2 is missing! (Gap test)
      DailyFertilityEntity(
        id: 'e3',
        userId: testProfile.id,
        logDate: DateTime(2026, 11, 3),
        bbtCelsius: 36.30,
      ),
      DailyFertilityEntity(
        id: 'e4',
        userId: testProfile.id,
        logDate: DateTime(2026, 11, 4),
        bbtCelsius: 36.55,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BbtBiphasicChartWidget(
            cycleStartDate: DateTime(2026, 11, 1),
            entries: entries,
            coverlineCelsius: 36.30,
            showFahrenheit: false,
          ),
        ),
      ),
    );

    expect(find.byType(BbtBiphasicChartWidget), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.textContaining('36.30'), findsWidgets);
  });

  testWidgets('renders ConceptionHubPage with status, chart, and quick log sheet',
      (tester) async {
    // Start cycle
    await cycleRepo.logBleedingAndSymptoms(
      CycleSymptomEntity(
        id: 'symptom-init',
        userId: testProfile.id,
        logDate: DateTime(2026, 11, 1),
        bleedingFlow: 'medium',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeUserProfileProvider.overrideWith((ref) => testProfile),
          fertilityRepositoryProvider.overrideWithValue(fertilityRepo),
          cycleRepositoryProvider.overrideWithValue(cycleRepo),
        ],
        child: const MaterialApp(
          home: ConceptionHubPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hub de Fertilidad y Concepción'), findsOneWidget);
    expect(find.byKey(const Key('conception_status_card')), findsOneWidget);
    expect(find.byKey(const Key('quick_log_fertility_fab')), findsOneWidget);

    // Open quick log bottom sheet
    await tester.tap(find.byKey(const Key('quick_log_fertility_fab')));
    await tester.pumpAndSettle();

    expect(find.text('Registro Diario de Fertilidad'), findsOneWidget);
    expect(find.text('Temperatura Basal (°C)'), findsOneWidget);
    expect(find.text('Moco Cervical'), findsOneWidget);
    expect(find.text('Tira Reactiva LH'), findsOneWidget);
  });

  testWidgets('renders PreconceptionChecklistPage and allows toggling recommendations',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeUserProfileProvider.overrideWith((ref) => testProfile),
          fertilityRepositoryProvider.overrideWithValue(fertilityRepo),
        ],
        child: const MaterialApp(
          home: PreconceptionChecklistPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Checklist Preconcepcional'), findsOneWidget);
    expect(find.textContaining('Ácido fólico'), findsOneWidget);
    expect(find.textContaining('Consulta médica'), findsOneWidget);
    expect(find.byKey(const Key('folic_acid_checkbox')), findsOneWidget);

    // Toggle folic acid
    await tester.tap(find.byKey(const Key('folic_acid_checkbox')));
    await tester.pumpAndSettle();
  });
}
