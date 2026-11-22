import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';

class MenstrualMonthGrid extends StatelessWidget {
  static const List<String> monthNamesEs = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const List<String> _weekdayLabels = [
    'L',
    'M',
    'X',
    'J',
    'V',
    'S',
    'D',
  ];

  final CalendarMonthProjectionEntity projection;
  final DateTime selectedDate;
  final DateTime referenceToday;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const MenstrualMonthGrid({
    super.key,
    required this.projection,
    required this.selectedDate,
    required this.referenceToday,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _isNonMenstrualMode =>
      projection.displayMode == CalendarDisplayMode.pregnancyGestational ||
      projection.displayMode == CalendarDisplayMode.seniorPreventive;

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final monthName = monthNamesEs[(projection.month - 1).clamp(0, 11)];
    final firstOfMonth = DateTime.utc(projection.year, projection.month, 1);
    final leadingBlanks = firstOfMonth.weekday - 1;
    final daysInMonth = projection.days.length;
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;
    final minCellHeight = tokens.isHighLegibility ? 56.0 : 48.0;

    return CoraSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                key: const Key('calendar_prev_month_button'),
                tooltip: 'Mes anterior',
                constraints: BoxConstraints(
                  minWidth: minCellHeight,
                  minHeight: minCellHeight,
                ),
                onPressed: onPreviousMonth,
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: tokens.textPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  '$monthName ${projection.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                key: const Key('calendar_next_month_button'),
                tooltip: 'Mes siguiente',
                constraints: BoxConstraints(
                  minWidth: minCellHeight,
                  minHeight: minCellHeight,
                ),
                onPressed: onNextMonth,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (!_isNonMenstrualMode)
                CoraPhasePill(
                  phaseKey: projection.isHormonallyManaged
                      ? 'hormonally_managed'
                      : 'follicular',
                  label: 'Ciclo de ${projection.estimatedCycleLengthDays} días',
                  icon: Icons.autorenew_rounded,
                ),
              if (!_isNonMenstrualMode && projection.currentCycleDay != null)
                CoraPhasePill(
                  phaseKey: projection.currentPhase ?? 'follicular',
                  label: 'Día ${projection.currentCycleDay} del ciclo actual',
                  icon: Icons.today_rounded,
                ),
              if (projection.hasExtendedUncertainty)
                const CoraPhasePill(
                  phaseKey: 'luteal',
                  label: 'Rango flexible',
                  icon: Icons.tune_rounded,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: tokens.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          for (var week = 0; week < totalCells ~/ 7; week++)
            Row(
              children: List.generate(7, (col) {
                final cellIndex = week * 7 + col;
                final dayIndex = cellIndex - leadingBlanks;
                if (dayIndex < 0 || dayIndex >= daysInMonth) {
                  return Expanded(
                    child: SizedBox(height: minCellHeight),
                  );
                }
                final day = projection.days[dayIndex];
                final isSelected = _isSameDay(day.date, selectedDate);
                final isToday = _isSameDay(day.date, referenceToday);
                return Expanded(
                  child: _CalendarDayCell(
                    day: day,
                    isSelected: isSelected,
                    isToday: isToday,
                    minHeight: minCellHeight,
                    onTap: () => onDaySelected(day.date),
                  ),
                );
              }),
            ),
          const SizedBox(height: 12),
          Divider(color: tokens.borderSubtle, height: 1),
          const SizedBox(height: 12),
          const _CalendarLegendWrap(),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final CalendarDayProjectionEntity day;
  final bool isSelected;
  final bool isToday;
  final double minHeight;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.minHeight,
    required this.onTap,
  });

  String _markerSemanticLabel(CalendarDayMarker marker) {
    switch (marker) {
      case CalendarDayMarker.recordedPeriod:
        return 'Periodo registrado';
      case CalendarDayMarker.predictedPeriod:
        return 'Próximo periodo estimado';
      case CalendarDayMarker.fertileWindow:
        return 'Ventana fértil';
      case CalendarDayMarker.predictedOvulation:
        return 'Día estimado de ovulación';
      case CalendarDayMarker.spotting:
        return 'Manchado registrado';
      case CalendarDayMarker.none:
        return 'Día regular';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final d = day.date;
    final dateSuffix = '${d.year}_${d.month}_${d.day}';
    final marker = day.dayMarker;

    Color backgroundColor = Colors.transparent;
    Color textColor = tokens.textPrimary;
    BoxBorder? border;
    var useDashedBorder = false;
    Color dashedColor = tokens.menstrual;
    Widget? badgeMarker;

    switch (marker) {
      case CalendarDayMarker.recordedPeriod:
        backgroundColor = tokens.menstrual;
        textColor = Colors.white;
        badgeMarker = Icon(
          Icons.water_drop_rounded,
          key: Key('marker_recorded_$dateSuffix'),
          size: 9,
          color: Colors.white,
        );
        break;
      case CalendarDayMarker.predictedPeriod:
        backgroundColor = tokens.menstrualSurface;
        textColor = tokens.menstrual;
        useDashedBorder = true;
        dashedColor = tokens.menstrual;
        badgeMarker = SizedBox(
          key: Key('marker_predicted_$dateSuffix'),
          width: 6,
          height: 6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tokens.menstrual, width: 1.4),
            ),
          ),
        );
        break;
      case CalendarDayMarker.fertileWindow:
        backgroundColor = tokens.ovulatorySurface;
        textColor = tokens.ovulatory;
        border = Border.all(
          color: tokens.ovulatory.withValues(
            alpha: tokens.isHighLegibility ? 1.0 : 0.45,
          ),
          width: tokens.isHighLegibility ? 1.8 : 1.2,
        );
        badgeMarker = SizedBox(
          key: Key('marker_fertile_$dateSuffix'),
          width: 6,
          height: 6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.ovulatory,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
        break;
      case CalendarDayMarker.predictedOvulation:
        backgroundColor = tokens.ovulatorySurface;
        textColor = tokens.ovulatory;
        border = Border.all(
          color: tokens.ovulatory,
          width: tokens.isHighLegibility ? 2.4 : 2.0,
        );
        badgeMarker = Container(
          key: Key('marker_ovulation_$dateSuffix'),
          width: 10,
          height: 10,
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: tokens.ovulatory, width: 1.4),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.ovulatory,
            ),
          ),
        );
        break;
      case CalendarDayMarker.spotting:
        backgroundColor = tokens.follicularSurface;
        textColor = tokens.follicular;
        useDashedBorder = true;
        dashedColor = tokens.follicular;
        badgeMarker = Icon(
          Icons.grain_rounded,
          key: Key('marker_spotting_$dateSuffix'),
          size: 9,
          color: tokens.follicular,
        );
        break;
      case CalendarDayMarker.none:
        if (isToday) {
          border = Border.all(
            color: tokens.accentPrimary,
            width: 1.4,
          );
        }
        break;
    }

    if (isSelected) {
      border = Border.all(
        color: marker == CalendarDayMarker.recordedPeriod
            ? tokens.textPrimary
            : tokens.accentPrimary,
        width: 2.2,
      );
    }

    Widget cellBox = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
        border: border,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${d.day}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight:
                  (isSelected || isToday || marker != CalendarDayMarker.none)
                      ? FontWeight.w800
                      : FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badgeMarker != null) badgeMarker,
              if (badgeMarker != null && day.hasLoggedSymptoms)
                const SizedBox(width: 2),
              if (day.hasLoggedSymptoms)
                Container(
                  key: Key('marker_symptom_dot_$dateSuffix'),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: marker == CalendarDayMarker.recordedPeriod
                        ? Colors.white
                        : tokens.accentPrimary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (useDashedBorder) {
      cellBox = CustomPaint(
        foregroundPainter: _DashedRoundedRectPainter(
          color: dashedColor,
          strokeWidth: tokens.isHighLegibility ? 2.0 : 1.4,
          radius: 13,
        ),
        child: cellBox,
      );
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          'Día ${d.day}, ${_markerSemanticLabel(marker)}${day.hasLoggedSymptoms ? ", con síntomas registrados" : ""}',
      child: InkWell(
        key: Key('calendar_day_$dateSuffix'),
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: cellBox,
      ),
    );
  }
}

class _CalendarLegendWrap extends StatelessWidget {
  const _CalendarLegendWrap();

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(
          label: 'Periodo registrado',
          swatch: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: tokens.menstrual,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
        _LegendItem(
          label: 'Predicción',
          swatch: CustomPaint(
            painter: _DashedRoundedRectPainter(
              color: tokens.menstrual,
              strokeWidth: 1.4,
              radius: 5,
            ),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: tokens.menstrualSurface,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
        _LegendItem(
          label: 'Ventana fértil',
          swatch: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: tokens.ovulatorySurface,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: tokens.ovulatory, width: 1.3),
            ),
          ),
        ),
        _LegendItem(
          label: 'Ovulación',
          swatch: Container(
            width: 16,
            height: 16,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: tokens.ovulatorySurface,
              shape: BoxShape.circle,
              border: Border.all(color: tokens.ovulatory, width: 1.8),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.ovulatory,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Widget swatch;

  const _LegendItem({
    required this.label,
    required this.swatch,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  const _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          2.5, 2.5, math.max(0, size.width - 5), math.max(0, size.height - 5)),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    const dashWidth = 4.0;
    const dashSpace = 3.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
