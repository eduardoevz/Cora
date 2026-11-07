import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/wellness/data/wellness_repository_impl.dart';
import 'package:mobile/features/wellness/presentation/pages/wellness_tracker_page.dart';
import 'package:mobile/features/wellness/presentation/providers/wellness_providers.dart';

void main() {
  late AppDatabase db;
  late SyncCoordinator syncCoordinator;
  late WellnessRepositoryImpl wellnessRepo;

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
    enabledModules: const ['wellness'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncCoordinator = SyncCoordinator(db);
    wellnessRepo = WellnessRepositoryImpl(db, syncCoordinator);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
      'renders WellnessTrackerPage, modifies sliders and saves consolidated log',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncCoordinatorProvider.overrideWithValue(syncCoordinator),
          wellnessRepositoryProvider.overrideWithValue(wellnessRepo),
          activeUserProfileProvider.overrideWith((ref) => testProfile),
        ],
        child: const MaterialApp(
          home: WellnessTrackerPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify page title and sections
    expect(find.text('Bienestar y Hábitos'), findsOneWidget);
    expect(find.text('Sueño y Descanso'), findsOneWidget);
    expect(find.text('Nivel de Energía'), findsOneWidget);
    expect(find.text('Hidratación'), findsOneWidget);

    // Enter notes
    await tester.enterText(
        find.byKey(const Key('wellness_notes_input')), 'Excelente energía');
    await tester.pumpAndSettle();

    // Tap quick hydration chip +500 ml
    await tester.tap(find.text('+500 ml'));
    await tester.pumpAndSettle();

    // Tap Save button
    await tester.tap(find.byKey(const Key('save_wellness_button')));
    await tester.pumpAndSettle();

    // Verify SnackBar shown
    expect(find.text('Registro diario consolidado (Offline-First)'),
        findsOneWidget);

    // Verify stored in DB
    final saved = await wellnessRepo.getDailyLog(
        userId: 'user-val-1', date: DateTime.now());
    expect(saved, isNotNull);
    expect(saved!.notes, equals('Excelente energía'));
    expect(saved.hydrationMl, equals(2000)); // 1500 + 500
  });
}
