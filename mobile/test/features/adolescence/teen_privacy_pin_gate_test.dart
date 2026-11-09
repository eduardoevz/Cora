import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/adolescence/presentation/widgets/teen_privacy_pin_gate.dart';

void main() {
  testWidgets('entering correct PIN triggers onSuccess callback',
      (tester) async {
    bool successCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: TeenPrivacyPinGate(
          onSuccess: () => successCalled = true,
        ),
      ),
    );

    // Default PIN is 1234
    await tester.tap(find.byKey(const Key('pin_key_1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pin_key_2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pin_key_3')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pin_key_4')));
    await tester.pumpAndSettle();

    expect(successCalled, isTrue);
  });

  testWidgets(
      '5 consecutive failed PIN attempts triggers 30s lockout and disables keypad',
      (tester) async {
    bool successCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: TeenPrivacyPinGate(
          onSuccess: () => successCalled = true,
        ),
      ),
    );

    final state = tester.state<TeenPrivacyPinGateState>(
      find.byType(TeenPrivacyPinGate),
    );

    // Enter wrong PIN (9999) 4 times
    for (int attempt = 1; attempt <= 4; attempt++) {
      for (int d = 0; d < 4; d++) {
        await tester.tap(find.byKey(const Key('pin_key_9')));
        await tester.pump();
      }
      expect(state.failedAttempts, attempt);
      expect(state.isLockedOut, isFalse);
    }

    // 5th failed attempt: triggers lockout
    for (int d = 0; d < 4; d++) {
      await tester.tap(find.byKey(const Key('pin_key_9')));
      await tester.pump();
    }

    expect(state.failedAttempts, 5);
    expect(state.isLockedOut, isTrue);
    expect(state.lockoutSecondsRemaining, 30);
    expect(successCalled, isFalse);

    await tester.pump();

    // Verify lockout countdown message displayed
    expect(find.byKey(const Key('lockout_countdown_text')), findsOneWidget);
    expect(find.textContaining('30 segundos'), findsOneWidget);

    // Verify keypad button is disabled
    final btn = tester.widget<OutlinedButton>(
      find.byKey(const Key('pin_key_1')),
    );
    expect(btn.onPressed, isNull);
  });
}
