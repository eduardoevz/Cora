import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/presentation/providers/menstrual_calendar_providers.dart';
import 'package:mobile/features/cycle/presentation/widgets/menstrual_month_grid.dart';

class CalendarDayLogSheet extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final CycleSymptomEntity? initialSymptomLog;

  const CalendarDayLogSheet({
    super.key,
    required this.selectedDate,
    this.initialSymptomLog,
  });

  @override
  ConsumerState<CalendarDayLogSheet> createState() =>
      _CalendarDayLogSheetState();
}

class _CalendarDayLogSheetState extends ConsumerState<CalendarDayLogSheet> {
  static const List<(String, String)> _flowOptions = [
    ('none', 'Sin sangrado'),
    ('spotting', 'Manchado'),
    ('light', 'Ligero'),
    ('medium', 'Medio'),
    ('heavy', 'Abundante'),
  ];

  static const List<String> _companionSymptoms = [
    'Hinchazón',
    'Cólicos',
    'Sensibilidad mamaria',
    'Cefalea',
  ];

  late String _flow;
  late int _pain;
  late int _fatigue;
  late Set<String> _selectedGi;
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final log = widget.initialSymptomLog;
    _flow = log?.bleedingFlow ?? 'none';
    _pain = log?.pelvicPain ?? 0;
    _fatigue = log?.fatigueLevel ?? 0;
    _selectedGi = {...(log?.giSymptoms ?? const <String>[])};
    _notesController = TextEditingController(text: log?.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final controller = ref.read(menstrualCalendarControllerProvider);
      await controller.saveDayLog(
        date: widget.selectedDate,
        bleedingFlow: _flow,
        pelvicPain: _pain > 0 ? _pain : null,
        fatigueLevel: _fatigue > 0 ? _fatigue : null,
        giSymptoms: _selectedGi.toList(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final d = widget.selectedDate;
    final monthName =
        MenstrualMonthGrid.monthNamesEs[(d.month - 1).clamp(0, 11)];
    final minTouch = tokens.isHighLegibility ? 56.0 : 48.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Registro del ${d.day} de $monthName',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  constraints: BoxConstraints(
                    minWidth: minTouch,
                    minHeight: minTouch,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: tokens.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Flujo o sangrado',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _flowOptions.map((opt) {
                final code = opt.$1;
                final label = opt.$2;
                final selected = _flow == code;
                return ChoiceChip(
                  key: Key('log_flow_$code'),
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setState(() => _flow = code),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _NumericStepperRow(
              label: 'Dolor pélvico o cólicos (0–10)',
              value: _pain,
              minusKey: const Key('log_pain_minus'),
              valueKey: const Key('log_pain_value'),
              plusKey: const Key('log_pain_plus'),
              minTouchSize: minTouch,
              onDecrement: () =>
                  setState(() => _pain = (_pain - 1).clamp(0, 10)),
              onIncrement: () =>
                  setState(() => _pain = (_pain + 1).clamp(0, 10)),
            ),
            const SizedBox(height: 12),
            _NumericStepperRow(
              label: 'Fatiga o cansancio (0–10)',
              value: _fatigue,
              minusKey: const Key('log_fatigue_minus'),
              valueKey: const Key('log_fatigue_value'),
              plusKey: const Key('log_fatigue_plus'),
              minTouchSize: minTouch,
              onDecrement: () =>
                  setState(() => _fatigue = (_fatigue - 1).clamp(0, 10)),
              onIncrement: () =>
                  setState(() => _fatigue = (_fatigue + 1).clamp(0, 10)),
            ),
            const SizedBox(height: 16),
            Text(
              'Síntomas acompañantes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _companionSymptoms.map((symptom) {
                final isSelected = _selectedGi.contains(symptom);
                return FilterChip(
                  key: Key('log_gi_$symptom'),
                  label: Text(symptom),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedGi.add(symptom);
                      } else {
                        _selectedGi.remove(symptom);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('log_notes_input'),
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Nota clínica o síntoma adicional',
              ),
            ),
            const SizedBox(height: 18),
            CoraPrimaryActionButton(
              key: const Key('log_save_button'),
              label: 'Guardar registro del día',
              icon: Icons.check_rounded,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _NumericStepperRow extends StatelessWidget {
  final String label;
  final int value;
  final Key minusKey;
  final Key valueKey;
  final Key plusKey;
  final double minTouchSize;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _NumericStepperRow({
    required this.label,
    required this.value,
    required this.minusKey,
    required this.valueKey,
    required this.plusKey,
    required this.minTouchSize,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.outlined(
              key: minusKey,
              tooltip: 'Disminuir',
              constraints: BoxConstraints(
                minWidth: minTouchSize,
                minHeight: minTouchSize,
              ),
              onPressed: value > 0 ? onDecrement : null,
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 10),
            Text(
              '$value/10',
              key: valueKey,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tokens.accentPrimary,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 10),
            IconButton.outlined(
              key: plusKey,
              tooltip: 'Aumentar',
              constraints: BoxConstraints(
                minWidth: minTouchSize,
                minHeight: minTouchSize,
              ),
              onPressed: value < 10 ? onIncrement : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
