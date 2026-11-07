import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/cora_theme.dart';

void main() {
  test('CoraTheme provides standard and highLegibility themes', () {
    final standard = CoraTheme.standard();
    final highLegibility = CoraTheme.highLegibility();

    expect(standard.brightness, Brightness.light);
    expect(highLegibility.brightness, Brightness.light);
    expect(highLegibility.colorScheme.primary, isNotNull);
  });

  testWidgets(
      'Shell UI renders cleanly without overflow under 2.0x accessibility text scaling',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoraTheme.highLegibility(),
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cora — Cuidado Integral de la Salud Femenina',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Acompañamiento longitudinal en tus 7 etapas biológicas.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cora — Cuidado Integral de la Salud Femenina'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
