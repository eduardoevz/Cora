import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/main.dart';

Future<void> _settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  } catch (_) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxSteps = 40,
}) async {
  for (var i = 0; i < maxSteps; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 300));
      return;
    }
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _openDrawerAndTap(WidgetTester tester, Key itemKey) async {
  await tester.tap(find.byKey(const Key('open_navigation_drawer_button')));
  await _settle(tester);
  final itemFinder = find.byKey(itemKey);
  await tester.ensureVisible(itemFinder);
  await _settle(tester);
  await tester.tap(itemFinder);
  await _settle(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Full Cora v2.0 E2E flow on Android device: Onboarding (2 periods) -> Clean Home -> Interactive Calendar -> Navigation Drawer -> Stage Switch -> GDPR Purge',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: CoraApp(),
        ),
      );
      await _settle(tester);
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
      await _settle(tester);

      // Clear any residual state from prior runs if profile already existed
      if (find.text('¿Cómo te llamas?').evaluate().isEmpty) {
        final ctx = tester.element(find.byType(Scaffold).first);
        final container = ProviderScope.containerOf(ctx);
        await container.read(appDatabaseProvider).purgeAllLocalData();
        container.read(activeUserProfileProvider.notifier).state = null;
        await _settle(tester);
      }

      // 1. Onboarding Layer 1
      expect(find.text('¿Cómo te llamas?'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('first_name_input')), 'Sofía');
      await tester.enterText(find.byKey(const Key('last_name_input')), 'Vega');
      await tester.enterText(find.byKey(const Key('birth_year_input')), '1994');
      await tester.tap(find.byKey(const Key('next_step_button')));
      await _settle(tester);

      // 2. Onboarding Layer 2
      expect(find.text('¿Qué te gustaría priorizar hoy?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('intent_cycle_and_symptoms')));
      await tester.tap(find.byKey(const Key('intent_general_wellness')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('next_step_button')));
      await _settle(tester);

      // 3. Onboarding Layer 3 -> Layer 4
      expect(find.text('Contexto Clínico Base'), findsOneWidget);
      final layer3Btn = find.byKey(const Key('layer_three_continue_button'));
      await tester.ensureVisible(layer3Btn);
      await _settle(tester);
      await tester.tap(layer3Btn);
      await _settle(tester);

      // 4. Onboarding Layer 4 (Menstrual Baseline) -> Complete
      expect(find.text('Tu Línea Base Menstrual'), findsOneWidget);
      final completeBtn = find.byKey(const Key('complete_onboarding_button'));
      await tester.ensureVisible(completeBtn);
      await _settle(tester);
      await tester.tap(completeBtn);
      await _pumpUntilFound(tester, find.text('Hola, Sofía'));

      // 5. Clean Dynamic Home Dashboard v2
      expect(find.text('Hola, Sofía'), findsOneWidget);
      expect(find.byKey(const Key('home_cycle_hero_card')), findsOneWidget);
      expect(find.byKey(const Key('home_week_calendar_strip')), findsOneWidget);
      expect(
          find.byKey(const Key('home_phase_education_card')), findsOneWidget);

      // 6. Open Interactive Menstrual Calendar from Weekly Strip
      final openCalendarBtn =
          find.byKey(const Key('home_open_full_calendar_button'));
      await tester.ensureVisible(openCalendarBtn);
      await _settle(tester);
      await tester.tap(openCalendarBtn);
      await _settle(tester);
      expect(find.text('Calendario Menstrual'), findsOneWidget);
      expect(find.text('DETALLE DEL REGISTRO'), findsOneWidget);
      await tester.pageBack();
      await _settle(tester);

      // 7. Cycle Monitor flow + Quick Log
      final cycleCardBtn = find.byKey(const Key('dashboard_cycle_card'));
      await tester.ensureVisible(cycleCardBtn);
      await _settle(tester);
      await tester.tap(cycleCardBtn);
      await _settle(tester);
      expect(find.text('Monitoreo del Ciclo'), findsOneWidget);
      await tester.tap(find.text('Registrar Sangrado y Síntomas'));
      await _settle(tester);
      await tester.tap(find.text('Medio'));
      await _settle(tester);
      await tester.tap(find.text('Guardar'));
      await _settle(tester);
      await tester.pageBack();
      await _settle(tester);

      // 8. Wellness Tracker flow via CoraNavigationDrawer
      await _openDrawerAndTap(tester, const Key('drawer_item_wellness'));
      expect(find.text('Bienestar y Hábitos'), findsOneWidget);
      await tester.tap(find.byKey(const Key('save_wellness_button')));
      await _settle(tester);
      await tester.pageBack();
      await _settle(tester);

      // 9. Pillbox & Treatments flow via CoraNavigationDrawer
      await _openDrawerAndTap(tester, const Key('drawer_item_treatments'));
      expect(find.text('Pastillero y Tratamientos'), findsOneWidget);
      await tester.tap(find.byKey(const Key('add_regimen_button')));
      await _settle(tester);
      await tester.enterText(
          find.byKey(const Key('regimen_name_input')), 'Ácido Fólico');
      await tester.tap(find.byKey(const Key('save_new_regimen_button')));
      await _settle(tester);
      expect(find.text('Ácido Fólico'), findsOneWidget);
      await tester.pageBack();
      await _settle(tester);

      // 10. Medical Folder & Doctor-Ready PDF via CoraNavigationDrawer
      await _openDrawerAndTap(tester, const Key('drawer_item_medical_folder'));
      expect(find.text('Carpeta Clínica Digital'), findsOneWidget);
      await tester.tap(find.byKey(const Key('open_doctor_report_button')));
      await _settle(tester);
      expect(find.text('Reporte Doctor-Ready PDF'), findsOneWidget);
      await tester.tap(find.byKey(const Key('doctor_report_generate_button')));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('doctor_report_completed_card')),
      );
      expect(find.byKey(const Key('doctor_report_completed_card')),
          findsOneWidget);
      await tester.pageBack();
      await _settle(tester);
      await tester.pageBack();
      await _settle(tester);

      // 11. Clinical Assistant (Emergency Triage) via CoraNavigationDrawer
      await _openDrawerAndTap(tester, const Key('drawer_item_assistant'));
      await _pumpUntilFound(
          tester, find.byKey(const Key('assistant_query_input')));
      expect(find.text('Asistente Clínico Cora'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('assistant_query_input')),
        'Tengo sangrado abundante de una toalla por hora desde hace 2 horas',
      );
      await tester.tap(find.byKey(const Key('assistant_send_button')));
      await _pumpUntilFound(tester, find.textContaining('Urgente'));
      expect(find.textContaining('Urgente'), findsWidgets);
      await tester.pageBack();
      await _settle(tester);

      // 12. Clinical Library via CoraNavigationDrawer
      await _openDrawerAndTap(tester, const Key('drawer_item_library'));
      await _pumpUntilFound(tester, find.text('Biblioteca Clínica Cora'));
      expect(find.text('Biblioteca Clínica Cora'), findsOneWidget);
      await tester.pageBack();
      await _settle(tester);

      // 13. Partner Sharing via CoraNavigationDrawer
      await _openDrawerAndTap(tester, const Key('drawer_item_partner'));
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
      await _settle(tester);
      await tester.pageBack();
      await _settle(tester);

      // 14. Life Stage Switch -> Pregnancy
      final switchBtn = find.byKey(const Key('switch_stage_chip_button'));
      await tester.ensureVisible(switchBtn);
      await _settle(tester);
      await tester.tap(switchBtn);
      await _settle(tester);
      await tester.tap(find.byKey(const Key('switch_target_stage_dropdown')));
      await _settle(tester);
      await tester.tap(find.text(LifeStage.pregnancy.label).last);
      await _settle(tester);
      await tester.tap(find.byKey(const Key('confirm_stage_switch_button')));
      await _settle(tester);
      expect(find.byKey(const Key('dashboard_pregnancy_hub_card')),
          findsOneWidget);

      // 15. Privacy & GDPR Purge -> Returns to Onboarding
      await tester.tap(find.byKey(const Key('open_privacy_settings_button')));
      await _settle(tester);
      expect(find.text('Privacidad y Soberanía'), findsOneWidget);
      final purgeBtn = find.byKey(const Key('open_purge_dialog_button'));
      await tester.scrollUntilVisible(
        purgeBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
      await _settle(tester);
      await tester.ensureVisible(purgeBtn);
      await _settle(tester);
      await tester.tap(purgeBtn);
      await _settle(tester);
      await tester.enterText(
        find.byKey(const Key('purge_phrase_field')),
        'ELIMINAR MI CUENTA CORA',
      );
      await _settle(tester);
      await tester.tap(find.byKey(const Key('purge_confirm_button')));
      await _pumpUntilFound(tester, find.text('¿Cómo te llamas?'));

      // Back to fresh onboarding after irreversible purge
      expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    },
  );
}
