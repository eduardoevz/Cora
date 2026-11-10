import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/postpartum/data/postpartum_repository_impl.dart';
import 'package:mobile/features/postpartum/domain/entities/postpartum_entities.dart';
import 'package:mobile/features/postpartum/presentation/pages/epds_mental_health_page.dart';
import 'package:mobile/features/postpartum/presentation/pages/lactation_and_milk_bank_page.dart';
import 'package:mobile/features/postpartum/presentation/pages/postpartum_recovery_page.dart';
import 'package:mobile/features/postpartum/presentation/providers/postpartum_providers.dart';

class _FakePostpartumRepository implements IPostpartumRepository {
  final List<PostpartumRecoveryLog> recoveryLogs = [];
  final List<LactationSession> lactationSessions = [];
  final List<MilkStashEntry> milkStash = [];
  final List<EpdsScreening> epdsScreenings = [];

  @override
  Future<void> saveRecoveryLog(PostpartumRecoveryLog log) async {
    recoveryLogs.insert(0, log);
  }

  @override
  Future<List<PostpartumRecoveryLog>> getRecentRecoveryLogs(String userId,
      {int limit = 20}) async {
    return recoveryLogs.take(limit).toList();
  }

  @override
  Future<void> saveLactationSession(LactationSession session) async {
    lactationSessions.insert(0, session);
  }

  @override
  Future<List<LactationSession>> getRecentLactationSessions(String userId,
      {int limit = 20}) async {
    return lactationSessions.take(limit).toList();
  }

  @override
  Future<void> saveMilkStashEntry(MilkStashEntry entry) async {
    milkStash.add(entry);
    milkStash.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
  }

  @override
  Future<List<MilkStashEntry>> getActiveMilkStash(String userId) async {
    return milkStash.where((e) => !e.isConsumed).toList();
  }

  @override
  Future<void> markMilkStashConsumed(String stashId) async {
    final idx = milkStash.indexWhere((e) => e.id == stashId);
    if (idx != -1) {
      final old = milkStash[idx];
      milkStash[idx] = MilkStashEntry(
        id: old.id,
        userId: old.userId,
        pumpedAt: old.pumpedAt,
        volumeMl: old.volumeMl,
        storageLocation: old.storageLocation,
        expiresAt: old.expiresAt,
        isConsumed: true,
        consumedAt: DateTime.now(),
        notes: old.notes,
      );
    }
  }

  @override
  Future<void> saveEpdsScreening(EpdsScreening screening) async {
    epdsScreenings.insert(0, screening);
  }

  @override
  Future<EpdsScreening?> getLatestEpdsScreening(String userId) async {
    return epdsScreenings.isNotEmpty ? epdsScreenings.first : null;
  }
}

void main() {
  final testProfile = UserProfileEntity(
    id: 'user_postpartum_test',
    firebaseUid: 'uid_postpartum_test',
    firstName: 'María',
    lastName: 'Gómez',
    currentLifeStage: LifeStage.postpartum,
    onboardingCompleted: true,
    onboardingContext: const OnboardingContextEntity(
      birthYear: 1993,
      primaryIntents: [PrimaryIntent.generalWellness],
    ),
    enabledModules: const [
      'postpartum_recovery',
      'breastfeeding_tracker',
      'epds_screening'
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('Postpartum Clinical Evaluation Unit Tests', () {
    test('Endometritis alert is triggered by fever >= 38.0 and foul odor', () {
      final alerts = PostpartumOfflineEvaluator.evaluate(
        daysPostpartum: 5,
        lochiaStage: LochiaStage.serosa,
        lochiaFlow: LochiaFlow.light,
        foulOdor: true,
        maternalTemperatureC: 38.4,
      );

      expect(alerts, isNotEmpty);
      expect(
        alerts.any((a) =>
            a.severity == PostpartumAlertSeverity.urgentEmergency &&
            a.category == 'endometritis_infection'),
        isTrue,
      );
    });

    test('Lochia hemorrhage alert is triggered by severeHemorrhage flow', () {
      final alerts = PostpartumOfflineEvaluator.evaluate(
        daysPostpartum: 2,
        lochiaStage: LochiaStage.rubra,
        lochiaFlow: LochiaFlow.severeHemorrhage,
        foulOdor: false,
      );

      expect(
        alerts.any((a) =>
            a.severity == PostpartumAlertSeverity.urgentEmergency &&
            a.category == 'secondary_postpartum_hemorrhage'),
        isTrue,
      );
    });

    test('EPDS item 10 positive unconditionally triggers immediate crisis support', () {
      final screening = EpdsOfflineScoringService.evaluate(
        id: 'test_epds',
        userId: 'user_1',
        daysPostpartum: 10,
        responses: {
          'item_1': 0,
          'item_2': 0,
          'item_3': 3,
          'item_4': 0,
          'item_5': 3,
          'item_6': 3,
          'item_7': 3,
          'item_8': 3,
          'item_9': 3,
          'item_10': 2, // 1 point for self harm
        },
      );

      expect(screening.selfHarmRisk, isTrue);
      expect(screening.severity, PostpartumAlertSeverity.immediateCrisisSupport);
      expect(screening.item10Score, 1);
    });

    test('Milk stash expiration calculates correctly per CDC guidelines', () {
      final now = DateTime.now();
      final fridgeExp =
          MilkStashEntry.calculateExpiration(now, StorageLocation.refrigerator);
      final freezerExp =
          MilkStashEntry.calculateExpiration(now, StorageLocation.freezer);

      expect(fridgeExp.difference(now).inDays, 4);
      expect(freezerExp.difference(now).inDays, 180);
    });
  });

  group('Postpartum Widgets Tests', () {
    testWidgets('PostpartumRecoveryPage registers recovery log with fever alert',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakePostpartumRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testProfile),
            postpartumRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: PostpartumRecoveryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recuperación Puerperal'), findsOneWidget);

      // Increment day
      await tester.tap(find.byKey(const Key('btn_increment_day')));
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);

      // Enter fever temperature
      await tester.enterText(
          find.byKey(const Key('input_temperature')), '38.5');
      await tester.pumpAndSettle();

      // Toggle foul odor
      await tester.tap(find.byKey(const Key('switch_foul_odor')));
      await tester.pumpAndSettle();

      // Check that urgent alert banner appeared
      expect(find.byKey(const Key('alert_endometritis_infection')), findsOneWidget);

      // Tap save
      await tester.tap(find.byKey(const Key('btn_save_recovery_log')));
      await tester.pumpAndSettle();

      expect(fakeRepo.recoveryLogs.length, 1);
      expect(fakeRepo.recoveryLogs.first.daysPostpartum, 4);
      expect(fakeRepo.recoveryLogs.first.maternalTemperatureC, 38.5);
      expect(fakeRepo.recoveryLogs.first.foulOdor, isTrue);
    });

    testWidgets('LactationAndMilkBankPage dual timer and milk stash FIFO',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakePostpartumRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testProfile),
            postpartumRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: LactationAndMilkBankPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lactancia y Banco de Leche'), findsOneWidget);

      // Start Left Breast Timer
      await tester.tap(find.byKey(const Key('btn_left_breast_timer')));
      await tester.pump(const Duration(seconds: 2));

      // Switch to Right Breast Timer
      await tester.tap(find.byKey(const Key('btn_right_breast_timer')));
      await tester.pump(const Duration(seconds: 2));

      // Save session
      await tester.tap(find.byKey(const Key('btn_save_lactation_session')));
      await tester.pumpAndSettle();

      expect(fakeRepo.lactationSessions.length, 1);
      expect(fakeRepo.lactationSessions.first.lastOfferedBreast,
          OfferedBreast.right);
      expect(fakeRepo.lactationSessions.first.suggestedNextBreast,
          OfferedBreast.left);
    });

    testWidgets('EpdsMentalHealthPage renders crisis banner on item 10 positive',
        (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakePostpartumRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testProfile),
            postpartumRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: EpdsMentalHealthPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Salud Emocional (EPDS)'), findsOneWidget);
      // Initially item 10 is 3 ("Nunca" -> 0 points), so no crisis banner
      expect(find.byKey(const Key('banner_immediate_crisis_support')),
          findsNothing);

      // Select option 1 ("A veces" -> index 1 -> 2 points) for item 10
      await tester.scrollUntilVisible(
        find.byKey(const Key('option_item_10_1')),
        200,
      );
      await tester.tap(find.byKey(const Key('option_item_10_1')));
      await tester.pumpAndSettle();

      // Crisis banner must immediately appear
      expect(find.byKey(const Key('banner_immediate_crisis_support')),
          findsOneWidget);
      expect(find.byKey(const Key('btn_call_crisis_hotline')), findsOneWidget);

      // Tap save
      await tester.scrollUntilVisible(
        find.byKey(const Key('btn_save_epds_screening')),
        200,
      );
      await tester.tap(find.byKey(const Key('btn_save_epds_screening')));
      await tester.pumpAndSettle();

      expect(fakeRepo.epdsScreenings.length, 1);
      expect(fakeRepo.epdsScreenings.first.selfHarmRisk, isTrue);
      expect(fakeRepo.epdsScreenings.first.severity,
          PostpartumAlertSeverity.immediateCrisisSupport);
    });
  });
}
