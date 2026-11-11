import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/security/biometric_lock_service.dart';
import 'package:mobile/core/security/discreet_app_icon_service.dart';
import 'package:mobile/core/security/privacy_lifecycle_gate.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/partner/presentation/pages/partner_companion_view_page.dart';
import 'package:mobile/features/privacy/presentation/pages/privacy_and_data_sovereignty_page.dart';

void main() {
  test(
    'Longitudinal E2E Part 1: Offline-First Drift Enqueue & Idempotent SyncOutbox Drain',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final syncCoordinator = SyncCoordinator(db);

      await syncCoordinator.enqueueMutation(
        clientMutationId: 'e2e-mut-wellness-001',
        entityType: 'wellness_log',
        entityId: '2026-11-10',
        operation: 'upsert',
        payloadJson: '{"sleep_hours": 8.0, "hydration_ml": 2200}',
      );
      await syncCoordinator.enqueueMutation(
        clientMutationId: 'e2e-mut-cycle-002',
        entityType: 'cycle_symptom_log',
        entityId: '2026-11-10',
        operation: 'upsert',
        payloadJson: '{"bleeding_flow": "medium", "pelvic_pain": 3}',
      );

      final pendingBeforeSync = await syncCoordinator.getPendingMutations();
      expect(pendingBeforeSync.length, 2);

      for (final item in pendingBeforeSync) {
        await syncCoordinator.markAsSynced(item.clientMutationId);
      }
      final pendingAfterSync = await syncCoordinator.getPendingMutations();
      expect(pendingAfterSync, isEmpty);

      await db.close();
    },
  );

  testWidgets(
    'Longitudinal E2E Part 2: Stage Transitions -> Biometric Gate -> Partner View -> Account Purge',
    (tester) async {
      final biometricService = BiometricLockService()
        ..setBiometricEnabled(true)
        ..setTimeout(BiometricLockTimeout.immediate);
      final iconService = DiscreetAppIconService();

      // 1. Longitudinal Life Stage Transition (Pregnancy Dashboard)
      final pregnancyProfile = UserProfileEntity(
        id: 'e2e-user-1',
        firebaseUid: 'fb-e2e-1',
        firstName: 'Sofía',
        lastName: 'Longitudinal',
        currentLifeStage: LifeStage.pregnancy,
        onboardingCompleted: true,
        onboardingContext: const OnboardingContextEntity(
          birthYear: 1994,
          primaryIntents: [PrimaryIntent.pregnancyTracking],
          clinicalContextCompleted: true,
        ),
        enabledModules: const ['fetal_development', 'maternal_vitals'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 11, 10),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => pregnancyProfile),
          ],
          child: MaterialApp(
            theme: CoraTheme.standard(),
            home: PrivacyLifecycleGate(
              lockService: biometricService,
              child: const DynamicHomeDashboardPage(),
            ),
          ),
        ),
      );

      expect(find.text('Hola, Sofía'), findsOneWidget);
      expect(find.text('Embarazo Actual'), findsOneWidget);

      // 2. Privacy Lifecycle Shield & Biometric Gate on Background/Resume
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('privacy_shield_overlay')), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('privacy_shield_overlay')), findsOneWidget);

      await tester.tap(find.byKey(const Key('privacy_shield_unlock_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('privacy_shield_overlay')), findsNothing);

      // 3. Partner Companion Read-Only Projection
      await tester.pumpWidget(
        const MaterialApp(
          home: PartnerCompanionViewPage(
            projection: PartnerCompanionProjection(
              sharingUserName: 'Sofía',
              isLinkActive: true,
              pregnancyMilestone:
                  'Semana 20: Ecografía morfológica estructural.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Acompañando a Sofía'), findsOneWidget);
      expect(find.text('Solo Lectura'), findsOneWidget);

      // 4. Irreversible Account Purge Confirmation
      String? confirmedPhrase;
      await tester.pumpWidget(
        MaterialApp(
          home: PrivacyAndDataSovereigntyPage(
            biometricService: biometricService,
            iconService: iconService,
            onPurgeAccount: (phrase) async {
              confirmedPhrase = phrase;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final openPurgeBtn = find.byKey(const Key('open_purge_dialog_button'));
      await tester.scrollUntilVisible(openPurgeBtn, 200);
      await tester.ensureVisible(openPurgeBtn);
      await tester.pumpAndSettle();
      await tester.tap(openPurgeBtn);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('purge_phrase_field')),
        'ELIMINAR MI CUENTA CORA',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('purge_confirm_button')));
      await tester.pumpAndSettle();

      expect(confirmedPhrase, 'ELIMINAR MI CUENTA CORA');
      expect(find.byKey(const Key('purge_success_snackbar')), findsOneWidget);
    },
  );
}
