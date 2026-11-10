import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/menopause/data/menopause_repository_impl.dart';
import 'package:mobile/features/menopause/domain/models/cardiometabolic_panel.dart';
import 'package:mobile/features/menopause/domain/models/hot_flash_episode.dart';
import 'package:mobile/features/menopause/domain/models/vaginal_bleeding_record.dart';
import 'package:mobile/features/menopause/domain/services/menopause_offline_evaluator.dart';
import 'package:mobile/features/menopause/presentation/pages/hot_flash_tracker_page.dart';
import 'package:mobile/features/menopause/presentation/pages/perimenopause_hub_page.dart';
import 'package:mobile/features/menopause/presentation/providers/menopause_providers.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

class _FakeMenopauseRepository implements IMenopauseRepository {
  final List<HotFlashEpisode> hotFlashes = [];
  CardiometabolicPanel? latestCardio;
  final List<VaginalBleedingRecord> bleedingRecords = [];

  @override
  Future<void> saveHotFlash(HotFlashEpisode episode) async {
    hotFlashes.insert(0, episode);
  }

  @override
  Future<List<HotFlashEpisode>> getRecentHotFlashes(String userId,
      {int limit = 50}) async {
    return hotFlashes.take(limit).toList();
  }

  @override
  Future<void> saveCardiometabolicPanel(CardiometabolicPanel panel) async {
    latestCardio = panel;
  }

  @override
  Future<CardiometabolicPanel?> getLatestCardiometabolicPanel(
      String userId) async {
    return latestCardio;
  }

  @override
  Future<void> saveVaginalBleeding(VaginalBleedingRecord record) async {
    bleedingRecords.insert(0, record);
  }

  @override
  Future<List<VaginalBleedingRecord>> getRecentBleedingRecords(String userId,
      {int limit = 50}) async {
    return bleedingRecords.take(limit).toList();
  }
}

void main() {
  final testUser = UserProfileEntity(
    id: 'user_test_1',
    firebaseUid: 'fb_1',
    firstName: 'Elena',
    lastName: 'García',
    currentLifeStage: LifeStage.perimenopause,
    onboardingCompleted: true,
    onboardingContext: const OnboardingContextEntity(
      birthYear: 1974,
      primaryIntents: [PrimaryIntent.generalWellness],
      diagnosedConditions: [DiagnosedCondition.none],
      clinicalContextCompleted: true,
    ),
    enabledModules: const ['cycle_tracking', 'wellness'],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('MenopauseOfflineEvaluator Unit Tests', () {
    const evaluator = MenopauseOfflineEvaluator();

    test('Classifies as early transition when cycle length diff >= 7 days', () {
      final stage = evaluator.classifyStraw10(
        age: 48,
        consecutiveCycleLengths: [28, 36], // Diff: 8 days
        daysSinceLastMenstruation: 30,
      );
      expect(stage, Straw10Stage.earlyTransition);
    });

    test('Classifies as late transition when amenorrhea >= 60 days', () {
      final stage = evaluator.classifyStraw10(
        age: 50,
        consecutiveCycleLengths: [30, 32],
        daysSinceLastMenstruation: 75,
      );
      expect(stage, Straw10Stage.lateTransition);
    });

    test('Classifies as postmenopause when amenorrhea >= 365 days', () {
      final stage = evaluator.classifyStraw10(
        age: 52,
        consecutiveCycleLengths: [40, 60],
        daysSinceLastMenstruation: 380,
      );
      expect(stage, Straw10Stage.postmenopause);
    });

    test('Inviolable postmenopausal bleeding alert triggers when >= 365 days', () {
      final alert = evaluator.evaluateBleedingSafety(
        daysPriorAmenorrhea: 400,
      );
      expect(alert, isNotNull);
      expect(alert!.code, 'POSTMENOPAUSAL_BLEEDING_ALERT');
      expect(alert.severity, 'URGENT_EMERGENCY');
      expect(alert.requiresImmediateEvaluation, isTrue);
    });

    test('No postmenopausal alert when bleeding happens during late transition', () {
      final alert = evaluator.evaluateBleedingSafety(
        daysPriorAmenorrhea: 80,
      );
      expect(alert, isNull);
    });
  });

  group('HotFlashTrackerPage Widget Tests', () {
    testWidgets('Renders controls, selects values and saves episode',
        (tester) async {
      final fakeRepo = _FakeMenopauseRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testUser),
            menopauseRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: HotFlashTrackerPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and segmented buttons
      expect(find.text('Registrar Sofoco / Sudor'), findsOneWidget);
      expect(find.text('Diurno'), findsOneWidget);
      expect(find.text('Sudor Nocturno'), findsOneWidget);

      // Tap night sweats
      await tester.tap(find.text('Sudor Nocturno'));
      await tester.pumpAndSettle();

      // Select severity 3
      await tester.tap(find.text('3 Severo'));
      await tester.pumpAndSettle();

      // Tap trigger "Cafeína"
      await tester.tap(find.text('Cafeína'));
      await tester.pumpAndSettle();

      // Save
      final saveBtnFinder = find.byKey(const Key('save_hot_flash_button'));
      await tester.ensureVisible(saveBtnFinder);
      await tester.pumpAndSettle();
      await tester.tap(saveBtnFinder);
      await tester.pumpAndSettle();

      expect(fakeRepo.hotFlashes.length, 1);
      final saved = fakeRepo.hotFlashes.first;
      expect(saved.flashType, HotFlashType.nightSweats);
      expect(saved.severity, HotFlashSeverity.severe);
      expect(saved.triggers, contains('Cafeína'));
    });
  });

  group('PerimenopauseHubPage Widget Tests', () {
    testWidgets('Renders STRAW+10 card, hot flashes count and emergency banner',
        (tester) async {
      final fakeRepo = _FakeMenopauseRepository();
      fakeRepo.hotFlashes.add(
        HotFlashEpisode(
          id: 'hf_1',
          userId: testUser.id,
          occurredAt: DateTime.now(),
          severity: HotFlashSeverity.severe,
          flashType: HotFlashType.nightSweats,
          durationMinutes: 8,
          triggers: ['Calor ambiental'],
        ),
      );
      fakeRepo.bleedingRecords.add(
        VaginalBleedingRecord(
          id: 'vb_1',
          userId: testUser.id,
          observationDate: DateTime.now(),
          daysPriorAmenorrhea: 420,
          isAlertTriggered: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testUser),
            menopauseRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: PerimenopauseHubPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perimenopausia y Menopausia'), findsOneWidget);
      expect(find.text('Transición Hormonal (STRAW+10)'), findsOneWidget);

      // Verify emergency banner is rendered due to isAlertTriggered: true
      expect(
        find.byKey(const Key('postmenopausal_bleeding_alert_banner')),
        findsOneWidget,
      );
      expect(
        find.text('Alerta de Sangrado Posmenopáusico'),
        findsOneWidget,
      );

      // Verify hot flash summary
      expect(find.textContaining('Total episodios recientes: 1'), findsOneWidget);
    });
  });
}
