import 'package:flutter/material.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';

class HomeWeekCalendarStrip extends StatelessWidget {
  static const List<String> _weekdayInitials = [
    'L',
    'M',
    'X',
    'J',
    'V',
    'S',
    'D',
  ];

  final CalendarMonthProjectionEntity projection;
  final DateTime referenceToday;
  final ValueChanged<DateTime> onDayTapped;
  final VoidCallback onOpenFullCalendar;

  const HomeWeekCalendarStrip({
    super.key,
    required this.projection,
    required this.referenceToday,
    required this.onDayTapped,
    required this.onOpenFullCalendar,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  CalendarDayProjectionEntity? _findDay(DateTime target) {
    for (final d in projection.days) {
      if (_isSameDay(d.date, target)) {
        return d;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final monday = referenceToday.subtract(
      Duration(days: referenceToday.weekday - 1),
    );
    final weekDates = List<DateTime>.generate(
      7,
      (idx) => DateTime.utc(monday.year, monday.month, monday.day + idx),
    );
    final minTouch = tokens.isHighLegibility ? 56.0 : 48.0;

    return CoraSurfaceCard(
      key: const Key('home_week_calendar_strip'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CALENDARIO RÁPIDO',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: tokens.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                  ),
                  Text(
                    'Tu Semana Actual',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              InkWell(
                key: const Key('home_open_full_calendar_button'),
                onTap: onOpenFullCalendar,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Calendario',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: tokens.accentPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: tokens.accentPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (idx) {
              final date = weekDates[idx];
              final dayProj = _findDay(date);
              final marker = dayProj?.dayMarker ?? CalendarDayMarker.none;
              final isToday = _isSameDay(date, referenceToday);

              Color fill = Colors.transparent;
              Color fg = tokens.textPrimary;
              BoxBorder? border;
              Color dotColor = Colors.transparent;

              switch (marker) {
                case CalendarDayMarker.recordedPeriod:
                  fill = isToday ? tokens.menstrual : Colors.transparent;
                  fg = isToday ? Colors.white : tokens.menstrual;
                  dotColor = isToday ? Colors.white : tokens.menstrual;
                  break;
                case CalendarDayMarker.predictedPeriod:
                  dotColor = tokens.menstrual.withValues(alpha: 0.7);
                  break;
                case CalendarDayMarker.fertileWindow:
                  dotColor = tokens.ovulatory;
                  break;
                case CalendarDayMarker.predictedOvulation:
                  dotColor = tokens.ovulatory;
                  break;
                case CalendarDayMarker.spotting:
                  dotColor = tokens.follicular;
                  break;
                case CalendarDayMarker.none:
                  break;
              }

              if (isToday && marker != CalendarDayMarker.recordedPeriod) {
                fill = tokens.surfaceContainer;
                fg = tokens.primaryDeep;
                border = Border.all(color: tokens.primaryDeep.withValues(alpha: 0.35));
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    key: Key(
                      'home_week_day_${date.year}_${date.month}_${date.day}',
                    ),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onDayTapped(date),
                    child: Container(
                      constraints: BoxConstraints(minHeight: minTouch + 12),
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 2,
                      ),
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(14),
                        border: border,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _weekdayInitials[idx],
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color:
                                      marker == CalendarDayMarker.recordedPeriod &&
                                              isToday
                                          ? Colors.white
                                          : tokens.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: fg,
                              fontWeight:
                                  isToday ? FontWeight.w800 : FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
