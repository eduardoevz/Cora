import 'package:flutter/material.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/presentation/widgets/menstrual_month_grid.dart';

class CalendarDayDetailPanel extends StatelessWidget {
  final CalendarDayProjectionEntity dayProjection;
  final CalendarDisplayMode displayMode;
  final CycleSymptomEntity? symptomLog;
  final VoidCallback onOpenLogSheet;

  const CalendarDayDetailPanel({
    super.key,
    required this.dayProjection,
    required this.displayMode,
    this.symptomLog,
    required this.onOpenLogSheet,
  });

  String _phaseLabel(String? phase) {
    switch (phase?.toLowerCase()) {
      case 'menstrual':
        return 'Fase Menstrual';
      case 'follicular':
        return 'Fase Folicular';
      case 'ovulatory':
        return 'Fase Ovulatoria';
      case 'luteal':
        return 'Fase Lútea';
      case 'hormonally_managed':
        if (displayMode == CalendarDisplayMode.pregnancyGestational) {
          return 'Modo Gestacional';
        }
        if (displayMode == CalendarDisplayMode.postpartumRecovery) {
          return 'Puerperio y Lactancia';
        }
        return 'Gestión Hormonal';
      default:
        if (displayMode == CalendarDisplayMode.seniorPreventive) {
          return 'Calendario Preventivo';
        }
        return 'Seguimiento Diario';
    }
  }

  String _fertilityTitle(FertilityProbability fertility) {
    switch (fertility) {
      case FertilityProbability.high:
        return 'Probabilidad fértil: Alta';
      case FertilityProbability.medium:
        return 'Probabilidad fértil: Media';
      case FertilityProbability.low:
        return 'Probabilidad fértil: Baja';
      case FertilityProbability.none:
        return 'Guía fisiológica del día';
    }
  }

  String _flowLabel(String flow) {
    switch (flow.toLowerCase()) {
      case 'spotting':
        return 'Manchado';
      case 'light':
        return 'Ligero';
      case 'medium':
        return 'Medio';
      case 'heavy':
        return 'Abundante';
      default:
        return 'Sin sangrado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final d = dayProjection.date;
    final monthName =
        MenstrualMonthGrid.monthNamesEs[(d.month - 1).clamp(0, 11)];
    final formattedDate = '${d.day} de $monthName, ${d.year}';
    final phaseKey = dayProjection.phase ?? 'follicular';

    final effectiveFlow =
        symptomLog?.bleedingFlow ?? dayProjection.bleedingFlow;
    final effectivePain = symptomLog?.pelvicPain ?? dayProjection.pelvicPain;
    final effectiveFatigue = symptomLog?.fatigueLevel;
    final giSymptoms = symptomLog?.giSymptoms ?? const <String>[];
    final notes = symptomLog?.notes;

    final symptomChips = <String>[
      if (effectiveFlow != 'none') 'Sangrado: ${_flowLabel(effectiveFlow)}',
      if (effectivePain != null && effectivePain > 0)
        'Dolor pélvico: $effectivePain/10',
      if (effectiveFatigue != null && effectiveFatigue > 0)
        'Fatiga: $effectiveFatigue/10',
      ...giSymptoms,
    ];

    return CoraSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'DETALLE DEL REGISTRO',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
              ),
              CoraPhasePill(
                phaseKey: phaseKey,
                label: _phaseLabel(dayProjection.phase),
                icon: Icons.spa_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              Text(
                formattedDate,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (dayProjection.dayInCycle != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.surfaceSecondary,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: tokens.borderSubtle),
                  ),
                  child: Text(
                    'Día ${dayProjection.dayInCycle} del ciclo',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            dayProjection.dailySummaryEs,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 14),
          CoraInfoCallout(
            title: _fertilityTitle(dayProjection.fertilityProbability),
            subtitle: dayProjection.phaseEducationEs,
            icon: dayProjection.fertilityProbability ==
                        FertilityProbability.high ||
                    dayProjection.fertilityProbability ==
                        FertilityProbability.medium
                ? Icons.favorite_border_rounded
                : Icons.menu_book_rounded,
            phaseKey: dayProjection.fertilityProbability ==
                        FertilityProbability.high ||
                    dayProjection.fertilityProbability ==
                        FertilityProbability.medium
                ? 'ovulatory'
                : phaseKey,
          ),
          const SizedBox(height: 16),
          Text(
            'SÍNTOMAS Y BIOMARCADORES',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
          ),
          const SizedBox(height: 8),
          if (symptomChips.isEmpty && (notes == null || notes.isEmpty))
            Text(
              'Sin síntomas registrados en esta fecha.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
            )
          else ...[
            if (symptomChips.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: symptomChips
                    .map(
                      (chipText) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surfaceSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: tokens.borderSubtle),
                        ),
                        child: Text(
                          chipText,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tokens.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.canvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Text(
                  notes,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textPrimary,
                      ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          CoraPrimaryActionButton(
            key: const Key('calendar_open_log_sheet_button'),
            label: 'Registrar o modificar este día',
            icon: Icons.edit_calendar_rounded,
            onPressed: onOpenLogSheet,
          ),
        ],
      ),
    );
  }
}
