import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/security/biometric_lock_service.dart';
import 'package:mobile/core/security/discreet_app_icon_service.dart';
import 'package:mobile/features/partner/presentation/pages/partner_companion_view_page.dart';
import 'package:mobile/features/partner/presentation/pages/partner_sharing_settings_page.dart';
import 'package:mobile/features/privacy/presentation/pages/privacy_and_data_sovereignty_page.dart';

void main() {
  group('PartnerSharingSettingsPage', () {
    testWidgets('allows toggling permissions and revoking active link', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool? updatedFertility;
      bool? updatedPregnancy;
      bool? updatedMood;
      bool revokeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: PartnerSharingSettingsPage(
            initialInvitationCode: 'CORA-XYZ123',
            initialScopeFertility: false,
            initialScopePregnancy: false,
            initialScopeMood: false,
            onPermissionsChanged: (fertility, pregnancy, mood) {
              updatedFertility = fertility;
              updatedPregnancy = pregnancy;
              updatedMood = mood;
            },
            onRevokeLink: () async {
              revokeCalled = true;
            },
          ),
        ),
      );

      // Verify code display
      expect(find.byKey(const Key('active_invitation_code_display')), findsOneWidget);
      expect(find.text('CORA-XYZ123'), findsOneWidget);

      final fertilitySwitch = find.byKey(const Key('switch_share_fertility'));
      final pregnancySwitch = find.byKey(const Key('switch_share_pregnancy'));
      final moodSwitch = find.byKey(const Key('switch_share_mood'));

      await tester.ensureVisible(fertilitySwitch);
      expect(fertilitySwitch, findsOneWidget);
      await tester.ensureVisible(pregnancySwitch);
      expect(pregnancySwitch, findsOneWidget);
      await tester.ensureVisible(moodSwitch);
      expect(moodSwitch, findsOneWidget);

      // Verify initial switch values are false
      expect(tester.widget<SwitchListTile>(fertilitySwitch).value, isFalse);
      expect(tester.widget<SwitchListTile>(pregnancySwitch).value, isFalse);
      expect(tester.widget<SwitchListTile>(moodSwitch).value, isFalse);

      // Toggle fertility switch
      await tester.tap(fertilitySwitch);
      await tester.pumpAndSettle();
      expect(updatedFertility, isTrue);
      expect(updatedPregnancy, isFalse);
      expect(updatedMood, isFalse);

      // Revoke link
      final revokeButton = find.byKey(const Key('revoke_partner_link_button'));
      await tester.ensureVisible(revokeButton);
      await tester.tap(revokeButton);
      await tester.pumpAndSettle();
      expect(revokeCalled, isTrue);
    });

    testWidgets('allows generating invitation when button is pressed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PartnerSharingSettingsPage(
            onGenerateCode: () async => 'CORA-NEW999',
          ),
        ),
      );

      expect(find.byKey(const Key('generate_invitation_code_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('generate_invitation_code_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('active_invitation_code_display')), findsOneWidget);
      expect(find.text('CORA-NEW999'), findsOneWidget);
    });
  });

  group('PartnerCompanionViewPage', () {
    testWidgets('shows read-only badge and projected cards when authorized', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PartnerCompanionViewPage(
            projection: PartnerCompanionProjection(
              sharingUserName: 'Ana',
              isLinkActive: true,
              pregnancyMilestone: 'Semana 24: El bebé puede percibir sonidos.',
              fertilityWindowSummary: 'Ventana fértil estimada: Días 12 a 16.',
              moodAndSupportTip: 'Días con sensibilidad emocional alta; una caminata tranquila ayuda.',
            ),
          ),
        ),
      );

      expect(find.text('Acompañando a Ana'), findsOneWidget);
      expect(find.text('Solo Lectura'), findsOneWidget);
      expect(find.byKey(const Key('card_pregnancy_milestone')), findsOneWidget);
      expect(find.byKey(const Key('card_fertility_window')), findsOneWidget);
      expect(find.byKey(const Key('card_mood_tip')), findsOneWidget);
      expect(find.text('Semana 24: El bebé puede percibir sonidos.'), findsOneWidget);
    });

    testWidgets('shows empty notice when link is active but no scopes are shared', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PartnerCompanionViewPage(
            projection: PartnerCompanionProjection(
              sharingUserName: 'Ana',
              isLinkActive: true,
              pregnancyMilestone: null,
              fertilityWindowSummary: null,
              moodAndSupportTip: null,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('partner_empty_shared_notice')), findsOneWidget);
      expect(find.text('Sin información compartida por ahora'), findsOneWidget);
    });

    testWidgets('shows inactive notice when link is paused or revoked', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PartnerCompanionViewPage(
            projection: PartnerCompanionProjection(
              sharingUserName: 'Ana',
              isLinkActive: false,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('partner_inactive_notice')), findsOneWidget);
      expect(find.text('Enlace en pausa o revocado'), findsOneWidget);
    });
  });

  group('PrivacyAndDataSovereigntyPage', () {
    testWidgets('enforces strict phrase confirmation for account purge', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? purgedPhrase;

      final lockService = BiometricLockService();
      final iconService = DiscreetAppIconService();

      await tester.pumpWidget(
        MaterialApp(
          home: PrivacyAndDataSovereigntyPage(
            biometricService: lockService,
            iconService: iconService,
            onPurgeAccount: (phrase) async {
              purgedPhrase = phrase;
            },
          ),
        ),
      );

      // Open purge dialog
      final openDialogBtn = find.byKey(const Key('open_purge_dialog_button'));
      await tester.ensureVisible(openDialogBtn);
      await tester.tap(openDialogBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('purge_confirmation_dialog')), findsOneWidget);

      final confirmButtonFinder = find.byKey(const Key('purge_confirm_button'));
      // Initially disabled
      final initialButton = tester.widget<ElevatedButton>(confirmButtonFinder);
      expect(initialButton.onPressed, isNull);

      // Enter incorrect phrase
      final phraseField = find.byKey(const Key('purge_phrase_field'));
      await tester.enterText(phraseField, 'borrar cuenta');
      await tester.pumpAndSettle();

      final partialButton = tester.widget<ElevatedButton>(confirmButtonFinder);
      expect(partialButton.onPressed, isNull);

      // Enter exact phrase
      await tester.enterText(phraseField, 'ELIMINAR MI CUENTA CORA');
      await tester.pumpAndSettle();

      final enabledButton = tester.widget<ElevatedButton>(confirmButtonFinder);
      expect(enabledButton.onPressed, isNotNull);

      // Click confirm
      await tester.tap(confirmButtonFinder);
      await tester.pumpAndSettle();

      expect(purgedPhrase, equals('ELIMINAR MI CUENTA CORA'));
      expect(find.byKey(const Key('purge_success_snackbar')), findsOneWidget);
    });
  });
}
