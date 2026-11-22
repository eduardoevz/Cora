import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/main.dart';

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxSteps = 20,
}) async {
  for (var i = 0; i < maxSteps; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Full Cora E2E flow on Android device: Onboarding -> All Modules -> Stage Switch -> GDPR Purge',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: CoraApp(),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 20; i++) {
        if (find.text('¿Cómo te llamas?').evaluate().isNotEmpty ||
            find
                .byKey(const Key('switch_stage_chip_button'))
                .evaluate()
                .isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pumpAndSettle();

      // Clear any residual state from prior runs if profile already existed
      if (find.text('¿Cómo te llamas?').evaluate().isEmpty) {
        final ctx = tester.element(find.byType(Scaffold).first);
        final container = ProviderScope.containerOf(ctx);
        await container.read(appDatabaseProvider).purgeAllLocalData();
        container.read(activeUserProfileProvider.notifier).state = null;
        await tester.pumpAndSettle();
      }

      // 1. Onboarding Layer 1
      expect(find.text('¿Cómo te llamas?'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('first_name_input')), 'Sofía');
      await tester.enterText(find.byKey(const Key('last_name_input')), 'Vega');
      await tester.enterText(find.byKey(const Key('birth_year_input')), '1994');
      await tester.tap(find.byKey(const Key('next_step_button')));
      await tester.pumpAndSettle();

      // 2. Onboarding Layer 2
      expect(find.text('¿Qué te gustaría priorizar hoy?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('intent_cycle_and_symptoms')));
      await tester.tap(find.byKey(const Key('intent_general_wellness')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('next_step_button')));
      await tester.pumpAndSettle();

      // 3. Onboarding Layer 3
      expect(find.text('Contexto Clínico Base'), findsOneWidget);
      final completeBtn = find.byKey(const Key('complete_onboarding_button'));
      await tester.ensureVisible(completeBtn);
      await tester.pumpAndSettle();
      await tester.tap(completeBtn);
      await _pumpUntilFound(tester, find.text('Hola, Sofía'));

      // 4. Dynamic Home Dashboard
      expect(find.text('Hola, Sofía'), findsOneWidget);
      expect(find.byKey(const Key('dashboard_cycle_card')), findsOneWidget);

      // 5. Cycle Monitor flow + Quick Log
      await tester.tap(find.byKey(const Key('dashboard_cycle_card')));
      await tester.pumpAndSettle();
      expect(find.text('Monitoreo del Ciclo'), findsOneWidget);
      await tester.tap(find.text('Registrar Sangrado y Síntomas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 6. Wellness Tracker flow
      await tester.tap(find.byKey(const Key('quick_action_wellness')));
      await tester.pumpAndSettle();
      expect(find.text('Bienestar y Hábitos'), findsOneWidget);
      await tester.tap(find.byKey(const Key('save_wellness_button')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 7. Pillbox & Treatments flow
      await tester.tap(find.byKey(const Key('quick_action_treatments')));
      await tester.pumpAndSettle();
      expect(find.text('Pastillero y Tratamientos'), findsOneWidget);
      await tester.tap(find.byKey(const Key('add_regimen_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('regimen_name_input')), 'Ácido Fólico');
      await tester.tap(find.byKey(const Key('save_new_regimen_button')));
      await tester.pumpAndSettle();
      expect(find.text('Ácido Fólico'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 8. Medical Folder & Doctor-Ready PDF
      await tester.tap(find.byKey(const Key('quick_action_medical_folder')));
      await tester.pumpAndSettle();
      expect(find.text('Carpeta Clínica Digital'), findsOneWidget);
      await tester.tap(find.byKey(const Key('open_doctor_report_button')));
      await tester.pumpAndSettle();
      expect(find.text('Reporte Doctor-Ready PDF'), findsOneWidget);
      await tester.tap(find.byKey(const Key('doctor_report_generate_button')));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('doctor_report_completed_card')),
      );
      expect(find.byKey(const Key('doctor_report_completed_card')),
          findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 9. Clinical Assistant (Normal + Emergency Triage)
      final assistantCard = find.byKey(const Key('quick_action_assistant'));
      await tester.scrollUntilVisible(assistantCard, 200);
      await tester.tap(assistantCard);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Asistente Clínico Cora'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('assistant_query_input')),
        'Tengo sangrado abundante de una toalla por hora desde hace 2 horas',
      );
      await tester.tap(find.byKey(const Key('assistant_send_button')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('Urgente'), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 10. Clinical Library
      final libraryCard = find.byKey(const Key('quick_action_library'));
      await tester.scrollUntilVisible(libraryCard, 200);
      await tester.tap(libraryCard);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Biblioteca Clínica Cora'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 11. Partner Sharing
      final partnerCard = find.byKey(const Key('quick_action_partner'));
      await tester.scrollUntilVisible(partnerCard, 200);
      await tester.tap(partnerCard);
      await tester.pumpAndSettle();
      expect(find.text('Modo Acompañante / Pareja'), findsOneWidget);
      await tester
          .tap(find.byKey(const Key('generate_invitation_code_button')));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('active_invitation_code_display')),
      );
      expect(find.byKey(const Key('active_invitation_code_display')),
          findsOneWidget);
      final companionBtn = find.byKey(const Key('open_companion_view_button'));
      await tester.scrollUntilVisible(
        companionBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(companionBtn);
      await _pumpUntilFound(tester, find.text('Solo Lectura'));
      expect(find.text('Solo Lectura'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 12. Life Stage Switch -> Pregnancy & Senior Vitality (High Legibility)
      final switchBtn = find.byKey(const Key('switch_stage_chip_button'));
      await tester.scrollUntilVisible(switchBtn, -200);
      await tester.tap(switchBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('switch_target_stage_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(LifeStage.pregnancy.label).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_stage_switch_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dashboard_pregnancy_hub_card')),
          findsOneWidget);

      // 13. Privacy & GDPR Purge -> Returns to Onboarding
      await tester.tap(find.byKey(const Key('open_privacy_settings_button')));
      await tester.pumpAndSettle();
      expect(find.text('Privacidad y Soberanía'), findsOneWidget);
      final purgeBtn = find.byKey(const Key('open_purge_dialog_button'));
      await tester.scrollUntilVisible(
        purgeBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(purgeBtn);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('purge_phrase_field')),
        'ELIMINAR MI CUENTA CORA',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('purge_confirm_button')));
      await _pumpUntilFound(tester, find.text('¿Cómo te llamas?'));

      // Back to fresh onboarding after irreversible purge
      expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    },
  );
}
