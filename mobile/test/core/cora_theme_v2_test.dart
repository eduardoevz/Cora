import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';

double _relativeLuminance(Color c) {
  double linearize(double channel) {
    return channel <= 0.03928
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = linearize(c.r);
  final g = linearize(c.g);
  final b = linearize(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color a, Color b) {
  final l1 = _relativeLuminance(a);
  final l2 = _relativeLuminance(b);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('CoraTheme v2 & CoraColorTokens WCAG Calibration', () {
    test('standard theme attaches CoraColorTokens matching DESIGN.md', () {
      final theme = CoraTheme.standard();
      final tokens = theme.extension<CoraColorTokens>();

      expect(tokens, isNotNull);
      expect(tokens!.canvas, const Color(0xFFFBF8F6));
      expect(tokens.surface, const Color(0xFFFFFFFF));
      expect(tokens.surfaceSecondary, const Color(0xFFF4ECE8));
      expect(tokens.textPrimary, const Color(0xFF241A1E));
      expect(tokens.textSecondary, const Color(0xFF67585F));
      expect(tokens.borderSubtle, const Color(0xFFE9DCD6));
      expect(tokens.accentPrimary, const Color(0xFFB33A63));
      expect(tokens.accentSurface, const Color(0xFFFCEBF1));
      expect(tokens.isHighLegibility, isFalse);

      // No pure black in standard mode
      expect(tokens.textPrimary, isNot(const Color(0xFF000000)));
    });

    test('standard theme meets WCAG AA (>= 4.5:1) across text and cycle phases',
        () {
      final tokens = CoraTheme.standard().extension<CoraColorTokens>()!;

      expect(_contrastRatio(tokens.textPrimary, tokens.canvas),
          greaterThanOrEqualTo(10.0));
      expect(_contrastRatio(tokens.textSecondary, tokens.surface),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(tokens.accentPrimary, tokens.surface),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(Colors.white, tokens.accentPrimary),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(Colors.white, tokens.menstrual),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(tokens.menstrual, tokens.menstrualSurface),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(tokens.follicular, tokens.follicularSurface),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(tokens.ovulatory, tokens.ovulatorySurface),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(tokens.luteal, tokens.lutealSurface),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(tokens.hormonal, tokens.hormonalSurface),
          greaterThanOrEqualTo(4.5));
      expect(
          _contrastRatio(tokens.alertPreventive, tokens.alertPreventiveSurface),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(tokens.alertUrgent, tokens.alertUrgentSurface),
          greaterThanOrEqualTo(4.5));
    });

    test('highLegibility theme meets WCAG AAA (>= 7:1) and >= 56dp targets',
        () {
      final theme = CoraTheme.highLegibility();
      final tokens = theme.extension<CoraColorTokens>()!;

      expect(tokens.isHighLegibility, isTrue);
      expect(_contrastRatio(tokens.textPrimary, tokens.canvas),
          greaterThanOrEqualTo(15.0));
      expect(_contrastRatio(tokens.textSecondary, tokens.surface),
          greaterThanOrEqualTo(7.0));
      expect(_contrastRatio(tokens.accentPrimary, tokens.surface),
          greaterThanOrEqualTo(7.0));
      expect(_contrastRatio(tokens.menstrual, tokens.menstrualSurface),
          greaterThanOrEqualTo(7.0));
      expect(_contrastRatio(tokens.follicular, tokens.follicularSurface),
          greaterThanOrEqualTo(7.0));
      expect(_contrastRatio(tokens.ovulatory, tokens.ovulatorySurface),
          greaterThanOrEqualTo(7.0));
      expect(_contrastRatio(tokens.luteal, tokens.lutealSurface),
          greaterThanOrEqualTo(7.0));
      expect(_contrastRatio(tokens.hormonal, tokens.hormonalSurface),
          greaterThanOrEqualTo(7.0));

      final minSize = theme.elevatedButtonTheme.style?.minimumSize
          ?.resolve(<WidgetState>{});
      expect(minSize, isNotNull);
      expect(minSize!.height, greaterThanOrEqualTo(56));
    });

    test('CoraColorTokens supports phaseForKey lookup, copyWith, and lerp', () {
      final std = CoraTheme.standard().extension<CoraColorTokens>()!;
      final high = CoraTheme.highLegibility().extension<CoraColorTokens>()!;

      final menstrual = std.phaseColors('menstrual');
      expect(menstrual.foreground, std.menstrual);
      expect(menstrual.background, std.menstrualSurface);

      final ovulatory = std.phaseColors('ovulatory');
      expect(ovulatory.foreground, std.ovulatory);

      final copied = std.copyWith(canvas: const Color(0xFFFFFFFF));
      expect(copied.canvas, const Color(0xFFFFFFFF));

      final mid = std.lerp(high, 0.5);
      expect(mid.isHighLegibility, isTrue);
    });
  });

  group('Cora v2 Reusable Design Components', () {
    testWidgets(
      'render cleanly in standard mode and under TextScaler 2.0x without overflow',
      (tester) async {
        var actionTapped = false;
        var linkTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: CoraTheme.standard(),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 800),
                textScaler: TextScaler.linear(2.0),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CoraSectionLabel(
                        title: 'Semana 2 del ciclo',
                        actionLabel: 'Calendario',
                        onActionTap: () => linkTapped = true,
                      ),
                      const SizedBox(height: 12),
                      const CoraSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CoraPhasePill(
                              phaseKey: 'follicular',
                              label: 'Fase Folicular',
                              icon: Icons.wb_sunny_outlined,
                            ),
                            SizedBox(height: 12),
                            CoraInfoCallout(
                              title: 'Ventana fértil alta',
                              subtitle: 'Ovulación estimada en 2 días',
                              badgeText: 'Alta prob.',
                              phaseKey: 'ovulatory',
                              icon: Icons.eco_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Expanded(
                            child: CoraMetricTile(
                              label: 'Temp. Basal',
                              value: '36.4 °C',
                              icon: Icons.thermostat_outlined,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: CoraMetricTile(
                              label: 'Descanso',
                              value: '7h 45m',
                              icon: Icons.nightlight_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CoraPrimaryActionButton(
                        key: const Key('cora_primary_cta'),
                        label: 'Registrar biomarcadores de hoy',
                        icon: Icons.add_circle_outline,
                        onPressed: () => actionTapped = true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Semana 2 del ciclo'), findsOneWidget);
        expect(find.text('Fase Folicular'), findsOneWidget);
        expect(find.text('Ventana fértil alta'), findsOneWidget);
        expect(find.text('Alta prob.'), findsOneWidget);
        expect(find.text('36.4 °C'), findsOneWidget);
        expect(find.text('7h 45m'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Calendario'));
        expect(linkTapped, isTrue);

        final ctaFinder = find.byKey(const Key('cora_primary_cta'));
        await tester.ensureVisible(ctaFinder);
        await tester.pumpAndSettle();
        final ctaSize = tester.getSize(ctaFinder);
        expect(ctaSize.height, greaterThanOrEqualTo(48));

        await tester.tap(ctaFinder);
        expect(actionTapped, isTrue);
      },
    );

    testWidgets(
      'CoraPrimaryActionButton enforces >= 56dp target in highLegibility theme',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: CoraTheme.highLegibility(),
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CoraPrimaryActionButton(
                    key: const Key('high_legibility_cta'),
                    label: 'Registrar hoy',
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final size =
            tester.getSize(find.byKey(const Key('high_legibility_cta')));
        expect(size.height, greaterThanOrEqualTo(56));
      },
    );

    testWidgets(
      'CoraPageHeroBanner, CoraEmptyStateCard, CoraAlertBanner, and CoraSegmentedSliderCard render cleanly at 2.0x TextScaler',
      (tester) async {
        var emptyTapped = false;
        var sliderValue = 4.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: CoraTheme.standard(),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 800),
                textScaler: TextScaler.linear(2.0),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CoraPageHeroBanner(
                        eyebrow: 'Módulo clínico',
                        title: 'Bienestar Diario',
                        subtitle:
                            'Seguimiento integral de sueño e hidratación.',
                        badgeLabel: 'Activo',
                        phaseKey: 'follicular',
                        icon: Icons.spa_outlined,
                      ),
                      const SizedBox(height: 12),
                      const CoraAlertBanner(
                        title: 'Patrón preventivo FIGO',
                        description:
                            'Variación detectada en tus últimos ciclos.',
                        recommendation: 'Comenta este registro con tu médica.',
                        isUrgent: false,
                      ),
                      const SizedBox(height: 12),
                      const CoraAlertBanner(
                        title: 'Atención prioritaria',
                        description: 'Contacta a tu línea de apoyo clínico.',
                        isUrgent: true,
                      ),
                      const SizedBox(height: 12),
                      CoraSegmentedSliderCard(
                        title: 'Nivel de energía',
                        value: sliderValue,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        valueLabel: '4/10',
                        onChanged: (v) => sliderValue = v,
                      ),
                      const SizedBox(height: 12),
                      CoraEmptyStateCard(
                        icon: Icons.folder_open_rounded,
                        title: 'Sin estudios aún',
                        subtitle: 'Agrega tu primer resultado clínico.',
                        actionLabel: 'Agregar estudio',
                        onAction: () => emptyTapped = true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Bienestar Diario'), findsOneWidget);
        expect(find.text('Patrón preventivo FIGO'), findsOneWidget);
        expect(find.text('Atención prioritaria'), findsOneWidget);
        expect(find.text('4/10'), findsOneWidget);
        expect(find.text('Sin estudios aún'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text('Agregar estudio'));
        await tester.tap(find.text('Agregar estudio'));
        expect(emptyTapped, isTrue);
      },
    );
  });
}
