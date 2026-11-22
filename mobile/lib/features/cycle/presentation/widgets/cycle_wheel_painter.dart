import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile/core/theme/cora_theme.dart';

class CycleWheelPainter extends CustomPainter {
  final int currentDay;
  final int totalDays;
  final String phase;
  final bool isHormonallyManaged;
  final CoraColorTokens tokens;

  CycleWheelPainter({
    required this.currentDay,
    this.totalDays = 28,
    required this.phase,
    this.isHormonallyManaged = false,
    this.tokens = CoraColorTokens.standard,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 14;
    const strokeWidth = 10.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Subtle Stitch tonal background track
    final trackPaint = Paint()
      ..color = tokens.surfaceContainer
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (isHormonallyManaged) {
      basePaint.color = tokens.hormonal;
      canvas.drawCircle(center, radius, basePaint);
    } else {
      final safeTotal = math.max(18, totalDays);
      final menstrualRatio = 5 / safeTotal;
      final follicularRatio = 8 / safeTotal;
      final ovulatoryRatio = 3 / safeTotal;
      final lutealRatio = math.max(2, safeTotal - 16) / safeTotal;

      const startAngle = -math.pi / 2;
      const gap = 0.04;

      final sweep1 = math.max(0.05, 2 * math.pi * menstrualRatio - gap);
      canvas.drawArc(
        rect,
        startAngle,
        sweep1,
        false,
        basePaint..color = tokens.menstrual,
      );

      final sweep2 = math.max(0.05, 2 * math.pi * follicularRatio - gap);
      canvas.drawArc(
        rect,
        startAngle + 2 * math.pi * menstrualRatio,
        sweep2,
        false,
        basePaint..color = tokens.follicular,
      );

      final sweep3 = math.max(0.05, 2 * math.pi * ovulatoryRatio - gap);
      canvas.drawArc(
        rect,
        startAngle + 2 * math.pi * (menstrualRatio + follicularRatio),
        sweep3,
        false,
        basePaint..color = tokens.ovulatory,
      );

      final sweep4 = math.max(0.05, 2 * math.pi * lutealRatio - gap);
      canvas.drawArc(
        rect,
        startAngle +
            2 * math.pi * (menstrualRatio + follicularRatio + ovulatoryRatio),
        sweep4,
        false,
        basePaint..color = tokens.luteal.withValues(alpha: 0.45),
      );

      // Stitch dotted fertile/horizon tick ring inside the arc
      final dotTickPaint = Paint()
        ..color = tokens.primaryDeep.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      for (var d = 0; d < safeTotal; d++) {
        final tickAngle = startAngle + (2 * math.pi * d / safeTotal);
        final tx = center.dx + (radius - 13) * math.cos(tickAngle);
        final ty = center.dy + (radius - 13) * math.sin(tickAngle);
        canvas.drawCircle(Offset(tx, ty), 1.6, dotTickPaint);
      }
    }

    // Current day glowing indicator dot
    final progress = (currentDay.clamp(1, totalDays) - 1) / totalDays;
    final angle = -math.pi / 2 + 2 * math.pi * progress;
    final dotX = center.dx + radius * math.cos(angle);
    final dotY = center.dy + radius * math.sin(angle);

    final dotPaint = Paint()
      ..color = tokens.surface
      ..style = PaintingStyle.fill;
    final borderDotPaint = Paint()
      ..color = tokens.primaryDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;

    canvas.drawCircle(Offset(dotX, dotY), 7.5, dotPaint);
    canvas.drawCircle(Offset(dotX, dotY), 7.5, borderDotPaint);
  }

  @override
  bool shouldRepaint(covariant CycleWheelPainter oldDelegate) {
    return oldDelegate.currentDay != currentDay ||
        oldDelegate.totalDays != totalDays ||
        oldDelegate.phase != phase ||
        oldDelegate.isHormonallyManaged != isHormonallyManaged ||
        oldDelegate.tokens != tokens;
  }
}
