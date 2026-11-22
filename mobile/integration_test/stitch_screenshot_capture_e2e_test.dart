import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/auth/presentation/pages/firebase_auth_page.dart';
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

void _clearSnackBars(WidgetTester tester) {
  final scaffolds = find.byType(Scaffold);
  if (scaffolds.evaluate().isNotEmpty) {
    ScaffoldMessenger.maybeOf(tester.element(scaffolds.first))
        ?.clearSnackBars();
  }
}

Future<void> _popToHome(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    _clearSnackBars(tester);
    final scaffolds = find.byType(Scaffold);
    if (scaffolds.evaluate().isEmpty) break;
    final nav = Navigator.maybeOf(tester.element(scaffolds.first));
    if (nav == null || !nav.canPop()) break;
    nav.pop();
    await _settle(tester);
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
  _clearSnackBars(tester);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.byKey(const Key('open_navigation_drawer_button')));
  await _settle(tester);
  final itemFinder = find.byKey(itemKey);
  await tester.ensureVisible(itemFinder);
  await _settle(tester);
  await tester.tap(itemFinder);
  await _settle(tester);
}

Future<void> _switchLifeStage(WidgetTester tester, LifeStage target) async {
  _clearSnackBars(tester);
  await tester.pump(const Duration(milliseconds: 200));
  final switchBtn = find.byKey(const Key('switch_stage_chip_button'));
  await tester.ensureVisible(switchBtn);
  await _settle(tester);
  await tester.tap(switchBtn);
  await _settle(tester);
  await tester.tap(find.byKey(const Key('switch_target_stage_dropdown')));
  await _settle(tester);
  await tester.tap(find.text(target.label).last);
  await _settle(tester);
  await tester.tap(find.byKey(const Key('confirm_stage_switch_button')));
  await _settle(tester);
  _clearSnackBars(tester);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _snap(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await _settle(tester);
  await tester.pump(const Duration(milliseconds: 250));
  await binding.takeScreenshot(name);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Capture full Cora v2 Stitch visual showcase across all 7 stages & modules',
    (tester) async {
      // 01. Welcome / Auth Screen Showcase
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: CoraTheme.standard(),
            home: const FirebaseAuthPage(),
          ),
        ),
      );
      await _settle(tester);
      await binding.convertFlutterSurfaceToImage();
      await _snap(binding, tester, '01_bienvenida_y_acceso');

      // Launch full CoraApp
      await tester.pumpWidget(const ProviderScope(child: CoraApp()));
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

      if (find.text('¿Cómo te llamas?').evaluate().isEmpty) {
        final ctx = tester.element(find.byType(Scaffold).first);
        final container = ProviderScope.containerOf(ctx);
        await container.read(appDatabaseProvider).purgeAllLocalData();
        container.read(activeUserProfileProvider.notifier).state = null;
        await _settle(tester);
      }

      // 02-05. Onboarding 4 Layers
      expect(find.text('¿Cómo te llamas?'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('first_name_input')), 'Valentina');
      await tester.enterText(find.byKey(const Key('last_name_input')), 'Ríos');
      await tester.enterText(find.byKey(const Key('birth_year_input')), '1994');
      await _snap(binding, tester, '02_onboarding_paso1');
      await tester.tap(find.byKey(const Key('next_step_button')));
      await _settle(tester);

      await tester.tap(find.byKey(const Key('intent_cycle_and_symptoms')));
      await tester.tap(find.byKey(const Key('intent_general_wellness')));
      await _snap(binding, tester, '03_onboarding_paso2');
      await tester.tap(find.byKey(const Key('next_step_button')));
      await _settle(tester);

      await _snap(binding, tester, '04_onboarding_paso3');
      final layer3Btn = find.byKey(const Key('layer_three_continue_button'));
      await tester.ensureVisible(layer3Btn);
      await _settle(tester);
      await tester.tap(layer3Btn);
      await _settle(tester);

      await _snap(binding, tester, '05_onboarding_ultimos_periodos');
      final completeBtn = find.byKey(const Key('complete_onboarding_button'));
      await tester.ensureVisible(completeBtn);
      await _settle(tester);
      await tester.tap(completeBtn);
      await _pumpUntilFound(tester, find.text('Hola, Valentina'));

      // 06. Home Principal
      await _snap(binding, tester, '06_inicio_principal');

      // 07. Navigation Drawer
      await tester.tap(find.byKey(const Key('open_navigation_drawer_button')));
      await _snap(binding, tester, '07_menu_lateral_drawer');
      Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      await _settle(tester);

      // 08. Interactive Menstrual Calendar
      final openCalendarBtn =
          find.byKey(const Key('home_open_full_calendar_button'));
      await tester.ensureVisible(openCalendarBtn);
      await _settle(tester);
      await tester.tap(openCalendarBtn);
      await _settle(tester);
      await _snap(binding, tester, '08_calendario_menstrual_interactivo');
      await _popToHome(tester);

      // 09. Cycle Monitor
      final cycleCardBtn = find.byKey(const Key('dashboard_cycle_card'));
      await tester.ensureVisible(cycleCardBtn);
      await _settle(tester);
      await tester.tap(cycleCardBtn);
      await _settle(tester);
      await _snap(binding, tester, '09_monitoreo_del_ciclo');
      await _popToHome(tester);

      // 10. SOP & Endometriosis
      await _openDrawerAndTap(tester, const Key('drawer_item_stage_hub'));
      await _snap(binding, tester, '10_sop_y_endometriosis');
      await _popToHome(tester);

      // 11. Modules a la Carta
      await _openDrawerAndTap(tester, const Key('drawer_item_modules'));
      await _snap(binding, tester, '11_modulos_a_la_carta');
      await _popToHome(tester);

      // 12. Adolescence
      await _switchLifeStage(tester, LifeStage.adolescence);
      await _openDrawerAndTap(tester, const Key('drawer_item_stage_hub'));
      await _snap(binding, tester, '12_adolescencia_mi_primer_periodo');
      await _popToHome(tester);

      // 13-14. Fertility Hub & Preconception Checklist
      await _switchLifeStage(tester, LifeStage.conceptionSearch);
      await _openDrawerAndTap(tester, const Key('drawer_item_stage_hub'));
      await _snap(binding, tester, '13_hub_fertilidad_sintotermica');
      final checklistBtn = find.byTooltip('Checklist Preconcepcional');
      await _pumpUntilFound(tester, checklistBtn);
      await tester.tap(checklistBtn);
      await _settle(tester);
      await _snap(binding, tester, '14_checklist_preconcepcional');
      await _popToHome(tester);

      // 15-18. Pregnancy (Weekly Hub -> Vitals -> Timers -> Birth Plan)
      await _switchLifeStage(tester, LifeStage.pregnancy);
      final pregCard = find.byKey(const Key('dashboard_pregnancy_hub_card'));
      await tester.ensureVisible(pregCard);
      await tester.tap(pregCard);
      await _settle(tester);
      if (find.text('Iniciar Seguimiento de Embarazo').evaluate().isNotEmpty) {
        await tester.tap(find.text('Iniciar Seguimiento de Embarazo'));
        await _settle(tester);
        final okFinder = find.text('OK');
        if (okFinder.evaluate().isNotEmpty) {
          await tester.tap(okFinder.last);
        } else {
          await tester.tap(find.text('ACEPTAR').last);
        }
        await _pumpUntilFound(
            tester, find.text('Signos Vitales y Alertas ACOG'));
      }
      await _snap(binding, tester, '15_embarazo_semana_a_semana');

      final vitalsTile = find.text('Signos Vitales y Alertas ACOG');
      await tester.ensureVisible(vitalsTile);
      await tester.tap(vitalsTile);
      await _settle(tester);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '165');
      await tester.enterText(fields.at(1), '115');
      await _snap(binding, tester, '16_signos_vitales_acog_alerta');
      Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      await _settle(tester);

      final timersTile = find.text('Cronómetro de Contracciones y Patadas');
      await tester.ensureVisible(timersTile);
      await tester.tap(timersTile);
      await _settle(tester);
      await _snap(binding, tester, '17_cronometro_contracciones_patadas');
      Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      await _settle(tester);

      final birthPlanTile = find.text('Plan de Parto y Citas Prenatales');
      await tester.ensureVisible(birthPlanTile);
      await tester.tap(birthPlanTile);
      await _settle(tester);
      await _snap(binding, tester, '18_plan_de_parto_citas');
      await _popToHome(tester);

      // 19-21. Postpartum (Recovery -> Lactation -> EPDS)
      await _switchLifeStage(tester, LifeStage.postpartum);
      await tester.tap(find.widgetWithText(ActionChip, 'Recuperación'));
      await _settle(tester);
      await _snap(binding, tester, '19_recuperacion_posparto');
      await _popToHome(tester);

      await tester.tap(find.widgetWithText(ActionChip, 'Lactancia'));
      await _settle(tester);
      await _snap(binding, tester, '20_lactancia_banco_leche');
      await _popToHome(tester);

      await tester.tap(find.widgetWithText(ActionChip, 'EPDS'));
      await _settle(tester);
      await _snap(binding, tester, '21_tamizaje_emocional_epds');
      await _popToHome(tester);

      // 22-23. Perimenopause & Hot Flashes
      await _switchLifeStage(tester, LifeStage.perimenopause);
      await _openDrawerAndTap(tester, const Key('drawer_item_stage_hub'));
      await _snap(binding, tester, '22_perimenopausia_straw10');
      await tester.tap(find.byKey(const Key('quick_log_hot_flash_button')));
      await _settle(tester);
      await _snap(binding, tester, '23_diario_de_sofocos');
      await _popToHome(tester);

      // 24. Senior Vitality WCAG AAA
      await _switchLifeStage(tester, LifeStage.seniorVitality);
      final seniorCard =
          find.byKey(const Key('dashboard_senior_vitality_card'));
      await tester.ensureVisible(seniorCard);
      await tester.tap(seniorCard);
      await _settle(tester);
      await _snap(binding, tester, '24_plenitud_vitalidad_senior_aaa');
      await _popToHome(tester);

      // 25. Wellness & 26. Pillbox
      await _openDrawerAndTap(tester, const Key('drawer_item_wellness'));
      await _snap(binding, tester, '25_bienestar_diario');
      await _popToHome(tester);

      await _openDrawerAndTap(tester, const Key('drawer_item_treatments'));
      await _snap(binding, tester, '26_pastillero_virtual');
      await _popToHome(tester);

      // 27-29. Medical Folder, Specialists, Doctor-Ready PDF
      await _openDrawerAndTap(tester, const Key('drawer_item_medical_folder'));
      await _snap(binding, tester, '27_carpeta_clinica_digital');
      await tester.tap(find.text('Especialistas & Vacunas'));
      await _settle(tester);
      await _snap(binding, tester, '28_vacunacion_y_especialistas');
      Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      await _settle(tester);
      await tester.tap(find.byKey(const Key('open_doctor_report_button')));
      await _settle(tester);
      await _snap(binding, tester, '29_exportacion_doctor_ready_pdf');
      await _popToHome(tester);

      // 30-31. RAG Assistant & Clinical Library
      await _openDrawerAndTap(tester, const Key('drawer_item_assistant'));
      await _pumpUntilFound(
          tester, find.byKey(const Key('assistant_query_input')));
      await tester.enterText(
        find.byKey(const Key('assistant_query_input')),
        'Tengo sangrado abundante de una toalla por hora desde hace 2 horas',
      );
      await tester.tap(find.byKey(const Key('assistant_send_button')));
      await _pumpUntilFound(tester, find.textContaining('Urgente'));
      await _snap(binding, tester, '30_asistente_clinico_rag');
      await _popToHome(tester);

      await _openDrawerAndTap(tester, const Key('drawer_item_library'));
      await _pumpUntilFound(tester, find.text('Biblioteca Clínica Cora'));
      await _snap(binding, tester, '31_biblioteca_medica');
      await _popToHome(tester);

      // 32-33. Partner Mode & Companion View
      await _openDrawerAndTap(tester, const Key('drawer_item_partner'));
      await _snap(binding, tester, '32_modo_acompanante');
      final companionBtn = find.byKey(const Key('open_companion_view_button'));
      await tester.scrollUntilVisible(
        companionBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(companionBtn);
      await _pumpUntilFound(tester, find.text('Solo Lectura'));
      await _snap(binding, tester, '33_vista_acompanante');
      await _popToHome(tester);

      // 34. Privacy & GDPR
      await _openDrawerAndTap(tester, const Key('drawer_item_privacy'));
      await _snap(binding, tester, '34_privacidad_y_soberania_gdpr');
      await _popToHome(tester);
    },
  );
}
