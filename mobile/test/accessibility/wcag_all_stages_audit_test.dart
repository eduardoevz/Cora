import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/security/biometric_lock_service.dart';
import 'package:mobile/core/security/discreet_app_icon_service.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/partner/presentation/pages/partner_companion_view_page.dart';
import 'package:mobile/features/partner/presentation/pages/partner_sharing_settings_page.dart';
import 'package:mobile/features/privacy/presentation/pages/privacy_and_data_sovereignty_page.dart';

void main() {
  group('WCAG 2.1 AA/AAA Accessibility Audit across all 7 Life Stages', () {
    final stages = <LifeStage, List<String>>{
      LifeStage.adolescence: const ['cycle_tracker', 'wellness', 'education'],
      LifeStage.regularAdult: const ['cycle_tracker', 'wellness', 'treatments'],
      LifeStage.conceptionSearch: const [
        'fertility_ovulation',
        'cycle_tracker'
      ],
      LifeStage.pregnancy: const ['fetal_development', 'maternal_vitals'],
      LifeStage.postpartum: const ['lactation_tracker', 'epds_screening'],
      LifeStage.perimenopause: const ['vasomotor_symptoms', 'cardiometabolic'],
      LifeStage.seniorVitality: const ['bone_muscle_health', 'urogynecology'],
    };

    for (final entry in stages.entries) {
      testWidgets(
        'DynamicHomeDashboardPage renders ${entry.key.name} at TextScaler 2.0x without overflow',
        (tester) async {
          final profile = UserProfileEntity(
            id: 'wcag-${entry.key.name}',
            firebaseUid: 'fb-${entry.key.name}',
            firstName: 'Lucía',
            lastName: 'Accesible',
            currentLifeStage: entry.key,
            onboardingCompleted: true,
            onboardingContext: const OnboardingContextEntity(
              birthYear: 1985,
              primaryIntents: [PrimaryIntent.generalWellness],
              clinicalContextCompleted: true,
            ),
            enabledModules: entry.value,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          );

          final useHighLegibility = entry.key == LifeStage.seniorVitality;

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                activeUserProfileProvider.overrideWith((ref) => profile),
              ],
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(390, 844),
                  textScaler: TextScaler.linear(2.0),
                ),
                child: MaterialApp(
                  theme: useHighLegibility
                      ? CoraTheme.highLegibility()
                      : CoraTheme.standard(),
                  home: const DynamicHomeDashboardPage(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Hola, Lucía'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'Partner & Privacy screens render at TextScaler 2.0x in High Legibility theme without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 1800),
              textScaler: TextScaler.linear(2.0),
            ),
            child: MaterialApp(
              theme: CoraTheme.highLegibility(),
              home: PartnerSharingSettingsPage(
                initialInvitationCode: 'CORA-WCAG99',
                initialScopeFertility: true,
                initialScopePregnancy: true,
                initialScopeMood: false,
                onPermissionsChanged: (f, p, m) {},
                onRevokeLink: () async {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(
              size: Size(800, 1800),
              textScaler: TextScaler.linear(2.0),
            ),
            child: MaterialApp(
              home: PartnerCompanionViewPage(
                projection: PartnerCompanionProjection(
                  sharingUserName: 'Lucía',
                  isLinkActive: true,
                  pregnancyMilestone: 'Semana 28: Tercer trimestre iniciado.',
                  fertilityWindowSummary: 'Fase lútea estable.',
                  moodAndSupportTip: 'Descanso prioritario hoy.',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 1800),
              textScaler: TextScaler.linear(2.0),
            ),
            child: MaterialApp(
              theme: CoraTheme.highLegibility(),
              home: PrivacyAndDataSovereigntyPage(
                biometricService: BiometricLockService(),
                iconService: DiscreetAppIconService(),
                onPurgeAccount: (_) async {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
