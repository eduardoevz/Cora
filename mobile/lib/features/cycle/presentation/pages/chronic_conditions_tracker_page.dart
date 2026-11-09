import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro de síntomas clínicos guardado.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salud Crónica — SOP y Endometriosis'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFFF8FAFC),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.health_and_safety_outlined,
                      color: Color(0xFF6366F1), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Monitorea marcadores inflamatorios y hormonales para '
                      'generar reportes médicos precisos.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Sección Endometriosis
          Text(
            'Marcadores de Dolor Pélvico y Endometriosis',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Dolor pélvico no menstrual (0-10)'),
            subtitle: Slider(
              value: _pelvicPain.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '$_pelvicPain',
              onChanged: (val) => setState(() => _pelvicPain = val.round()),
            ),
            trailing: Text('$_pelvicPain/10',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('Dismenorrea / Cólicos menstruales (0-10)'),
            subtitle: Slider(
              value: _dysmenorrhea.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '$_dysmenorrhea',
              onChanged: (val) => setState(() => _dysmenorrhea = val.round()),
            ),
            trailing: Text('$_dysmenorrhea/10',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Dispareunia (Dolor en relaciones sexuales)'),
            subtitle: const Text('Síntoma relevante en sospecha de endometriosis profunda'),
            value: _dyspareunia,
            onChanged: (val) => setState(() => _dyspareunia = val),
          ),
          const SizedBox(height: 12),
          const Text('Síntomas Gastrointestinales Asociados:'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: _availableGi.map((gi) {
              final isSelected = _selectedGiSymptoms.contains(gi);
              return FilterChip(
                label: Text(gi),
                selected: isSelected,
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
          const Divider(height: 32),
          // Sección SOP
          Text(
            'Marcadores Androgénicos y Metabólicos (SOP)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Severidad de brotes de acné (0-10)'),
            subtitle: Slider(
              value: _acneSeverity.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '$_acneSeverity',
              onChanged: (val) => setState(() => _acneSeverity = val.round()),
            ),
            trailing: Text('$_acneSeverity/10',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Hirsutismo notable (vello facial/corporal)'),
            subtitle: const Text('Signo de hiperandrogenismo clínico'),
            value: _hirsutism,
            onChanged: (val) => setState(() => _hirsutism = val),
          ),
          ListTile(
            title: const Text('Nivel de fatiga o letargo (0-10)'),
            subtitle: Slider(
              value: _fatigueLevel.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '$_fatigueLevel',
              onChanged: (val) => setState(() => _fatigueLevel = val.round()),
            ),
            trailing: Text('$_fatigueLevel/10',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notas para tu especialista',
              hintText: 'Detalles sobre medicamentos, alimentación o síntomas...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const CircularProgressIndicator.adaptive()
                : const Text('Guardar Registro Clínico'),
          ),
        ],
      ),
    );
  }
}
