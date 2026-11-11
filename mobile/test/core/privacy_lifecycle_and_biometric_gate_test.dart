import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/security/biometric_lock_service.dart';
import 'package:mobile/core/security/privacy_lifecycle_gate.dart';

void main() {
  late BiometricLockService lockService;

  setUp(() {
    lockService = BiometricLockService();
  });

  Widget buildTestWidget({required Widget child}) {
    return MaterialApp(
      home: PrivacyLifecycleGate(
        lockService: lockService,
        child: child,
      ),
    );
  }

  testWidgets('renders child initially without shield overlay', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        child: const Scaffold(
          body: Center(child: Text('Secret Clinical Data')),
        ),
      ),
    );

    expect(find.text('Secret Clinical Data'), findsOneWidget);
    expect(find.byKey(const Key('privacy_shield_overlay')), findsNothing);
  });

  testWidgets('shows shield overlay when app lifecycle transitions to paused', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        child: const Scaffold(
          body: Center(child: Text('Secret Clinical Data')),
        ),
      ),
    );

    // Simulate transition to paused (app switcher / background)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('privacy_shield_overlay')), findsOneWidget);
    expect(find.text('Cora — Privacidad Protegida'), findsOneWidget);
  });

  testWidgets('hides shield overlay on resume if biometric is disabled', (tester) async {
    lockService.setBiometricEnabled(false);

    await tester.pumpWidget(
      buildTestWidget(
        child: const Scaffold(
          body: Center(child: Text('Secret Clinical Data')),
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('privacy_shield_overlay')), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('privacy_shield_overlay')), findsNothing);
  });

  testWidgets('requires unlock button on resume if biometric is enabled with immediate timeout', (tester) async {
    lockService.setBiometricEnabled(true);
    lockService.setTimeout(BiometricLockTimeout.immediate);

    await tester.pumpWidget(
      buildTestWidget(
        child: const Scaffold(
          body: Center(child: Text('Secret Clinical Data')),
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('privacy_shield_overlay')), findsOneWidget);

    // Resume keeps shield overlay because authentication is required
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('privacy_shield_overlay')), findsOneWidget);

    // Tap unlock button
    await tester.tap(find.byKey(const Key('privacy_shield_unlock_button')));
    await tester.pumpAndSettle();

    // Shield should be gone
    expect(find.byKey(const Key('privacy_shield_overlay')), findsNothing);
    expect(find.text('Secret Clinical Data'), findsOneWidget);
  });
}
