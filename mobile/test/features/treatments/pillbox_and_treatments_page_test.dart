import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/treatments/data/treatments_repository_impl.dart';
import 'package:mobile/features/treatments/domain/entities/treatment_entities.dart';
import 'package:mobile/features/treatments/presentation/pages/pillbox_and_treatments_page.dart';
import 'package:mobile/features/treatments/presentation/providers/treatment_providers.dart';

void main() {
  late AppDatabase db;
  late SyncCoordinator syncCoordinator;
  late TreatmentsRepositoryImpl treatmentsRepo;

  final testProfile = UserProfileEntity(
    id: 'user-val-1',
    firebaseUid: 'uid-val-1',
    firstName: 'Valentina',
    lastName: 'Ríos',
    currentLifeStage: LifeStage.regularAdult,
    onboardingCompleted: true,
    onboardingContext: const OnboardingContextEntity(
      birthYear: 1996,
      primaryIntents: [PrimaryIntent.cycleAndSymptoms],
      clinicalContextCompleted: true,
    ),
    enabledModules: const ['contraceptive_management'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncCoordinator = SyncCoordinator(db);
    treatmentsRepo = TreatmentsRepositoryImpl(db, syncCoordinator);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
      'renders PillboxAndTreatmentsPage, toggles discreet mode and marks dose taken',
      (tester) async {
    // Seed one treatment regimen
    await treatmentsRepo.saveRegimen(
      TreatmentRegimenEntity(
        id: 'regimen-yasmin-1',
        userId: testProfile.id,
        name: 'Yasmin 21',
        category: 'contraceptive_oral_combined',
        dosage: '1 comprimido',
        scheduleType: 'cyclic_active_break',
        scheduledTime: '21:00',
        activeDays: 21,
        breakDays: 7,
        startDate: DateTime.now().toUtc(),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncCoordinatorProvider.overrideWithValue(syncCoordinator),
          treatmentsRepositoryProvider.overrideWithValue(treatmentsRepo),
          activeUserProfileProvider.overrideWith((ref) => testProfile),
        ],
        child: const MaterialApp(
          home: PillboxAndTreatmentsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title and regimen card
    expect(find.text('Pastillero y Tratamientos'), findsOneWidget);
    expect(find.text('Yasmin 21'), findsOneWidget);

    // Default discreet mode should display masked reminder
    expect(
        find.text(
            'Recordatorio: "Tienes un recordatorio de bienestar en Cora"'),
        findsOneWidget);

    // Toggle discreet mode off
    await tester.tap(find.byKey(const Key('discreet_mode_switch')));
    await tester.pumpAndSettle();

    // Now detailed text should appear
    expect(
        find.text(
            'Recordatorio: "1 comprimido a las 21:00"'),
        findsOneWidget);

    // Tap "Tomar Dosis"
    await tester.tap(find.byKey(const Key('take_dose_regimen-yasmin-1')));
    await tester.pumpAndSettle();

    // Verify SnackBar
    expect(
        find.text('¡Dosis de Yasmin 21 registrada con éxito!'), findsOneWidget);

    // Verify stored in DB
    final intakes = await treatmentsRepo.getIntakes(
      regimenId: 'regimen-yasmin-1',
      from: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      to: DateTime.now().toUtc().add(const Duration(days: 1)),
    );
    expect(intakes.length, equals(1));
    expect(intakes.first.status, equals('taken'));
  });
}
