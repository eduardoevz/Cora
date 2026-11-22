import 'package:flutter/material.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';

enum _PeriodSlot { latest, previous }

class InitialPeriodsCalendarPicker extends StatefulWidget {
  final LifeStage lifeStage;
  final List<DiagnosedCondition> diagnosedConditions;
  final CycleRegularity regularity;
  final int cycleLengthDays;
  final InitialPeriodRangeEntity? latestPeriod;
  final InitialPeriodRangeEntity? previousPeriod;
  final ValueChanged<CycleRegularity> onRegularityChanged;
  final ValueChanged<int> onCycleLengthChanged;
  final ValueChanged<InitialPeriodRangeEntity?> onLatestPeriodChanged;
  final ValueChanged<InitialPeriodRangeEntity?> onPreviousPeriodChanged;
  final DateTime? initialMonth;

  const InitialPeriodsCalendarPicker({
    super.key,
    required this.lifeStage,
    this.diagnosedConditions = const [],
    required this.regularity,
    required this.cycleLengthDays,
    this.latestPeriod,
    this.previousPeriod,
    required this.onRegularityChanged,
    required this.onCycleLengthChanged,
    required this.onLatestPeriodChanged,
    required this.onPreviousPeriodChanged,
    this.initialMonth,
  });

  @override
  State<InitialPeriodsCalendarPicker> createState() =>
      _InitialPeriodsCalendarPickerState();
}

class _InitialPeriodsCalendarPickerState
    extends State<InitialPeriodsCalendarPicker> {
  static const List<String> _monthNames = [
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

  static const List<String> _weekdayHeaders = [
    'L',
    'M',
    'X',
    'J',
    'V',
    'S',
    'D',
  ];

  late DateTime _visibleMonth;
  _PeriodSlot _activeSlot = _PeriodSlot.latest;
  DateTime? _pendingStart;
  String? _validationMessage;

  DateTime _norm(DateTime dt) => DateTime.utc(dt.year, dt.month, dt.day);

  @override
  void initState() {
    super.initState();
    final base =
        widget.initialMonth ?? widget.latestPeriod?.startDate ?? DateTime.now();
    _visibleMonth = DateTime.utc(base.year, base.month, 1);
  }

  void _shiftMonth(int delta) {
    final candidate =
        DateTime.utc(_visibleMonth.year, _visibleMonth.month + delta, 1);
    final now = _norm(DateTime.now());
    final currentMonth = DateTime.utc(now.year, now.month, 1);
    if (candidate.isAfter(currentMonth)) return;
    setState(() {
      _visibleMonth = candidate;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inRange(DateTime day, InitialPeriodRangeEntity? range) {
    if (range == null) return false;
    final nDay = _norm(day);
    final s = _norm(range.startDate);
    final e = _norm(range.endDate);
    return !nDay.isBefore(s) && !nDay.isAfter(e);
  }

  void _onDayTapped(DateTime day) {
    final tapped = _norm(day);
    final today = _norm(DateTime.now());
    if (tapped.isAfter(today)) return;

    setState(() {
      _validationMessage = null;
    });

    if (_pendingStart == null) {
      final newRange = InitialPeriodRangeEntity(
        startDate: tapped,
        endDate: tapped,
      );
      if (!_validateSlotRange(_activeSlot, newRange)) return;
      setState(() {
        _pendingStart = tapped;
      });
      _emitSlot(_activeSlot, newRange);
      return;
    }

    final start = _pendingStart!;
    final delta = tapped.difference(start).inDays;
    if (delta >= 0 && delta <= 14) {
      final completedRange = InitialPeriodRangeEntity(
        startDate: start,
        endDate: tapped,
      );
      if (!_validateSlotRange(_activeSlot, completedRange)) {
        setState(() {
          _pendingStart = null;
        });
        return;
      }
      setState(() {
        _pendingStart = null;
      });
      _emitSlot(_activeSlot, completedRange);
      if (_activeSlot == _PeriodSlot.latest &&
          widget.previousPeriod == null &&
          mounted) {
        setState(() {
          _activeSlot = _PeriodSlot.previous;
        });
      }
    } else {
      final restartedRange = InitialPeriodRangeEntity(
        startDate: tapped,
        endDate: tapped,
      );
      if (!_validateSlotRange(_activeSlot, restartedRange)) return;
      setState(() {
        _pendingStart = tapped;
      });
      _emitSlot(_activeSlot, restartedRange);
    }
  }

  bool _validateSlotRange(
    _PeriodSlot slot,
    InitialPeriodRangeEntity candidate,
  ) {
    final cStart = _norm(candidate.startDate);
    final cEnd = _norm(candidate.endDate);

    if (slot == _PeriodSlot.previous && widget.latestPeriod != null) {
      final latestStart = _norm(widget.latestPeriod!.startDate);
      if (!cEnd.isBefore(latestStart)) {
        setState(() {
          _validationMessage =
              'El periodo anterior debe terminar antes del inicio de tu último periodo.';
          _pendingStart = null;
        });
        return false;
      }
    }

    if (slot == _PeriodSlot.latest && widget.previousPeriod != null) {
      final prevEnd = _norm(widget.previousPeriod!.endDate);
      if (!prevEnd.isBefore(cStart)) {
        setState(() {
          _validationMessage =
              'Tu último periodo debe comenzar después de finalizar el periodo anterior.';
          _pendingStart = null;
        });
        return false;
      }
    }

    return true;
  }

  void _emitSlot(_PeriodSlot slot, InitialPeriodRangeEntity? range) {
    if (slot == _PeriodSlot.latest) {
      widget.onLatestPeriodChanged(range);
      if (range != null && widget.previousPeriod != null) {
        final diff = _norm(range.startDate)
            .difference(_norm(widget.previousPeriod!.startDate))
            .inDays;
        if (diff >= 15 && diff <= 90) {
          widget.onCycleLengthChanged(diff);
        }
      }
    } else {
      widget.onPreviousPeriodChanged(range);
      if (range != null && widget.latestPeriod != null) {
        final diff = _norm(widget.latestPeriod!.startDate)
            .difference(_norm(range.startDate))
            .inDays;
        if (diff >= 15 && diff <= 90) {
          widget.onCycleLengthChanged(diff);
        }
      }
    }
  }

  String _formatShort(InitialPeriodRangeEntity? range) {
    if (range == null) return 'Sin seleccionar';
    final s = range.startDate;
    final e = range.endDate;
    if (_isSameDay(s, e)) {
      return '${s.day}/${s.month}';
    }
    return '${s.day}/${s.month} – ${e.day}/${e.month} (${range.bleedingDurationDays}d)';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final showUncertaintyNote =
        widget.regularity == CycleRegularity.irregular ||
            widget.lifeStage == LifeStage.adolescence ||
            widget.diagnosedConditions.contains(DiagnosedCondition.pcos);

    final now = _norm(DateTime.now());
    final currentMonth = DateTime.utc(now.year, now.month, 1);
    final canGoNext = _visibleMonth.isBefore(currentMonth);

    final daysInMonth =
        DateTime.utc(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final firstWeekday = _visibleMonth.weekday; // 1 = Mon .. 7 = Sun
    final leadingBlanks = firstWeekday - 1;
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SlotSelectorCard(
              key: const Key('slot_latest_period'),
              title: 'Último periodo',
              subtitle: _formatShort(widget.latestPeriod),
              isActive: _activeSlot == _PeriodSlot.latest,
              accentColor: tokens.menstrual,
              surfaceColor: tokens.menstrualSurface,
              onTap: () => setState(() {
                _activeSlot = _PeriodSlot.latest;
                _pendingStart = null;
                _validationMessage = null;
              }),
              onClear: widget.latestPeriod != null
                  ? () => _emitSlot(_PeriodSlot.latest, null)
                  : null,
            ),
            _SlotSelectorCard(
              key: const Key('slot_previous_period'),
              title: 'Periodo anterior',
              subtitle: _formatShort(widget.previousPeriod),
              isActive: _activeSlot == _PeriodSlot.previous,
              accentColor: tokens.accentPrimary,
              surfaceColor: tokens.accentSurface,
              onTap: () => setState(() {
                _activeSlot = _PeriodSlot.previous;
                _pendingStart = null;
                _validationMessage = null;
              }),
              onClear: widget.previousPeriod != null
                  ? () => _emitSlot(_PeriodSlot.previous, null)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        CoraSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const Key('cal_prev_month'),
                    tooltip: 'Mes anterior',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Flexible(
                    child: Text(
                      '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    key: const Key('cal_next_month'),
                    tooltip: 'Mes siguiente',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: canGoNext ? () => _shiftMonth(1) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _activeSlot == _PeriodSlot.latest
                    ? 'Toca el día que comenzó tu último periodo y luego el día en que terminó.'
                    : 'Ahora marca el inicio y fin de tu periodo anterior para calcular tu ciclo.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _weekdayHeaders
                    .map(
                      (label) => Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: tokens.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 6),
              for (var week = 0; week < totalCells ~/ 7; week++)
                Row(
                  children: List.generate(7, (col) {
                    final cellIndex = week * 7 + col;
                    final dayNumber = cellIndex - leadingBlanks + 1;
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const Expanded(child: SizedBox(height: 48));
                    }
                    final dayDate = DateTime.utc(
                      _visibleMonth.year,
                      _visibleMonth.month,
                      dayNumber,
                    );
                    final isFuture = dayDate.isAfter(todayForGrid);
                    final inLatest = _inRange(dayDate, widget.latestPeriod);
                    final inPrev = _inRange(dayDate, widget.previousPeriod);

                    Color? fillColor;
                    Color textColor =
                        isFuture ? Colors.grey.shade400 : tokens.textPrimary;
                    BoxBorder? border;

                    if (inLatest) {
                      fillColor = tokens.menstrualSurface;
                      textColor = tokens.menstrual;
                      border = Border.all(
                        color: tokens.menstrual,
                        width: tokens.isHighLegibility ? 2.0 : 1.3,
                      );
                    } else if (inPrev) {
                      fillColor = tokens.accentSurface;
                      textColor = tokens.accentPrimary;
                      border = Border.all(
                        color: tokens.accentPrimary,
                        width: tokens.isHighLegibility ? 2.0 : 1.3,
                      );
                    } else if (_isSameDay(dayDate, todayForGrid)) {
                      border = Border.all(
                        color: tokens.borderSubtle,
                        width: 1.5,
                      );
                    }

                    return Expanded(
                      child: Semantics(
                        button: true,
                        enabled: !isFuture,
                        selected: inLatest || inPrev,
                        label: 'Día $dayNumber',
                        child: InkWell(
                          key: Key(
                            'cal_day_${dayDate.year}_${dayDate.month}_${dayDate.day}',
                          ),
                          onTap: isFuture ? null : () => _onDayTapped(dayDate),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: fillColor,
                              borderRadius: BorderRadius.circular(12),
                              border: border,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$dayNumber',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: textColor,
                                    fontWeight: (inLatest || inPrev)
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
        if (_validationMessage != null) ...[
          const SizedBox(height: 10),
          CoraInfoCallout(
            title: 'Verifica las fechas',
            subtitle: _validationMessage!,
            icon: Icons.info_outline_rounded,
            phaseKey: 'luteal',
          ),
        ],
        const SizedBox(height: 16),
        Text(
          '¿Cómo suele ser tu ciclo?',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final reg in [
              CycleRegularity.regular,
              CycleRegularity.irregular,
              CycleRegularity.unsure,
            ])
              ChoiceChip(
                key: Key('regularity_${reg.value}'),
                label: Text(reg.label),
                selected: widget.regularity == reg,
                onSelected: (_) => widget.onRegularityChanged(reg),
              ),
          ],
        ),
        const SizedBox(height: 16),
        CoraSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Duración habitual del ciclo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                (widget.latestPeriod != null && widget.previousPeriod != null)
                    ? 'Calculado entre tus últimos 2 periodos (puedes ajustarlo).'
                    : 'Días promedio desde el inicio de un periodo al siguiente.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton.outlined(
                    key: const Key('cycle_len_minus'),
                    tooltip: 'Reducir días del ciclo',
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: widget.cycleLengthDays > 15
                        ? () => widget
                            .onCycleLengthChanged(widget.cycleLengthDays - 1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '${widget.cycleLengthDays} días',
                    key: const Key('cycle_len_value'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: tokens.accentPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  IconButton.outlined(
                    key: const Key('cycle_len_plus'),
                    tooltip: 'Aumentar días del ciclo',
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: widget.cycleLengthDays < 90
                        ? () => widget
                            .onCycleLengthChanged(widget.cycleLengthDays + 1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showUncertaintyNote) ...[
          const SizedBox(height: 12),
          const CoraInfoCallout(
            title: 'Predicciones flexibles activadas',
            subtitle:
                'Tomaremos tus fechas como guía orientativa ampliando los rangos de estimación para respetar la variabilidad fisiológica natural.',
            icon: Icons.auto_awesome_outlined,
            phaseKey: 'ovulatory',
          ),
        ],
      ],
    );
  }

  DateTime get todayForGrid => _norm(DateTime.now());
}

class _SlotSelectorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isActive;
  final Color accentColor;
  final Color surfaceColor;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _SlotSelectorCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.accentColor,
    required this.surfaceColor,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    return Material(
      color: isActive ? surfaceColor : tokens.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 145),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? accentColor : tokens.borderSubtle,
              width: isActive ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Limpiar fechas',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: onClear,
                  icon: Icon(Icons.close_rounded, size: 16, color: accentColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
