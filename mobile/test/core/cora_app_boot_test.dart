import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/cycle/data/cycle_repository_impl.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/fertility/data/fertility_repository_impl.dart';
import 'package:mobile/features/fertility/domain/entities/fertility_chart_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets(
    'CoraApp boots to OnboardingWizardPage and transitions to DynamicHomeDashboardPage',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const CoraApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Must NOT be stuck on the static placeholder screen
      expect(find.text('¿Cómo te llamas?'), findsOneWidget);

      // Step 1: Personal data
      await tester.enterText(
          find.byKey(const Key('first_name_input')), 'Lucía');
      await tester.enterText(
          find.byKey(const Key('last_name_input')), 'Mendoza');
      await tester.enterText(find.byKey(const Key('birth_year_input')), '1995');
      await tester.tap(find.byKey(const Key('next_step_button')));
      await tester.pumpAndSettle();

      // Step 2: Primary intents
      await tester.tap(find.byKey(const Key('intent_cycle_and_symptoms')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('next_step_button')));
      await tester.pumpAndSettle();

      // Step 3: Advance clinical context -> Step 4 Menstrual baseline
      await tester.tap(find.byKey(const Key('layer_three_continue_button')));
      await tester.pumpAndSettle();

      // Step 4: Complete onboarding
      final finishBtn = find.byKey(const Key('complete_onboarding_button'));
      await tester.ensureVisible(finishBtn);
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      // Must transition automatically to DynamicHomeDashboardPage
      expect(find.text('Hola, Lucía'), findsOneWidget);
      expect(find.byKey(const Key('quick_action_assistant')), findsOneWidget);
      expect(find.byKey(const Key('quick_action_library')), findsOneWidget);
      expect(find.byKey(const Key('quick_action_partner')), findsOneWidget);
      expect(find.byKey(const Key('quick_action_privacy')), findsOneWidget);
    },
  );

  test(
      'Cycle & Fertility repositories allow multiple same-day saves without UNIQUE crash',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final sync = SyncCoordinator(db);
    final cycleRepo = CycleRepositoryImpl(db, sync);
    final fertilityRepo = FertilityRepositoryImpl(db, sync);
    final today = DateTime(2026, 11, 21);

    // Same-day cycle quick log + chronic symptom update
    await cycleRepo.logBleedingAndSymptoms(
      CycleSymptomEntity(
        id: '',
        userId: 'u-1',
        logDate: today,
        bleedingFlow: 'medium',
        pelvicPain: 4,
      ),
    );
    final updatedSymptom = await cycleRepo.logBleedingAndSymptoms(
      CycleSymptomEntity(
        id: '',
        userId: 'u-1',
        logDate: today,
        bleedingFlow: 'none',
        acneSeverity: 3,
      ),
    );
    expect(updatedSymptom.bleedingFlow, 'medium');
    expect(updatedSymptom.pelvicPain, 4);
    expect(updatedSymptom.acneSeverity, 3);

    // Same-day fertility update twice
    await fertilityRepo.saveDailyFertility(
      DailyFertilityEntity(
        id: 'fert-1',
        userId: 'u-1',
        logDate: today,
        bbtCelsius: 36.4,
        cervicalMucus: 'creamy',
      ),
    );
    await fertilityRepo.saveDailyFertility(
      DailyFertilityEntity(
        id: 'fert-2',
        userId: 'u-1',
        logDate: today,
        bbtCelsius: 36.7,
        lhResult: 'peak',
      ),
    );
    final fetched = await fertilityRepo.getDailyFertility('u-1', today);
    expect(fetched, isNotNull);
    expect(fetched!.bbtCelsius, 36.7);
    expect(fetched.cervicalMucus, 'creamy');
    expect(fetched.lhResult, 'peak');
  });
}
