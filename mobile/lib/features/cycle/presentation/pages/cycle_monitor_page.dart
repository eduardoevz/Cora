import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/presentation/pages/chronic_conditions_tracker_page.dart';
import 'package:mobile/features/cycle/presentation/pages/menstrual_calendar_page.dart';
import 'package:mobile/features/cycle/presentation/providers/cycle_providers.dart';
import 'package:mobile/features/cycle/presentation/providers/menstrual_calendar_providers.dart';
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
    final monthProjectionAsync =
        ref.watch(activeCalendarMonthProjectionProvider);
    final estimatedTotalDays =
        monthProjectionAsync.valueOrNull?.estimatedCycleLengthDays ??
            user.onboardingContext.typicalCycleLengthDays ??
            28;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoreo del Ciclo'),
        actions: [
          IconButton(
            key: const Key('open_menstrual_calendar_button'),
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Calendario Menstrual',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MenstrualCalendarPage(),
                ),
              );
            },
          ),
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
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error al cargar datos del ciclo: $err'),
          ),
        ),
        data: (overview) {
          final status = overview.status;
          final currentDay = status.dayInCycle ?? 1;
          final tokens = CoraTheme.tokensOf(context);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CoraStitchPageHeader(
                  eyebrow: 'FISIOLOGÍA CÍCLICA PERSONALIZADA',
                  title: 'Tu Ciclo y Fases',
                  subtitle:
                      'Rueda de 4 fases, ventana fértil y vigilancia preventiva FIGO.',
                  eyebrowIcon: Icons.donut_large_rounded,
                  trailing: CoraMintStatusPill(
                    label: status.isHormonallyManaged
                        ? 'Gestión Hormonal'
                        : 'Ciclo Activo',
                    variant: CoraStatusPillVariant.mint,
                  ),
                ),
                const SizedBox(height: 16),
                const CoraEditorialImageBanner(
                  assetPath: 'assets/images/cycle_physiology_card.jpg',
                  height: 102,
                  topBadge: 'ALINEACIÓN FISIOLÓGICA',
                  bottomLeftBadge: 'Monitoreo con Validación FIGO',
                ),
                const SizedBox(height: 16),
                // 1. Rueda de 4 Fases
                CoraSurfaceCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 24,
                  child: Column(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 232,
                          height: 232,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(232, 232),
                                painter: CycleWheelPainter(
                                  currentDay: currentDay,
                                  totalDays: estimatedTotalDays,
                                  phase: status.currentPhase,
                                  isHormonallyManaged:
                                      status.isHormonallyManaged,
                                  tokens: tokens,
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
                                      fontWeight: FontWeight.w800,
                                      color: tokens.textPrimary,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  CoraPhasePill(
                                    phaseKey: status.currentPhase,
                                    label:
                                        _formatPhaseName(status.currentPhase),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _phaseChip(
                            context,
                            'Menstrual',
                            status.currentPhase == 'menstrual',
                            tokens,
                          ),
                          _phaseChip(
                            context,
                            'Folicular',
                            status.currentPhase == 'follicular',
                            tokens,
                          ),
                          _phaseChip(
                            context,
                            'Ovulatoria',
                            status.currentPhase == 'ovulatory',
                            tokens,
                          ),
                          _phaseChip(
                            context,
                            'Lútea',
                            status.currentPhase == 'luteal',
                            tokens,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Tarjeta Informativa de Fase y Consejo Diario
                CoraInfoCallout(
                  title: 'Consejo del Día',
                  subtitle:
                      '${status.phaseDescriptionEs}\n${status.dailyTipEs}',
                  phaseKey: status.currentPhase,
                  icon: Icons.lightbulb_outline_rounded,
                ),
                const SizedBox(height: 16),

                // 3. Pronóstico de Próximo Periodo y Ventana Fértil
                if (!status.isHormonallyManaged &&
                    status.predictedNextPeriod != null) ...[
                  CoraSurfaceCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pronósticos Fisiológicos',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: tokens.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Próximo periodo:',
                              style: TextStyle(color: tokens.textSecondary),
                            ),
                            Text(
                              status.predictedNextPeriod!
                                  .toIso8601String()
                                  .split('T')
                                  .first,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: tokens.menstrual,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (status.ovulationDate != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ovulación estimada:',
                                style: TextStyle(color: tokens.textSecondary),
                              ),
                              Text(
                                status.ovulationDate!
                                    .toIso8601String()
                                    .split('T')
                                    .first,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: tokens.ovulatory,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Alertas Preventivas FIGO
                if (overview.alerts.isNotEmpty) ...[
                  Text(
                    'Alertas Preventivas de Patrones',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tokens.alertPreventive,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...overview.alerts.map((alert) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CoraAlertBanner(
                        title: alert.titleEs,
                        description: alert.descriptionEs,
                        recommendation: alert.recommendationEs,
                        isUrgent: false,
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: CoraPrimaryActionButton(
            onPressed: () => _showQuickLogSheet(context, ref, user.id),
            icon: Icons.water_drop_outlined,
            label: 'Registrar Sangrado y Síntomas',
          ),
        ),
      ),
    );
  }

  Widget _phaseChip(
    BuildContext context,
    String label,
    bool active,
    CoraColorTokens tokens,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? tokens.primaryDeep : tokens.blushInset,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? tokens.primaryDeep : tokens.borderSubtle,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: active ? Colors.white : tokens.textSecondary,
              fontWeight: FontWeight.w700,
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
        final tokens = CoraTheme.tokensOf(context);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registro guardado correctamente.'),
            backgroundColor: tokens.ovulatory,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final tokens = CoraTheme.tokensOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: tokens.alertUrgent,
          ),
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
