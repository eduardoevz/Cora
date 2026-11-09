import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/presentation/pages/chronic_conditions_tracker_page.dart';
import 'package:mobile/features/cycle/presentation/providers/cycle_providers.dart';
import 'package:mobile/features/cycle/presentation/widgets/cycle_wheel_painter.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

class CycleMonitorPage extends ConsumerWidget {
  const CycleMonitorPage({super.key});

  String _formatPhaseName(String phase) {
    switch (phase.toLowerCase()) {
      case 'menstrual':
        return 'Fase Menstrual';
      case 'follicular':
        return 'Fase Folicular';
      case 'ovulatory':
        return 'Fase Ovulatoria';
      case 'luteal':
        return 'Fase Lútea';
      case 'hormonally_managed':
        return 'Gestión Hormonal';
      default:
        return phase;
    }
  }

  void _showQuickLogSheet(BuildContext context, WidgetRef ref, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _QuickLogBottomSheet(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(activeUserProfileProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final overviewAsync = ref.watch(
      cycleOverviewProvider((userId: user.id, referenceDate: null)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoreo del Ciclo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'SOP y Endometriosis',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ChronicConditionsTrackerPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error al cargar datos del ciclo: $err'),
          ),
        ),
        data: (overview) {
          final status = overview.status;
          final currentDay = status.dayInCycle ?? 1;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Rueda de 4 Fases
              Center(
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(240, 240),
                        painter: CycleWheelPainter(
                          currentDay: currentDay,
                          totalDays: 28,
                          phase: status.currentPhase,
                          isHormonallyManaged: status.isHormonallyManaged,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Día $currentDay',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatPhaseName(status.currentPhase),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: const Color(0xFF6366F1),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Tarjeta Informativa de Fase y Consejo Diario
              Card(
                elevation: 0,
                color: const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              color: Color(0xFFEAB308)),
                          const SizedBox(width: 8),
                          Text(
                            'Consejo del Día',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status.phaseDescriptionEs,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status.dailyTipEs,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF475569),
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Pronóstico de Próximo Periodo y Ventana Fértil
              if (!status.isHormonallyManaged &&
                  status.predictedNextPeriod != null) ...[
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pronósticos Fisiológicos',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Próximo periodo:'),
                            Text(
                              status.predictedNextPeriod!
                                  .toIso8601String()
                                  .split('T')
                                  .first,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE11D48)),
                            ),
                          ],
                        ),
                        if (status.ovulationDate != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ovulación estimada:'),
                              Text(
                                status.ovulationDate!
                                    .toIso8601String()
                                    .split('T')
                                    .first,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD97706)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 4. Alertas Preventivas FIGO
              if (overview.alerts.isNotEmpty) ...[
                Text(
                  'Alertas Preventivas de Patrones',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFDC2626),
                      ),
                ),
                const SizedBox(height: 8),
                ...overview.alerts.map((alert) {
                  return Card(
                    color: const Color(0xFFFEF2F2),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  alert.titleEs,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            alert.descriptionEs,
                            style: const TextStyle(
                              color: Color(0xFF7F1D1D),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '💡 ${alert.recommendationEs}',
                            style: const TextStyle(
                              color: Color(0xFF450A0A),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => _showQuickLogSheet(context, ref, user.id),
          icon: const Icon(Icons.water_drop_outlined),
          label: const Text('Registrar Sangrado y Síntomas'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}

class _QuickLogBottomSheet extends ConsumerStatefulWidget {
  final String userId;

  const _QuickLogBottomSheet({required this.userId});

  @override
  ConsumerState<_QuickLogBottomSheet> createState() =>
      _QuickLogBottomSheetState();
}

class _QuickLogBottomSheetState extends ConsumerState<_QuickLogBottomSheet> {
  String _flow = 'none';
  int _pain = 0;
  bool _isSaving = false;

  static const _flowOptions = [
    ('none', 'Sin sangrado'),
    ('spotting', 'Manchado'),
    ('light', 'Ligero'),
    ('medium', 'Medio'),
    ('heavy', 'Abundante'),
  ];

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      final symptom = CycleSymptomEntity(
        id: '',
        userId: widget.userId,
        logDate: DateTime.now(),
        bleedingFlow: _flow,
        pelvicPain: _pain > 0 ? _pain : null,
      );

      final repo = ref.read(cycleRepositoryProvider);
      await repo.logBleedingAndSymptoms(symptom);

      ref.invalidate(cycleOverviewProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro guardado correctamente.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registro Rápido de Ciclo',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Intensidad de Sangrado:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _flowOptions.map((opt) {
              final isSelected = _flow == opt.$1;
              return ChoiceChip(
                label: Text(opt.$2),
                selected: isSelected,
                onSelected: (val) {
                  if (val) setState(() => _flow = opt.$1);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Dolor o cólicos (0-10): $_pain'),
          Slider(
            value: _pain.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '$_pain',
            onChanged: (val) => setState(() => _pain = val.round()),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const CircularProgressIndicator.adaptive()
                  : const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
