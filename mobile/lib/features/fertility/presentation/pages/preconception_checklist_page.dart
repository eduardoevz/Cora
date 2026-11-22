import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/fertility/domain/entities/fertility_chart_entity.dart';
import 'package:mobile/features/fertility/presentation/providers/fertility_providers.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

class PreconceptionChecklistPage extends ConsumerStatefulWidget {
  const PreconceptionChecklistPage({super.key});

  @override
  ConsumerState<PreconceptionChecklistPage> createState() =>
      _PreconceptionChecklistPageState();
}

class _PreconceptionChecklistPageState
    extends ConsumerState<PreconceptionChecklistPage> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeUserProfileProvider);
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final checklistAsync =
        ref.watch(preconceptionChecklistProvider(profile.id));
    final tokens = CoraTheme.tokensOf(context);

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        title: const Text('Checklist Preconcepcional'),
      ),
      body: checklistAsync.when(
        data: (checklist) => _buildChecklistBody(context, checklist),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildChecklistBody(
      BuildContext context, PreconceptionChecklistEntity checklist) {
    final tokens = CoraTheme.tokensOf(context);
    final percentage = checklist.completionPercentage;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        CoraSurfaceCard(
          backgroundColor: tokens.blushInset,
          borderColor: tokens.borderSubtle,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CoraCircularProgressRing(
                    progress: percentage / 100.0,
                    centerLabel: '$percentage%',
                    centerSublabel: 'metas',
                    size: 72,
                    strokeWidth: 6,
                    progressColor: tokens.verified,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progreso de Preparación',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: tokens.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Recomendaciones clínicas clave respaldadas por ACOG y la OMS antes de la concepción.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage / 100.0,
                  minHeight: 8,
                  backgroundColor: tokens.surface,
                  color: tokens.verified,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildChecklistItem(
          context,
          key: const Key('folic_acid_checkbox'),
          title: 'Ácido fólico diario (≥ 400 mcg)',
          subtitle:
              'Iniciado al menos 1 a 3 meses antes de la concepción para prevenir defectos del tubo neural.',
          value: checklist.takingFolicAcid,
          onChanged: (val) => _updateChecklist(
            checklist.copyWith(takingFolicAcid: val ?? false),
          ),
        ),
        _buildChecklistItem(
          context,
          title: 'Consulta médica preconcepcional y análisis de sangre',
          subtitle:
              'Revisión clínica integral, hemograma, glucemia y función tiroidea.',
          value: checklist.medicalCheckupDone,
          onChanged: (val) => _updateChecklist(
            checklist.copyWith(medicalCheckupDone: val ?? false),
          ),
        ),
        _buildChecklistItem(
          context,
          title: 'Inmunidad a la rubéola y vacunas al día',
          subtitle:
              'Verificación de anticuerpos IgG contra rubéola, varicela y hepatitis B.',
          value: checklist.rubellaImmunityChecked,
          onChanged: (val) => _updateChecklist(
            checklist.copyWith(rubellaImmunityChecked: val ?? false),
          ),
        ),
        _buildChecklistItem(
          context,
          title: 'Revisión odontológica y salud periodontal',
          subtitle:
              'La salud bucal previene complicaciones inflamatorias durante el embarazo.',
          value: checklist.dentalCheckupDone,
          onChanged: (val) => _updateChecklist(
            checklist.copyWith(dentalCheckupDone: val ?? false),
          ),
        ),
        _buildChecklistItem(
          context,
          title: 'Cese de hábitos tóxicos (tabaco y alcohol)',
          subtitle:
              'Eliminar alcohol y nicotina optimiza la calidad ovárica y el desarrollo temprano.',
          value: checklist.toxicHabitsStopped,
          onChanged: (val) => _updateChecklist(
            checklist.copyWith(toxicHabitsStopped: val ?? false),
          ),
        ),
        _buildChecklistItem(
          context,
          title: 'Evaluación y planificación de fertilidad en pareja',
          subtitle:
              'Revisión de salud reproductiva mutua, espermiograma o antecedentes familiares.',
          value: checklist.partnerEvaluationPlanned,
          onChanged: (val) => _updateChecklist(
            checklist.copyWith(partnerEvaluationPlanned: val ?? false),
          ),
        ),
        const SizedBox(height: 16),
        CoraSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tiempo de Búsqueda Activa',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Permite a Cora calibrar alertas preventivas según tu edad.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${checklist.activeSeekingMonths} meses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: tokens.accentPrimary,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton.outlined(
                        icon: const Icon(Icons.remove),
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: checklist.activeSeekingMonths > 0
                            ? () => _updateChecklist(
                                  checklist.copyWith(
                                    activeSeekingMonths:
                                        checklist.activeSeekingMonths - 1,
                                  ),
                                )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        icon: const Icon(Icons.add),
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: () => _updateChecklist(
                          checklist.copyWith(
                            activeSeekingMonths:
                                checklist.activeSeekingMonths + 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(
    BuildContext context, {
    Key? key,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CoraSelectableOptionCard(
        key: key,
        title: title,
        subtitle: subtitle,
        badgeLabel: value ? 'Completado' : 'Pendiente',
        badgeVariant: value
            ? CoraStatusPillVariant.softMint
            : CoraStatusPillVariant.blush,
        selected: value,
        isRadio: false,
        onTap: () => onChanged(!value),
      ),
    );
  }

  Future<void> _updateChecklist(PreconceptionChecklistEntity updated) async {
    final repo = ref.read(fertilityRepositoryProvider);
    await repo.savePreconceptionChecklist(updated);
    ref.invalidate(preconceptionChecklistProvider(updated.userId));
    ref.invalidate(fertilityChartDataProvider(updated.userId));
  }
}
