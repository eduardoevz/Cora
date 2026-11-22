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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Full Cora v2.0 Production Audit E2E: All 7 Life Stages, Clinical Evaluators & Transversal Modules',
    (tester) async {
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

      // 1. 4-Step Onboarding
      debugPrint('E2E STEP: 1. Onboarding');
      expect(find.text('¿Cómo te llamas?'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('first_name_input')), 'Valeria');
      await tester.enterText(find.byKey(const Key('last_name_input')), 'Ríos');
      await tester.enterText(find.byKey(const Key('birth_year_input')), '1992');
      await tester.tap(find.byKey(const Key('next_step_button')));
      await _settle(tester);

      await tester.tap(find.byKey(const Key('intent_cycle_and_symptoms')));
      await tester.tap(find.byKey(const Key('intent_general_wellness')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('next_step_button')));
      await _settle(tester);

      final layer3Btn = find.byKey(const Key('layer_three_continue_button'));
      await tester.ensureVisible(layer3Btn);
      await _settle(tester);
      await tester.tap(layer3Btn);
      await _settle(tester);

      final completeBtn = find.byKey(const Key('complete_onboarding_button'));
      await tester.ensureVisible(completeBtn);
      await _settle(tester);
      await tester.tap(completeBtn);
      await _pumpUntilFound(tester, find.text('Hola, Valeria'));

      // 2. Menstrual Calendar & Cycle Monitor + Quick Log
      debugPrint('E2E STEP: 2. Calendar & Cycle Monitor');
      final openCalendarBtn =
          find.byKey(const Key('home_open_full_calendar_button'));
      await tester.ensureVisible(openCalendarBtn);
      await _settle(tester);
      await tester.tap(openCalendarBtn);
      await _settle(tester);
      expect(find.text('Calendario Menstrual'), findsOneWidget);
      await _popToHome(tester);

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
      await _popToHome(tester);

      // 3. SOP & Endometriosis Tracker + Modules a la Carta
      debugPrint('E2E STEP: 3. SOP/Endometriosis & Modules');
      await _openDrawerAndTap(tester, const Key('drawer_item_stage_hub'));
      expect(find.text('Panel Clínico: SOP & Endometriosis'), findsOneWidget);
      _clearSnackBars(tester);
      await tester.pump(const Duration(milliseconds: 200));
      final saveChronicBtn = find.text('Guardar Registro Clínico');
      await tester.scrollUntilVisible(
        saveChronicBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(saveChronicBtn);
      await _settle(tester);
      await tester.tap(saveChronicBtn);
      await _settle(tester);
      await _popToHome(tester);

      await _openDrawerAndTap(tester, const Key('drawer_item_modules'));
      expect(find.text('Módulos a la Carta'), findsOneWidget);
      await _popToHome(tester);

      // 4. Stage: Adolescence
      debugPrint('E2E STEP: 4. Adolescence');
      await _switchLifeStage(tester, LifeStage.adolescence);
      await _openDrawerAndTap(tester, const Key('drawer_item_stage_hub'));
      expect(find.text('Mi Primer Periodo'), findsOneWidget);
      await _popToHome(tester);

      // 5. Stage: Conception Search + Preconception Checklist
      debugPrint('E2E STEP: 5. Conception Search');
      await _switchLifeStage(tester, LifeStage.conceptionSearch);
      await _openDrawerAndTap(tester, const Key('drawer_item_stage_hub'));
      expect(find.text('Hub de Fertilidad y Concepción'), findsOneWidget);
      final checklistBtn = find.byTooltip('Checklist Preconcepcional');
      await _pumpUntilFound(tester, checklistBtn);
      await tester.tap(checklistBtn);
      await _settle(tester);
      final folicBox = find.byKey(const Key('folic_acid_checkbox'));
      await _pumpUntilFound(tester, folicBox);
      await tester.ensureVisible(folicBox);
      await tester.tap(folicBox);
      await _settle(tester);
      await _popToHome(tester);

      // 6. Stage: Pregnancy (Weekly Hub -> Start Pregnancy -> ACOG Vitals Red Flag -> Timers -> Birth Plan)
      debugPrint('E2E STEP: 6. Pregnancy');
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
      final vitalsTile = find.text('Signos Vitales y Alertas ACOG');
      await tester.ensureVisible(vitalsTile);
      await tester.tap(vitalsTile);
      await _settle(tester);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '165');
      await tester.enterText(fields.at(1), '115');
      await _settle(tester);
      expect(find.textContaining('Preeclampsia'), findsWidgets);
      Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      await _settle(tester);

      final timersTile = find.text('Cronómetro de Contracciones y Patadas');
      await tester.ensureVisible(timersTile);
      await tester.tap(timersTile);
      await _settle(tester);
      expect(find.text('Contracciones y Patadas'), findsOneWidget);
      Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      await _settle(tester);

      final birthPlanTile = find.text('Plan de Parto y Citas Prenatales');
      await tester.ensureVisible(birthPlanTile);
      await tester.tap(birthPlanTile);
      await _settle(tester);
      expect(find.text('Plan de Parto y Citas'), findsOneWidget);
      await _popToHome(tester);

      // 7. Stage: Postpartum (Recovery -> Lactation -> EPDS Item 10 Crisis)
      debugPrint('E2E STEP: 7. Postpartum & EPDS');
      await _switchLifeStage(tester, LifeStage.postpartum);
      await tester.tap(find.widgetWithText(ActionChip, 'Recuperación'));
      await _settle(tester);
      expect(find.text('Recuperación Puerperal'), findsOneWidget);
      await _popToHome(tester);

      await tester.tap(find.widgetWithText(ActionChip, 'Lactancia'));
      await _settle(tester);
      expect(find.text('Lactancia y Banco de Leche'), findsOneWidget);
      await _popToHome(tester);

      await tester.tap(find.widgetWithText(ActionChip, 'EPDS'));
      await _settle(tester);
      expect(find.text('Salud Emocional (EPDS)'), findsOneWidget);
      final item10Option = find.text('A veces').last;
      await tester.scrollUntilVisible(
        item10Option,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(item10Option);
      await _settle(tester);
      expect(find.byKey(const Key('banner_immediate_crisis_support')),
          findsOneWidget);
      await _popToHome(tester);

      // 8. Stage: Perimenopause -> Hot Flash Tracker
      debugPrint('E2E STEP: 8. Perimenopause');
      await _switchLifeStage(tester, LifeStage.perimenopause);
      await _openDrawerAndTap(tester, const Key('drawer_item_stage_hub'));
      expect(find.text('Perimenopausia y Menopausia'), findsOneWidget);
      await tester.tap(find.byKey(const Key('quick_log_hot_flash_button')));
      await _settle(tester);
      expect(find.text('Registrar Sofoco / Sudor'), findsOneWidget);
      await _popToHome(tester);

      // 9. Stage: Senior Vitality (WCAG AAA)
      debugPrint('E2E STEP: 9. Senior Vitality');
      await _switchLifeStage(tester, LifeStage.seniorVitality);
      final seniorCard =
          find.byKey(const Key('dashboard_senior_vitality_card'));
      await tester.ensureVisible(seniorCard);
      await tester.tap(seniorCard);
      await _settle(tester);
      expect(find.text('Plenitud y Vitalidad'), findsOneWidget);
      await _popToHome(tester);

      // 10. Transversal Modules: Wellness, Pillbox, Medical Folder + Specialists + PDF, Assistant, Library, Partner, GDPR Purge
      debugPrint('E2E STEP: 10a. Wellness & Pillbox');
      await _openDrawerAndTap(tester, const Key('drawer_item_wellness'));
      expect(find.text('Bienestar y Hábitos'), findsOneWidget);
      await tester.tap(find.byKey(const Key('save_wellness_button')));
      await _settle(tester);
      await _popToHome(tester);

      await _openDrawerAndTap(tester, const Key('drawer_item_treatments'));
      expect(find.text('Pastillero y Tratamientos'), findsOneWidget);
      await tester.tap(find.byKey(const Key('add_regimen_button')));
      await _settle(tester);
      await tester.enterText(
          find.byKey(const Key('regimen_name_input')), 'Vitamina D3');
      await tester.tap(find.byKey(const Key('save_new_regimen_button')));
      await _settle(tester);
      expect(find.text('Vitamina D3'), findsOneWidget);
      await _popToHome(tester);

      debugPrint('E2E STEP: 10b. Medical Folder, Vaccines & PDF');
      await _openDrawerAndTap(tester, const Key('drawer_item_medical_folder'));
      expect(find.text('Carpeta Clínica Digital'), findsOneWidget);
      await tester.tap(find.text('Especialistas & Vacunas'));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('specialists_tab')));
      await _settle(tester);
      Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      await _settle(tester);
      await tester.tap(find.byKey(const Key('open_doctor_report_button')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('doctor_report_generate_button')));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('doctor_report_completed_card')),
      );
      expect(find.byKey(const Key('doctor_report_completed_card')),
          findsOneWidget);
      await _popToHome(tester);

      debugPrint('E2E STEP: 10c. Assistant RAG & Library');
      await _openDrawerAndTap(tester, const Key('drawer_item_assistant'));
      await _pumpUntilFound(
          tester, find.byKey(const Key('assistant_query_input')));
      await tester.enterText(
        find.byKey(const Key('assistant_query_input')),
        'Tengo sangrado abundante de una toalla por hora desde hace 2 horas',
      );
      await tester.tap(find.byKey(const Key('assistant_send_button')));
      await _pumpUntilFound(tester, find.textContaining('Urgente'));
      expect(find.textContaining('Urgente'), findsWidgets);
      await _popToHome(tester);

      await _openDrawerAndTap(tester, const Key('drawer_item_library'));
      await _pumpUntilFound(tester, find.text('Biblioteca Clínica Cora'));
      expect(find.text('Biblioteca Clínica Cora'), findsOneWidget);
      await _popToHome(tester);

      debugPrint('E2E STEP: 10d. Partner Sharing & GDPR Purge');
      await _openDrawerAndTap(tester, const Key('drawer_item_partner'));
      await tester
          .tap(find.byKey(const Key('generate_invitation_code_button')));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('active_invitation_code_display')),
      );
      final companionBtn = find.byKey(const Key('open_companion_view_button'));
      await tester.scrollUntilVisible(
        companionBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(companionBtn);
      await _pumpUntilFound(tester, find.text('Solo Lectura'));
      expect(find.text('Solo Lectura'), findsOneWidget);
      await _popToHome(tester);

      await _openDrawerAndTap(tester, const Key('drawer_item_privacy'));
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
      expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    },
  );
}
