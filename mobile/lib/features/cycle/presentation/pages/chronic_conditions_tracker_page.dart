import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/presentation/providers/cycle_providers.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

class ChronicConditionsTrackerPage extends ConsumerStatefulWidget {
  const ChronicConditionsTrackerPage({super.key});

  @override
  ConsumerState<ChronicConditionsTrackerPage> createState() =>
      _ChronicConditionsTrackerPageState();
}

class _ChronicConditionsTrackerPageState
    extends ConsumerState<ChronicConditionsTrackerPage> {
  int _pelvicPain = 0;
  int _dysmenorrhea = 0;
  bool _dyspareunia = false;
  int _acneSeverity = 0;
  bool _hirsutism = false;
  int _fatigueLevel = 0;
  final Set<String> _selectedGiSymptoms = {};
  final _notesController = TextEditingController();
  bool _isSaving = false;

  static const _availableGi = [
    'Inflamación pélvica',
    'Náuseas',
    'Estreñimiento',
    'Diarrea catamenial',
    'Gases',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(activeUserProfileProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final symptom = CycleSymptomEntity(
        id: '',
        userId: user.id,
        logDate: DateTime.now(),
        bleedingFlow: 'none',
        pelvicPain: _pelvicPain > 0 ? _pelvicPain : null,
        dysmenorrhea: _dysmenorrhea > 0 ? _dysmenorrhea : null,
        dyspareunia: _dyspareunia,
        acneSeverity: _acneSeverity > 0 ? _acneSeverity : null,
        hirsutism: _hirsutism,
        fatigueLevel: _fatigueLevel > 0 ? _fatigueLevel : null,
        giSymptoms: _selectedGiSymptoms.toList(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final repo = ref.read(cycleRepositoryProvider);
      await repo.logBleedingAndSymptoms(symptom);

      ref.invalidate(cycleOverviewProvider);

      if (mounted) {
        final tokens = CoraTheme.tokensOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registro de síntomas clínicos guardado.'),
            backgroundColor: tokens.ovulatory,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final tokens = CoraTheme.tokensOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
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
    final tokens = CoraTheme.tokensOf(context);
    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        title: const Text('Salud Crónica — SOP y Endometriosis'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          const CoraStitchPageHeader(
            eyebrow: 'MODO ALTA SENSIBILIDAD',
            title: 'Panel Clínico: SOP & Endometriosis',
            subtitle:
                'Monitoreo biométrico diario, correlación inflamatoria y modulación endocrina.',
            eyebrowIcon: Icons.health_and_safety_outlined,
          ),
          const SizedBox(height: 14),
          CoraSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado Sistémico Actual',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    CoraBlushInsetBox(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dolor pélvico',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: tokens.textSecondary),
                          ),
                          Text(
                            '$_pelvicPain/10',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: tokens.primaryDeep,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    CoraBlushInsetBox(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dismenorrea',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: tokens.textSecondary),
                          ),
                          Text(
                            '$_dysmenorrhea/10',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: tokens.primaryDeep,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Correlación Temporal 30 Días',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: tokens.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                CoraBiometricTrendChart(
                  values: [
                    2.5,
                    3.0,
                    4.2,
                    3.8,
                    _pelvicPain.toDouble().clamp(0.5, 10.0),
                  ],
                  secondaryValues: [
                    1.8,
                    2.4,
                    3.1,
                    2.9,
                    _dysmenorrhea.toDouble().clamp(0.5, 10.0),
                  ],
                  lineColor: tokens.primaryDeep,
                  secondaryLineColor: tokens.verified,
                  height: 76,
                  startLabel: 'Día 1',
                  midLabel: 'Día 15',
                  endLabel: 'Hoy',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Marcadores de Dolor Pélvico y Endometriosis',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
          ),
          const SizedBox(height: 10),
          CoraSegmentedSliderCard(
            title: 'Dolor pélvico no menstrual (0-10)',
            value: _pelvicPain.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            valueLabel: '$_pelvicPain/10',
            onChanged: (val) => setState(() => _pelvicPain = val.round()),
          ),
          const SizedBox(height: 10),
          CoraSegmentedSliderCard(
            title: 'Dismenorrea / Cólicos menstruales (0-10)',
            value: _dysmenorrhea.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            valueLabel: '$_dysmenorrhea/10',
            onChanged: (val) => setState(() => _dysmenorrhea = val.round()),
          ),
          const SizedBox(height: 10),
          CoraSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SwitchListTile(
              title: const Text('Dispareunia (Dolor en relaciones sexuales)'),
              subtitle: const Text(
                  'Síntoma relevante en sospecha de endometriosis profunda'),
              activeThumbColor: tokens.accentPrimary,
              value: _dyspareunia,
              onChanged: (val) => setState(() => _dyspareunia = val),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Síntomas Gastrointestinales Asociados',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableGi.map((gi) {
              final isSelected = _selectedGiSymptoms.contains(gi);
              return FilterChip(
                label: Text(gi),
                selected: isSelected,
                selectedColor: tokens.accentSurface,
                checkmarkColor: tokens.accentPrimary,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedGiSymptoms.add(gi);
                    } else {
                      _selectedGiSymptoms.remove(gi);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Divider(color: tokens.borderSubtle, height: 1),
          const SizedBox(height: 20),
          Text(
            'Marcadores Androgénicos y Metabólicos (SOP)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
          ),
          const SizedBox(height: 10),
          CoraSegmentedSliderCard(
            title: 'Severidad de brotes de acné (0-10)',
            value: _acneSeverity.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            valueLabel: '$_acneSeverity/10',
            onChanged: (val) => setState(() => _acneSeverity = val.round()),
          ),
          const SizedBox(height: 10),
          CoraSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SwitchListTile(
              title: const Text('Hirsutismo notable (vello facial/corporal)'),
              subtitle: const Text('Signo de hiperandrogenismo clínico'),
              activeThumbColor: tokens.accentPrimary,
              value: _hirsutism,
              onChanged: (val) => setState(() => _hirsutism = val),
            ),
          ),
          const SizedBox(height: 10),
          CoraSegmentedSliderCard(
            title: 'Nivel de fatiga o letargo (0-10)',
            value: _fatigueLevel.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            valueLabel: '$_fatigueLevel/10',
            onChanged: (val) => setState(() => _fatigueLevel = val.round()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notas para tu especialista',
              hintText:
                  'Detalles sobre medicamentos, alimentación o síntomas...',
            ),
          ),
          const SizedBox(height: 20),
          CoraPrimaryActionButton(
            onPressed: _save,
            isLoading: _isSaving,
            icon: Icons.check_rounded,
            label: 'Guardar Registro Clínico',
          ),
        ],
      ),
    );
  }
}
