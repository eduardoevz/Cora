import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
