import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

void main() {
  testWidgets(
      'Dynamic Home Dashboard renders pregnancy card when in pregnancy stage',
      (tester) async {
    final pregnancyProfile = UserProfileEntity(
      id: 'test-uuid-1',
      firebaseUid: 'uid-test-1',
      firstName: 'Camila',
      lastName: 'Torres',
      currentLifeStage: LifeStage.pregnancy,
      onboardingCompleted: true,
      onboardingContext: const OnboardingContextEntity(
        birthYear: 1996,
        primaryIntents: [PrimaryIntent.pregnancyTracking],
        clinicalContextCompleted: true,
      ),
      enabledModules: const [
        'fetal_development',
        "maternal_vitals",
        "wellness"
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeUserProfileProvider.overrideWith((ref) => pregnancyProfile),
        ],
        child: MaterialApp(
          theme: CoraTheme.standard(),
          home: const DynamicHomeDashboardPage(),
        ),
      ),
    );

    expect(find.text('Hola, Camila'), findsOneWidget);
    expect(find.text('Embarazo Actual'), findsOneWidget);
    expect(find.byKey(const Key('card_fetal_development')), findsOneWidget);
  });

  testWidgets(
      'Dynamic Home Dashboard renders without layout overflow under 2.0x accessibility scaling',
      (tester) async {
    final seniorProfile = UserProfileEntity(
      id: 'test-uuid-2',
      firebaseUid: 'uid-test-2',
      firstName: 'Elena',
      lastName: 'Vargas',
      currentLifeStage: LifeStage.seniorVitality,
      onboardingCompleted: true,
      onboardingContext: const OnboardingContextEntity(
        birthYear: 1958,
        primaryIntents: [PrimaryIntent.preventiveHealth],
        clinicalContextCompleted: true,
      ),
      enabledModules: const ['bone_muscle_health', "urogynecology"],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeUserProfileProvider.overrideWith((ref) => seniorProfile),
        ],
        child: MaterialApp(
          theme: CoraTheme.highLegibility(),
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: DynamicHomeDashboardPage(),
          ),
        ),
      ),
    );

    expect(find.text('Hola, Elena'), findsOneWidget);
    expect(find.text('Plenitud / Adulta Mayor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
