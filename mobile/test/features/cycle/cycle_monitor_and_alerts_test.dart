import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/cycle/data/cycle_repository_impl.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/presentation/pages/cycle_monitor_page.dart';
import 'package:mobile/features/cycle/presentation/providers/cycle_providers.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

void main() {
  late AppDatabase db;
  late SyncCoordinator syncCoordinator;
  late CycleRepositoryImpl cycleRepo;

  final testProfile = UserProfileEntity(
    id: 'user-sofia-1',
    firebaseUid: 'uid-sofia-1',
    firstName: 'Sofía',
    lastName: 'Mendoza',
    currentLifeStage: LifeStage.regularAdult,
    onboardingCompleted: true,
    onboardingContext: const OnboardingContextEntity(
      birthYear: 1998,
      primaryIntents: [PrimaryIntent.cycleAndSymptoms],
      clinicalContextCompleted: true,
    ),
    enabledModules: const ['cycle_tracking'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncCoordinator = SyncCoordinator(db);
    cycleRepo = CycleRepositoryImpl(db, syncCoordinator);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
      'renders CycleMonitorPage with phase wheel, status details and quick log',
      (tester) async {
    // Pre-populate an active cycle starting 3 days ago
    final day1 = DateTime.now().subtract(const Duration(days: 2));
    await cycleRepo.logBleedingAndSymptoms(
      CycleSymptomEntity(
        id: 'symptom-1',
        userId: testProfile.id,
        logDate: day1,
        bleedingFlow: 'heavy',
        pelvicPain: 3,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncCoordinatorProvider.overrideWithValue(syncCoordinator),
          cycleRepositoryProvider.overrideWithValue(cycleRepo),
          activeUserProfileProvider.overrideWith((ref) => testProfile),
        ],
        child: const MaterialApp(
          home: CycleMonitorPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify presence of Day 3 and Phase
    expect(find.text('Monitoreo del Ciclo'), findsOneWidget);
    expect(find.text('Día 3'), findsOneWidget);
    expect(find.text('Fase Menstrual'), findsOneWidget);
    expect(find.text('Consejo del Día'), findsOneWidget);
    expect(find.text('Registrar Sangrado y Síntomas'), findsOneWidget);

    // Tap quick log button
    await tester.tap(find.text('Registrar Sangrado y Síntomas'));
    await tester.pumpAndSettle();

    expect(find.text('Registro Rápido de Ciclo'), findsOneWidget);
    expect(find.text('Intensidad de Sangrado:'), findsOneWidget);
    expect(find.text('Medio'), findsOneWidget);

    // Select 'Medio'
    await tester.tap(find.text('Medio'));
    await tester.pumpAndSettle();

    // Tap Guardar
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Registro guardado correctamente.'), findsOneWidget);
  });

  test('CycleRepositoryImpl detects endometriosis risk alert offline', () async {
    final userId = testProfile.id;

    // Cycle 1: Severe pain 8
    final cycle1Date = DateTime.now().subtract(const Duration(days: 35));
    await cycleRepo.logBleedingAndSymptoms(
      CycleSymptomEntity(
        id: 'c1-log',
        userId: userId,
        logDate: cycle1Date,
        bleedingFlow: 'heavy',
        pelvicPain: 8,
        dysmenorrhea: 8,
      ),
    );

    // Cycle 2: Started 7 days ago with severe pain 9
    final cycle2Date = DateTime.now().subtract(const Duration(days: 6));
    await cycleRepo.logBleedingAndSymptoms(
      CycleSymptomEntity(
        id: 'c2-log',
        userId: userId,
        logDate: cycle2Date,
        bleedingFlow: 'medium',
        pelvicPain: 9,
        dysmenorrhea: 9,
      ),
    );

    final overview = await cycleRepo.getCycleOverview(userId: userId);

    expect(overview.alerts, isNotEmpty);
    final endoAlert = overview.alerts.firstWhere(
      (a) => a.alertType == 'severe_pelvic_pain_endometriosis_risk',
    );
    expect(endoAlert.severity, 'clinical_recommendation');
    expect(endoAlert.titleEs, contains('Dolor pélvico persistente'));
  });
}
