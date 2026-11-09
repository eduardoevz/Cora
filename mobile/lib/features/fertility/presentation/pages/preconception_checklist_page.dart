import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist Preconcepcional'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
    final theme = Theme.of(context);
    final percentage = checklist.completionPercentage;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Progress Card
        Card(
          elevation: 0,
          color: const Color(0xFFEFF6FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFBFDBFE)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progreso de Preparación',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100.0,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFDBEAFE),
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Recomendaciones clínicas clave respaldadas por ACOG y la OMS antes de la concepción.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Items
        _buildChecklistItem(
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
          title: 'Consulta médica preconcepcional y análisis de sangre',
          subtitle:
              'Revisión clínica integral, hemograma, glucemia y función tiroidea.',
          value: checklist.medicalCheckupDone,
          onChanged: (val) => _updateChecklist(
            checklist.copyWith(medicalCheckupDone: val ?? false),
          ),
        ),
        _buildChecklistItem(
          title: 'Inmunidad a la rubéola y vacunas al día',
          subtitle:
              'Verificación de anticuerpos IgG contra rubéola, varicela y hepatitis B.',
          value: checklist.rubellaImmunityChecked,
          onChanged: (val) => _updateChecklist(
            checklist.copyWith(rubellaImmunityChecked: val ?? false),
          ),
        ),
        _buildChecklistItem(
          title: 'Revisión odontológica y salud periodontal',
          subtitle:
              'La salud bucal previene complicaciones inflamatorias durante el embarazo.',
          value: checklist.dentalCheckupDone,
          onChanged: (val) => _updateChecklist(
            checklist.copyWith(dentalCheckupDone: val ?? false),
          ),
        ),
        _buildChecklistItem(
          title: 'Cese de hábitos tóxicos (tabaco y alcohol)',
          subtitle:
              'Eliminar alcohol y nicotina optimiza la calidad ovárica y el desarrollo temprano.',
          value: checklist.toxicHabitsStopped,
          onChanged: (val) => _updateChecklist(
            checklist.copyWith(toxicHabitsStopped: val ?? false),
          ),
        ),
        _buildChecklistItem(
          title: 'Evaluación y planificación de fertilidad en pareja',
          subtitle:
              'Revisión de salud reproductiva mutua, espermiograma o antecedentes familiares.',
          value: checklist.partnerEvaluationPlanned,
          onChanged: (val) => _updateChecklist(
            checklist.copyWith(partnerEvaluationPlanned: val ?? false),
          ),
        ),

        const SizedBox(height: 16),
        // Active seeking months card
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tiempo de Búsqueda Activa',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Permite a Cora calibrar alertas preventivas según tu edad.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${checklist.activeSeekingMonths} meses',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: checklist.activeSeekingMonths > 0
                              ? () => _updateChecklist(
                                    checklist.copyWith(
                                      activeSeekingMonths:
                                          checklist.activeSeekingMonths - 1,
                                    ),
                                  )
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
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
        ),
      ],
    );
  }

  Widget _buildChecklistItem({
    Key? key,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      key: key,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: value ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            decoration: value ? TextDecoration.none : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
        value: value,
        activeColor: const Color(0xFF16A34A),
        onChanged: onChanged,
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
