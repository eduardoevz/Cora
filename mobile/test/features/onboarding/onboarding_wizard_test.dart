import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/onboarding/presentation/pages/onboarding_wizard_page.dart';

void main() {
  testWidgets('Onboarding wizard enforces 1 to 3 primary intents in Step 2',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: CoraTheme.standard(),
          home: const OnboardingWizardPage(),
        ),
      ),
    );

    // Step 1: Fill name, birth year, stage
    expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('first_name_input')), 'Mariana');
    await tester.enterText(find.byKey(const Key('last_name_input')), 'Gómez');
    await tester.enterText(find.byKey(const Key('birth_year_input')), '1996');

    // Tap Next to advance to Step 2
    await tester.tap(find.byKey(const Key('next_step_button')));
    await tester.pumpAndSettle();

    // Step 2: Primary intents
    expect(find.text('¿Qué te gustaría priorizar hoy?'), findsOneWidget);

    // Initial state: 0 intents selected -> Next button must be disabled
    final nextBtnFinder = find.byKey(const Key('next_step_button'));
    final ElevatedButton nextBtn = tester.widget(nextBtnFinder);
    expect(nextBtn.onPressed, isNull);

    // Select 1st intent: Cycle
    await tester.tap(find.byKey(const Key('intent_cycle_and_symptoms')));
    await tester.pumpAndSettle();

    // Next button should now be enabled
    final ElevatedButton nextBtnAfterOne = tester.widget(nextBtnFinder);
    expect(nextBtnAfterOne.onPressed, isNotNull);

    // Select 2nd and 3rd intents
    await tester.tap(find.byKey(const Key('intent_family_planning')));
    await tester.tap(find.byKey(const Key('intent_general_wellness')));
    await tester.pumpAndSettle();

    // Attempt to tap 4th intent
    await tester.tap(find.byKey(const Key('intent_preventive_health')));
    await tester.pumpAndSettle();

    // 4th chip should remain unselected (max 3 reached)
    expect(find.text('Máximo 3 intenciones seleccionadas'), findsOneWidget);
  });

  testWidgets(
      'Onboarding wizard allows skipping Step 3 via Responder después button',
      (tester) async {
    bool onboardingCompleted = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: CoraTheme.standard(),
          home: OnboardingWizardPage(
            onCompleted: (profile) {
              onboardingCompleted = true;
              expect(
                  profile.onboardingContext.clinicalContextCompleted, isFalse);
            },
          ),
        ),
      ),
    );

    // Step 1
    await tester.enterText(
        find.byKey(const Key('first_name_input')), 'Valeria');
    await tester.enterText(find.byKey(const Key('last_name_input')), 'Ruiz');
    await tester.enterText(find.byKey(const Key('birth_year_input')), '2000');
    await tester.tap(find.byKey(const Key('next_step_button')));
    await tester.pumpAndSettle();

    // Step 2
    await tester.tap(find.byKey(const Key('intent_cycle_and_symptoms')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('next_step_button')));
    await tester.pumpAndSettle();

    // Step 3: Contexto Clínico Base (Opcional)
    expect(find.text('Contexto Clínico Base'), findsOneWidget);
    expect(find.byKey(const Key('skip_layer_three_button')), findsOneWidget);

    // Tap "Responder después"
    await tester.tap(find.byKey(const Key('skip_layer_three_button')));
    await tester.pumpAndSettle();

    expect(onboardingCompleted, isTrue);
  });
}
