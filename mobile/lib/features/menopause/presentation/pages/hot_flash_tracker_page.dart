import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/menopause/domain/models/hot_flash_episode.dart';
import 'package:mobile/features/menopause/presentation/providers/menopause_providers.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:uuid/uuid.dart';

class HotFlashTrackerPage extends ConsumerStatefulWidget {
  const HotFlashTrackerPage({super.key});

  @override
  ConsumerState<HotFlashTrackerPage> createState() =>
      _HotFlashTrackerPageState();
}

class _HotFlashTrackerPageState extends ConsumerState<HotFlashTrackerPage> {
  HotFlashSeverity _severity = HotFlashSeverity.moderate;
  HotFlashType _flashType = HotFlashType.daytime;
  int _durationMinutes = 5;
  int _sleepDisruption = 0;
  bool _associatedWithHrt = false;
  final Set<String> _selectedTriggers = {};
  final TextEditingController _notesController = TextEditingController();

  static const List<String> _availableTriggers = [
    'Cafeína',
    'Estrés',
    'Calor ambiental',
    'Alcohol',
    'Comida picante',
    'Emociones intensas',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveEpisode() async {
    final user = ref.read(activeUserProfileProvider);
    if (user == null) return;

    final episode = HotFlashEpisode(
      id: const Uuid().v4(),
      userId: user.id,
      occurredAt: DateTime.now(),
      severity: _severity,
      flashType: _flashType,
      durationMinutes: _durationMinutes,
      triggers: _selectedTriggers.toList(),
      sleepDisruptionLevel: _sleepDisruption,
      associatedWithHrt: _associatedWithHrt,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    await ref.read(menopauseRepositoryProvider).saveHotFlash(episode);
    ref.invalidate(recentHotFlashesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sofoco registrado correctamente')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Sofoco / Sudor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Momento y Tipo',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<HotFlashType>(
              segments: const [
                ButtonSegment(
                  value: HotFlashType.daytime,
                  label: Text('Diurno'),
                  icon: Icon(Icons.wb_sunny_outlined),
                ),
                ButtonSegment(
                  value: HotFlashType.nightSweats,
                  label: Text('Sudor Nocturno'),
                  icon: Icon(Icons.nightlight_round),
                ),
              ],
              selected: {_flashType},
              onSelectionChanged: (newVal) {
                setState(() => _flashType = newVal.first);
              },
            ),
            if (_flashType == HotFlashType.nightSweats) ...[
              const SizedBox(height: 12),
              Text(
                'Interrupción del sueño: $_sleepDisruption / 3',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _sleepDisruption.toDouble(),
                min: 0,
                max: 3,
                divisions: 3,
                label: '$_sleepDisruption',
                onChanged: (val) =>
                    setState(() => _sleepDisruption = val.round()),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Intensidad',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: HotFlashSeverity.values.map((sev) {
                final isSelected = _severity == sev;
                return ChoiceChip(
                  label: Text(
                    switch (sev) {
                      HotFlashSeverity.mild => '1 Leve',
                      HotFlashSeverity.moderate => '2 Mod',
                      HotFlashSeverity.severe => '3 Severo',
                      HotFlashSeverity.verySevere => '4 Muy Sev',
                    },
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _severity = sev),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Duración estimada: $_durationMinutes min',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _durationMinutes.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              label: '$_durationMinutes min',
              onChanged: (val) =>
                  setState(() => _durationMinutes = val.round()),
            ),
            const SizedBox(height: 12),
            Text(
              'Factores Desencadenantes',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _availableTriggers.map((trigger) {
                final isSelected = _selectedTriggers.contains(trigger);
                return FilterChip(
                  label: Text(trigger),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTriggers.add(trigger);
                      } else {
                        _selectedTriggers.remove(trigger);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Asociado a Terapia Hormonal (TRH)'),
              subtitle: const Text('Bajo esquema de reemplazo activo'),
              value: _associatedWithHrt,
              onChanged: (val) => setState(() => _associatedWithHrt = val),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('save_hot_flash_button'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _saveEpisode,
              icon: const Icon(Icons.check),
              label: const Text('Guardar Registro'),
            ),
          ],
        ),
      ),
    );
  }
}
