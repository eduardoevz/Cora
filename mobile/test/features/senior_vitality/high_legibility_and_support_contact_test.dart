import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/senior_vitality/data/senior_vitality_repository_impl.dart';
import 'package:mobile/features/senior_vitality/domain/models/dexa_bone_scan.dart';
import 'package:mobile/features/senior_vitality/domain/models/fall_risk_entry.dart';
import 'package:mobile/features/senior_vitality/domain/models/pelvic_floor_entry.dart';
import 'package:mobile/features/senior_vitality/domain/models/trusted_support_contact.dart';
import 'package:mobile/features/senior_vitality/domain/services/senior_vitality_offline_evaluator.dart';
import 'package:mobile/features/senior_vitality/presentation/pages/senior_vitality_hub_page.dart';
import 'package:mobile/features/senior_vitality/presentation/providers/senior_vitality_providers.dart';
import 'package:mobile/features/senior_vitality/presentation/widgets/trusted_contact_quick_action_card.dart';

class _FakeSeniorVitalityRepository implements ISeniorVitalityRepository {
  DexaBoneScan? latestDexa;
  FallRiskEntry? latestFall;
  final List<PelvicFloorEntry> pelvicLogs = [];
  TrustedSupportContact? primaryContact;

  @override
  Future<void> saveDexaScan(DexaBoneScan scan) async {
    latestDexa = scan;
  }

  @override
  Future<DexaBoneScan?> getLatestDexaScan(String userId) async {
    return latestDexa;
  }

  @override
  Future<void> saveFallRiskAssessment(FallRiskEntry entry) async {
    latestFall = entry;
  }

  @override
  Future<FallRiskEntry?> getLatestFallRiskAssessment(String userId) async {
    return latestFall;
  }

  @override
  Future<void> savePelvicLog(PelvicFloorEntry entry) async {
    pelvicLogs.insert(0, entry);
  }

  @override
  Future<List<PelvicFloorEntry>> getRecentPelvicLogs(String userId,
      {int limit = 20}) async {
    return pelvicLogs.take(limit).toList();
  }

  @override
  Future<void> saveSupportContact(TrustedSupportContact contact) async {
    primaryContact = contact;
  }

  @override
  Future<TrustedSupportContact?> getPrimarySupportContact(String userId) async {
    return primaryContact;
  }
}

void main() {
  final testUser = UserProfileEntity(
    id: 'user_senior_1',
    firebaseUid: 'fb_senior_1',
    firstName: 'Rosa',
    lastName: 'Morales',
    currentLifeStage: LifeStage.seniorVitality,
    onboardingCompleted: true,
    onboardingContext: const OnboardingContextEntity(
      birthYear: 1956,
      primaryIntents: [PrimaryIntent.generalWellness],
      diagnosedConditions: [DiagnosedCondition.none],
      clinicalContextCompleted: true,
    ),
    enabledModules: const ['wellness'],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('SeniorVitalityOfflineEvaluator Unit Tests', () {
    const evaluator = SeniorVitalityOfflineEvaluator();

    test('Classifies T-score according to WHO diagnostic categories', () {
      expect(evaluator.classifyBoneDensity(-0.5), BoneDensityCategory.normal);
      expect(evaluator.classifyBoneDensity(-1.8), BoneDensityCategory.osteopenia);
      expect(evaluator.classifyBoneDensity(-2.7), BoneDensityCategory.osteoporosis);
      expect(
        evaluator.classifyBoneDensity(-2.7, previousFracture: true),
        BoneDensityCategory.severeOsteoporosis,
      );
    });

    test('Fall risk evaluation scores appropriately', () {
      final highResult = evaluator.evaluateFallRisk(
        fallsPastYear: 2,
        hasGaitUnsteadiness: true,
        usesWalkingAid: true,
        timedUpAndGoSeconds: 15.0,
      );
      expect(highResult.level, FallRiskLevel.high);
      expect(highResult.score, greaterThanOrEqualTo(4));

      final lowResult = evaluator.evaluateFallRisk(
        fallsPastYear: 0,
        hasGaitUnsteadiness: false,
        usesWalkingAid: false,
        timedUpAndGoSeconds: 8.0,
      );
      expect(lowResult.level, FallRiskLevel.low);
      expect(lowResult.score, 0);
    });

    test('Detects high fracture risk when osteopenia + high fall risk intersect', () {
      final isAlert = evaluator.isHighFractureRisk(
        boneCategory: BoneDensityCategory.osteopenia,
        fallLevel: FallRiskLevel.high,
      );
      expect(isAlert, isTrue);

      final normalAlert = evaluator.isHighFractureRisk(
        boneCategory: BoneDensityCategory.normal,
        fallLevel: FallRiskLevel.low,
      );
      expect(normalAlert, isFalse);
    });
  });

  group('TrustedContactQuickActionCard Widget Tests', () {
    testWidgets('Opens 2-step confirmation modal with large touch targets >= 56dp',
        (tester) async {
      final fakeRepo = _FakeSeniorVitalityRepository();
      fakeRepo.primaryContact = const TrustedSupportContact(
        id: 'contact_1',
        userId: 'user_senior_1',
        contactName: 'Dra. Carmen Silva (Hija)',
        relationship: 'Hija',
        phoneNumber: '+525512345678',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testUser),
            seniorVitalityRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: CoraTheme.highLegibility(),
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: TrustedContactQuickActionCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Tap the card
      expect(find.byKey(const Key('trusted_contact_quick_card')), findsOneWidget);
      expect(find.textContaining('Carmen Silva'), findsOneWidget);

      await tester.tap(find.byKey(const Key('trusted_contact_quick_card')));
      await tester.pumpAndSettle();

      // Step 2: Modal displays 2-step options
      expect(find.text('Confirmar Comunicación'), findsOneWidget);
      expect(find.textContaining('+525512345678'), findsOneWidget);

      final callBtn = find.byKey(const Key('confirm_call_button'));
      expect(callBtn, findsOneWidget);
      final size = tester.getSize(callBtn);
      expect(size.height, greaterThanOrEqualTo(56.0)); // Touch target invariant
    });
  });

  group('SeniorVitalityHubPage Widget Tests & Scaled Rendering', () {
    testWidgets('Renders all cards and supports TextScaler 2.0 without overflow',
        (tester) async {
      final fakeRepo = _FakeSeniorVitalityRepository();
      fakeRepo.latestDexa = DexaBoneScan(
        id: 'dexa_1',
        userId: 'user_senior_1',
        scanDate: DateTime(2026, 4, 10),
        anatomicalSite: AnatomicalSite.femoralNeck,
        tScore: -2.8,
        category: BoneDensityCategory.osteoporosis,
      );
      fakeRepo.latestFall = FallRiskEntry(
        id: 'fall_1',
        userId: 'user_senior_1',
        assessmentDate: DateTime(2026, 5, 1),
        fallsPastYear: 2,
        hasGaitUnsteadiness: true,
        riskLevel: FallRiskLevel.high,
      );
      fakeRepo.primaryContact = const TrustedSupportContact(
        id: 'c_1',
        userId: 'user_senior_1',
        contactName: 'Carmen',
        relationship: 'Hija',
        phoneNumber: '5512345678',
      );

      // Render with 2.0x text scaler (WCAG AAA Senior Accessibility Requirement)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testUser),
            seniorVitalityRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2.0),
            ),
            child: MaterialApp(
              theme: CoraTheme.highLegibility(),
              home: const SeniorVitalityHubPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plenitud y Vitalidad'), findsOneWidget);
      expect(find.text('Salud Ósea (Densitometría)'), findsOneWidget);
      expect(find.textContaining('-2.8'), findsOneWidget);
      expect(find.text('Prevención de Caídas'), findsOneWidget);
      expect(find.text('Suelo Pélvico y Continencia'), findsOneWidget);

      // Verify fracture risk banner is active
      expect(find.byKey(const Key('high_fracture_risk_banner')), findsOneWidget);

      // Zero exceptions and no RenderFlex overflow caught by Flutter test framework
      expect(tester.takeException(), isNull);
    });
  });
}
