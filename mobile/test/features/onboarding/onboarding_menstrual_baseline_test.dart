import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/cycle/data/cycle_repository_impl.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/onboarding/data/local/profile_dao.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/pages/onboarding_wizard_page.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/onboarding/presentation/widgets/initial_periods_calendar_picker.dart';

void main() {
  testWidgets(
      'RegularAdult completes 4-step onboarding selecting 2 initial periods and seeds Drift SQLite',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final now = DateTime.now();
    final prevMonth = DateTime.utc(now.year, now.month - 1, 1);
    final twoMonthsAgo = DateTime.utc(now.year, now.month - 2, 1);
    final p2Start = DateTime.utc(prevMonth.year, prevMonth.month, 10);
    final p2End = DateTime.utc(prevMonth.year, prevMonth.month, 14);
    final p1Start = DateTime.utc(twoMonthsAgo.year, twoMonthsAgo.month, 11);
    final p1End = DateTime.utc(twoMonthsAgo.year, twoMonthsAgo.month, 15);
    final expectedDiff = p2Start.difference(p1Start).inDays;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          theme: CoraTheme.standard(),
          home: const OnboardingWizardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Step 1
    await tester.enterText(find.byKey(const Key('first_name_input')), 'Camila');
    await tester.enterText(find.byKey(const Key('last_name_input')), 'Navarro');
    await tester.enterText(find.byKey(const Key('birth_year_input')), '1995');
    await tester.tap(find.byKey(const Key('next_step_button')));
    await tester.pumpAndSettle();

    // Step 2
    await tester.tap(find.byKey(const Key('intent_cycle_and_symptoms')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('next_step_button')));
    await tester.pumpAndSettle();

    // Step 3 -> Advance to Step 4
    await tester.tap(find.byKey(const Key('layer_three_continue_button')));
    await tester.pumpAndSettle();
    expect(find.text('Tu Línea Base Menstrual'), findsOneWidget);

    // Go back 1 month (prevMonth) & select Latest Period: 10..14 (5 days)
    await tester.tap(find.byKey(const Key('cal_prev_month')));
    await tester.pumpAndSettle();
    await tester.tap(find
        .byKey(Key('cal_day_${p2Start.year}_${p2Start.month}_${p2Start.day}')));
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(Key('cal_day_${p2End.year}_${p2End.month}_${p2End.day}')));
    await tester.pumpAndSettle();

    // Auto-switches slot to Periodo anterior; go back 1 more month & select 11..15
    await tester.tap(find.byKey(const Key('cal_prev_month')));
    await tester.pumpAndSettle();
    await tester.tap(find
        .byKey(Key('cal_day_${p1Start.year}_${p1Start.month}_${p1Start.day}')));
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(Key('cal_day_${p1End.year}_${p1End.month}_${p1End.day}')));
    await tester.pumpAndSettle();

    // Verify auto-calculated cycle length and toggle Regular
    expect(find.text('$expectedDiff días'), findsOneWidget);
    final regularChip = find.byKey(const Key('regularity_regular'));
    await tester.ensureVisible(regularChip);
    await tester.tap(regularChip);
    await tester.pumpAndSettle();

    // Adjust cycle length manually via '+' stepper button
    final plusBtn = find.byKey(const Key('cycle_len_plus'));
    await tester.ensureVisible(plusBtn);
    await tester.tap(plusBtn);
    await tester.pumpAndSettle();
    expect(find.text('${expectedDiff + 1} días'), findsOneWidget);

    // Finish onboarding
    final completeBtn = find.byKey(const Key('complete_onboarding_button'));
    await tester.ensureVisible(completeBtn);
    await tester.tap(completeBtn);
    await tester.pumpAndSettle();

    // Verify Drift Profile & 2 Seeded Cycles + 10 Bleeding Symptom Logs
    final profile = await ProfileDao(db).getActiveProfile();
    expect(profile, isNotNull);
    expect(profile!.onboardingContext.cycleRegularity, CycleRegularity.regular);
    expect(profile.onboardingContext.typicalCycleLengthDays, expectedDiff + 1);
    expect(profile.onboardingContext.typicalBleedingDurationDays, 5);

    final cycleRows = await db.select(db.menstrualCycleEntries).get();
    expect(cycleRows.length, 2);
    expect(cycleRows.where((r) => r.isCurrent).length, 1);

    final symptomRows = await db.select(db.cycleSymptomEntries).get();
    expect(symptomRows.length, 10);
    expect(symptomRows.every((s) => s.bleedingFlow == 'medium'), isTrue);

    // Verify Drift timezone round-trip preserves exact recorded calendar dates
    final cycleRepo = CycleRepositoryImpl(db, SyncCoordinator(db));
    final cal = await cycleRepo.getCalendarMonth(
      userId: profile.id,
      year: p2Start.year,
      month: p2Start.month,
      referenceDate: now,
    );
    // estimateCycleLength prioritizes recorded completed cycle length (expectedDiff)
    // while UserProfileEntries stores the manually adjusted typicalCycleLengthDays (+1)
    expect(cal.estimatedCycleLengthDays, expectedDiff);
    final recordedDay10 = cal.days.firstWhere((d) => d.date.day == 10);
    expect(recordedDay10.dayMarker, CalendarDayMarker.recordedPeriod);
  });

  testWidgets(
      'Non-menstrual stage (pregnancy) skips Step 4 and sets CycleRegularity.notApplicable',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          theme: CoraTheme.standard(),
          home: const OnboardingWizardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('first_name_input')), 'Mariana');
    await tester.enterText(
        find.byKey(const Key('last_name_input')), 'Castillo');
    await tester.enterText(find.byKey(const Key('birth_year_input')), '1992');

    // Switch stage to Pregnancy
    await tester.tap(find.byKey(const Key('life_stage_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LifeStage.pregnancy.label).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('next_step_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('intent_pregnancy_tracking')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('next_step_button')));
    await tester.pumpAndSettle();

    // Step 3 directly exposes Finalizar Configuración (skips Step 4)
    expect(find.byKey(const Key('complete_onboarding_button')), findsOneWidget);
    expect(find.byKey(const Key('layer_three_continue_button')), findsNothing);
    await tester.tap(find.byKey(const Key('complete_onboarding_button')));
    await tester.pumpAndSettle();

    final profile = await ProfileDao(db).getActiveProfile();
    expect(profile, isNotNull);
    expect(profile!.currentLifeStage, LifeStage.pregnancy);
    expect(profile.onboardingContext.cycleRegularity,
        CycleRegularity.notApplicable);

    final cycleRows = await db.select(db.menstrualCycleEntries).get();
    expect(cycleRows, isEmpty);
  });

  testWidgets(
      'InitialPeriodsCalendarPicker supports 2.0x TextScaler without overflow',
      (tester) async {
    final prevHandler = FlutterError.onError;
    final capturedErrors = <FlutterErrorDetails>[];
    FlutterError.onError = (details) {
      capturedErrors.add(details);
    };
    addTearDown(() => FlutterError.onError = prevHandler);

    await tester.pumpWidget(
      MaterialApp(
        theme: CoraTheme.highLegibility(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 780),
            textScaler: TextScaler.linear(2.0),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: InitialPeriodsCalendarPicker(
                lifeStage: LifeStage.adolescence,
                diagnosedConditions: const [DiagnosedCondition.pcos],
                regularity: CycleRegularity.irregular,
                cycleLengthDays: 34,
                onRegularityChanged: (_) {},
                onCycleLengthChanged: (_) {},
                onLatestPeriodChanged: (_) {},
                onPreviousPeriodChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Predicciones flexibles activadas'), findsOneWidget);
    expect(capturedErrors, isEmpty);
  });
}
