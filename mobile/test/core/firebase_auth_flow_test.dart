import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/auth_providers.dart';
import 'package:mobile/core/auth/firebase_auth_service.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/network/cora_api_client.dart';
import 'package:mobile/core/security/discreet_app_icon_service.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/main.dart';

class _FakeCoraAuthService implements ICoraAuthService {
  final _controller = StreamController<CoraAuthUser?>.broadcast();
  CoraAuthUser? _user;
  String? _token;

  @override
  bool get isFirebaseReady => true;

  @override
  CoraAuthUser? get currentUser => _user;

  @override
  Stream<CoraAuthUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async => _token;

  @override
  Future<CoraAuthUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    _user = CoraAuthUser(uid: 'firebase-real-uid-999', email: email);
    _token = 'eyJhbGciOiJSUzI1NiIsImtpZCI6InJlYWwifQ.fake.jwt';
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<CoraAuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _user = CoraAuthUser(uid: 'firebase-real-uid-999', email: email);
    _token = 'eyJhbGciOiJSUzI1NiIsImtpZCI6InJlYWwifQ.fake.jwt';
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {
    _user = null;
    _token = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteCurrentUser() async {
    await signOut();
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  testWidgets(
    'FirebaseAuthPage -> OnboardingWizardPage (real UID) -> DynamicHomeDashboardPage',
    (tester) async {
      final fakeAuth = _FakeCoraAuthService();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async {
        fakeAuth.dispose();
        await db.close();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coraAuthServiceProvider.overrideWithValue(fakeAuth),
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const CoraApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Starts at FirebaseAuthPage because Firebase is ready and user is signed out
      expect(find.byKey(const Key('auth_email_input')), findsOneWidget);
      await tester.tap(find.byKey(const Key('auth_toggle_mode_button')));
      await tester.pumpAndSettle();
      expect(find.text('Crear mi Cuenta Cora'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('auth_email_input')), 'ana@cora.health');
      await tester.enterText(
          find.byKey(const Key('auth_password_input')), 'Secreta123!');
      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pumpAndSettle();

      // Transitions to OnboardingWizardPage
      expect(find.text('¿Cómo te llamas?'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('first_name_input')), 'Ana');
      await tester.enterText(
          find.byKey(const Key('last_name_input')), 'Morales');
      await tester.enterText(find.byKey(const Key('birth_year_input')), '1993');
      await tester.tap(find.byKey(const Key('next_step_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('intent_cycle_and_symptoms')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('next_step_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('layer_three_continue_button')));
      await tester.pumpAndSettle();

      final finishBtn = find.byKey(const Key('complete_onboarding_button'));
      await tester.ensureVisible(finishBtn);
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      expect(find.text('Hola, Ana'), findsOneWidget);

      // Verify persisted profile uses the real Firebase UID (not mock_uid_)
      final container =
          ProviderScope.containerOf(tester.element(find.text('Hola, Ana')));
      final profile = container.read(activeUserProfileProvider);
      expect(profile?.firebaseUid, 'firebase-real-uid-999');
    },
  );

  test('CoraApiClient injects dynamic Bearer token from tokenProvider',
      () async {
    final client = CoraApiClient(
      baseUrl: 'https://example.test/api/v1',
      tokenProvider: () async => 'real.firebase.jwt',
    );
    String? capturedAuthHeader;
    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedAuthHeader = options.headers['Authorization'] as String?;
          return handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: const {}),
          );
        },
      ),
    );
    await client.dio.get('/identity/me');
    expect(capturedAuthHeader, 'Bearer real.firebase.jwt');
  });

  test('DiscreetAppIconService switches all 4 icon aliases cleanly', () {
    final service = DiscreetAppIconService();
    expect(service.currentIcon, DiscreetAppIcon.coraDefault);
    service.switchIcon(DiscreetAppIcon.neutralCalendar);
    expect(service.currentDisplayName, 'Mi Calendario');
    service.switchIcon(DiscreetAppIcon.neutralNotes);
    expect(service.currentDisplayName, 'Mis Notas');
    service.switchIcon(DiscreetAppIcon.pocketCalculator);
    expect(service.currentDisplayName, 'Calculadora');
  });
}
