import 'package:flutter/material.dart';
import 'package:mobile/features/fertility/domain/entities/fertility_chart_entity.dart';

class BbtBiphasicChartWidget extends StatelessWidget {
  final DateTime cycleStartDate;
  final List<DailyFertilityEntity> entries;
  final double? coverlineCelsius;
  final bool showFahrenheit;

  const BbtBiphasicChartWidget({
    super.key,
    required this.cycleStartDate,
    required this.entries,
    this.coverlineCelsius,
    this.showFahrenheit = false,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text(
          'Sin registros de temperatura basal en este ciclo.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Sort entries by logDate
    final sorted = List<DailyFertilityEntity>.from(entries)
      ..sort((a, b) => a.logDate.compareTo(b.logDate));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Curva Térmica Bifásica',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (coverlineCelsius != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    showFahrenheit
                        ? 'Línea base: ${((coverlineCelsius! * 9 / 5) + 32).toStringAsFixed(2)} °F'
                        : 'Línea base: ${coverlineCelsius!.toStringAsFixed(2)} °C',
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: _BbtChartPainter(
                cycleStartDate: cycleStartDate,
                entries: sorted,
                coverlineCelsius: coverlineCelsius,
                showFahrenheit: showFahrenheit,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFFE11D48), 'Basal Válida'),
              const SizedBox(width: 16),
              _buildLegendItem(const Color(0xFF94A3B8), 'Día sin medición',
                  isDashed: true),
              const SizedBox(width: 16),
              _buildLegendItem(const Color(0xFFDC2626), 'Línea base',
                  isCoverline: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label,
      {bool isDashed = false, bool isCoverline = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCoverline)
          Container(
            width: 14,
            height: 2,
            color: color,
          )
        else if (isDashed)
          Container(
            width: 14,
            height: 2,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: color, width: 2)),
            ),
          )
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _BbtChartPainter extends CustomPainter {
  final DateTime cycleStartDate;
  final List<DailyFertilityEntity> entries;
  final double? coverlineCelsius;
  final bool showFahrenheit;

  _BbtChartPainter({
    required this.cycleStartDate,
    required this.entries,
    required this.coverlineCelsius,
    required this.showFahrenheit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    const double leftPadding = 36.0;
    const double bottomPadding = 24.0;
    const double topPadding = 12.0;
    const double rightPadding = 12.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Find min and max cycle day
    final cycleDays = entries
        .map((e) => e.logDate.difference(cycleStartDate).inDays + 1)
        .toList();
    final minDay = cycleDays.reduce((a, b) => a < b ? a : b);
    final maxDay = cycleDays.reduce((a, b) => a > b ? a : b);
    final totalDays = (maxDay - minDay + 1).clamp(7, 35);

    // Min and max temperatures
    final validTemps =
        entries.map((e) => e.bbtCelsius).whereType<double>().toList();
    if (coverlineCelsius != null) {
      validTemps.add(coverlineCelsius!);
    }

    double minTempC = validTemps.isNotEmpty
        ? validTemps.reduce((a, b) => a < b ? a : b) - 0.15
        : 36.0;
    double maxTempC = validTemps.isNotEmpty
        ? validTemps.reduce((a, b) => a > b ? a : b) + 0.15
        : 37.0;

    if (maxTempC - minTempC < 0.6) {
      maxTempC = minTempC + 0.6;
    }

    double toDisplayTemp(double c) =>
        showFahrenheit ? ((c * 9 / 5) + 32) : c;

    double getY(double tempC) {
      final ratio = (tempC - minTempC) / (maxTempC - minTempC);
      return topPadding + chartHeight * (1.0 - ratio.clamp(0.0, 1.0));
    }

    double getX(int day) {
      final ratio = (day - minDay) / (totalDays > 1 ? (totalDays - 1) : 1);
      return leftPadding + chartWidth * ratio.clamp(0.0, 1.0);
    }

    // Grid lines & Y labels
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const ySteps = 4;
    for (int i = 0; i <= ySteps; i++) {
      final temp = minTempC + (maxTempC - minTempC) * (i / ySteps);
      final y = getY(temp);

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      final label = toDisplayTemp(temp).toStringAsFixed(1);
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(leftPadding - textPainter.width - 4, y - 6));
    }

    // Draw Coverline if present
    if (coverlineCelsius != null) {
      final coverlinePaint = Paint()
        ..color = const Color(0xFFEF4444)
        ..strokeWidth = 1.5;

      final yCover = getY(coverlineCelsius!);
      const dashWidth = 5.0;
      const dashSpace = 4.0;
      double startX = leftPadding;
      while (startX < size.width - rightPadding) {
        canvas.drawLine(
          Offset(startX, yCover),
          Offset(startX + dashWidth, yCover),
          coverlinePaint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    // Draw lines between measured points
    final solidLinePaint = Paint()
      ..color = const Color(0xFFE11D48)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final dashedLinePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    DailyFertilityEntity? prevEntry;
    Offset? prevPoint;

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry.bbtCelsius == null) continue;

      final day = entry.logDate.difference(cycleStartDate).inDays + 1;
      final currentPoint = Offset(getX(day), getY(entry.bbtCelsius!));

      if (prevEntry != null && prevPoint != null) {
        final dayDiff =
            entry.logDate.difference(prevEntry.logDate).inDays;

        if (dayDiff == 1) {
          // Consecutive days -> solid continuous curve
          canvas.drawLine(prevPoint, currentPoint, solidLinePaint);
        } else {
          // Gap with missing days -> dashed line to highlight gap
          _drawDashedLine(canvas, prevPoint, currentPoint, dashedLinePaint);
        }
      }

      prevEntry = entry;
      prevPoint = currentPoint;
    }

    // Draw points and indicators
    final normalPointPaint = Paint()
      ..color = const Color(0xFFE11D48)
      ..style = PaintingStyle.fill;

    final disturbedPointPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;

    for (final entry in entries) {
      if (entry.bbtCelsius == null) continue;

      final day = entry.logDate.difference(cycleStartDate).inDays + 1;
      final point = Offset(getX(day), getY(entry.bbtCelsius!));

      // Draw point circle
      canvas.drawCircle(
        point,
        entry.isDisturbed ? 5.0 : 4.0,
        entry.isDisturbed ? disturbedPointPaint : normalPointPaint,
      );

      // White inner ring for disturbed
      if (entry.isDisturbed) {
        canvas.drawCircle(
          point,
          2.5,
          Paint()..color = Colors.white,
        );
      }

      // X-axis Day label
      textPainter.text = TextSpan(
        text: 'D$day',
        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2, size.height - bottomPadding + 4),
      );
    }
  }

  void _drawDashedLine(
      Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashLength = 4.0;
    const dashGap = 3.0;

    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = (dx * dx + dy * dy);
    if (distance <= 0) return;

    final totalLength = distance > 0 ? (p2 - p1).distance : 0.0;
    var currentDist = 0.0;

    while (currentDist < totalLength) {
      final startRatio = currentDist / totalLength;
      final endRatio = ((currentDist + dashLength) / totalLength).clamp(0.0, 1.0);

      final start = Offset(
        p1.dx + dx * startRatio,
        p1.dy + dy * startRatio,
      );
      final end = Offset(
        p1.dx + dx * endRatio,
        p1.dy + dy * endRatio,
      );

      canvas.drawLine(start, end, paint);
      currentDist += dashLength + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _BbtChartPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.coverlineCelsius != coverlineCelsius ||
        oldDelegate.showFahrenheit != showFahrenheit;
  }
}
