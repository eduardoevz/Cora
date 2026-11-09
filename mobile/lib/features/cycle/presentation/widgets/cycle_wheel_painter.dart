import 'dart:math' as math;
import 'package:flutter/material.dart';

class CycleWheelPainter extends CustomPainter {
  final int currentDay;
  final int totalDays;
  final String phase;
  final bool isHormonallyManaged;

  CycleWheelPainter({
    required this.currentDay,
    this.totalDays = 28,
    required this.phase,
    this.isHormonallyManaged = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;
    const strokeWidth = 24.0;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (isHormonallyManaged) {
      // Single continuous managed arc
      basePaint.color = const Color(0xFF4FC3F7); // Soft calm blue
      canvas.drawCircle(center, radius, basePaint);
    } else {
      // 4 Biological Phases
      final menstrualRatio = 5 / totalDays;
      final follicularRatio = 8 / totalDays;
      final ovulatoryRatio = 3 / totalDays;
      final lutealRatio = (totalDays - 16) / totalDays;

      const startAngle = -math.pi / 2; // Top 12 o'clock

      // 1. Menstrual phase (Soft rose)
      final sweep1 = 2 * math.pi * menstrualRatio;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep1,
        false,
        basePaint..color = const Color(0xFFE57373),
      );

      // 2. Follicular phase (Soft green)
      final sweep2 = 2 * math.pi * follicularRatio;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + sweep1,
        sweep2,
        false,
        basePaint..color = const Color(0xFF81C784),
      );

      // 3. Ovulatory phase (Warm amber)
      final sweep3 = 2 * math.pi * ovulatoryRatio;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + sweep1 + sweep2,
        sweep3,
        false,
        basePaint..color = const Color(0xFFFFB74D),
      );

      // 4. Luteal phase (Lavender)
      final sweep4 = 2 * math.pi * lutealRatio;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + sweep1 + sweep2 + sweep3,
        sweep4,
        false,
        basePaint..color = const Color(0xFFBA68C8),
      );
    }

    // Needle / Indicator for current day
    final progress = (currentDay.clamp(1, totalDays) - 1) / totalDays;
    final angle = -math.pi / 2 + 2 * math.pi * progress;
    final dotX = center.dx + radius * math.cos(angle);
    final dotY = center.dy + radius * math.sin(angle);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderDotPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset(dotX, dotY), 8, dotPaint);
    canvas.drawCircle(Offset(dotX, dotY), 8, borderDotPaint);
  }

  @override
  bool shouldRepaint(covariant CycleWheelPainter oldDelegate) {
    return oldDelegate.currentDay != currentDay ||
        oldDelegate.totalDays != totalDays ||
        oldDelegate.phase != phase ||
        oldDelegate.isHormonallyManaged != isHormonallyManaged;
  }
}
