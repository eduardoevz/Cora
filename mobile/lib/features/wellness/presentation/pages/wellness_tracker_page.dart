import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/wellness/domain/entities/daily_wellness_entity.dart';
import 'package:mobile/features/wellness/presentation/providers/wellness_providers.dart';

class WellnessTrackerPage extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const WellnessTrackerPage({super.key, this.initialDate});

  @override
  ConsumerState<WellnessTrackerPage> createState() =>
      _WellnessTrackerPageState();
}

class _WellnessTrackerPageState extends ConsumerState<WellnessTrackerPage> {
  late DateTime _selectedDate;
  double _sleepHours = 7.0;
  int _sleepQuality = 3;
  int _energyLevel = 3;
  int _hydrationMl = 1500;
  int _exerciseMinutes = 30;
  final Set<String> _selectedMoods = {};
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  static const List<String> _availableMoods = [
    'calm',
    'energetic',
    'happy',
    'anxious',
    'exhausted',
    'crampy',
    'bloated',
    'stressed',
  ];

  static const Map<String, String> _moodLabels = {
    'calm': 'Calma 🌿',
    'energetic': 'Con energía ⚡',
    'happy': 'Alegre ✨',
    'anxious': 'Ansiosa 🌧️',
    'exhausted': 'Agotada 💤',
    'crampy': 'Cólicos 🩹',
    'bloated': 'Hinchazón 🎈',
    'stressed': 'Estresada 🌪️',
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadExistingLog();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingLog() async {
    final profile = ref.read(activeUserProfileProvider);
    if (profile == null) return;

    final repo = ref.read(wellnessRepositoryProvider);
    final existing =
        await repo.getDailyLog(userId: profile.id, date: _selectedDate);
    if (existing != null && mounted) {
      setState(() {
        if (existing.sleepHours != null) _sleepHours = existing.sleepHours!;
        if (existing.sleepQuality != null) {
          _sleepQuality = existing.sleepQuality!;
        }
        if (existing.energyLevel != null) _energyLevel = existing.energyLevel!;
        if (existing.hydrationMl != null) _hydrationMl = existing.hydrationMl!;
        if (existing.exerciseMinutes != null) {
          _exerciseMinutes = existing.exerciseMinutes!;
        }
        _selectedMoods.clear();
        _selectedMoods.addAll(existing.moodTags);
        if (existing.notes != null) _notesController.text = existing.notes!;
      });
    }
  }

  Future<void> _saveWellness() async {
    final profile = ref.read(activeUserProfileProvider);
    if (profile == null) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(wellnessRepositoryProvider);
      final log = DailyWellnessEntity(
        userId: profile.id,
        logDate: _selectedDate,
        sleepHours: _sleepHours,
        sleepQuality: _sleepQuality,
        energyLevel: _energyLevel,
        hydrationMl: _hydrationMl,
        exerciseMinutes: _exerciseMinutes,
        moodTags: _selectedMoods.toList(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await repo.saveDailyLog(log);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro diario consolidado (Offline-First)'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienestar y Hábitos'),
        actions: [
          IconButton(
            key: const Key('save_wellness_button'),
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            tooltip: 'Guardar registro',
            onPressed: _isLoading ? null : _saveWellness,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Header
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fecha: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Cambiar'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                          await _loadExistingLog();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sleep Section
            _buildSection(
              title: 'Sueño y Descanso',
              icon: Icons.bedtime,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Horas dormidas: ${_sleepHours.toStringAsFixed(1)} h'),
                  Slider(
                    key: const Key('sleep_hours_slider'),
                    value: _sleepHours,
                    min: 0.0,
                    max: 16.0,
                    divisions: 32,
                    label: '${_sleepHours.toStringAsFixed(1)} h',
                    onChanged: (val) => setState(() => _sleepHours = val),
                  ),
                  const SizedBox(height: 8),
                  Text('Calidad del sueño: $_sleepQuality / 5'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        icon: Icon(
                          star <= _sleepQuality
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => setState(() => _sleepQuality = star),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Energy Level
            _buildSection(
              title: 'Nivel de Energía',
              icon: Icons.bolt,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vitalidad percibida: $_energyLevel / 5'),
                  Slider(
                    key: const Key('energy_level_slider'),
                    value: _energyLevel.toDouble(),
                    min: 1.0,
                    max: 5.0,
                    divisions: 4,
                    label: '$_energyLevel',
                    onChanged: (val) =>
                        setState(() => _energyLevel = val.round()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hydration Section
            _buildSection(
              title: 'Hidratación',
              icon: Icons.water_drop,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Agua consumida: $_hydrationMl ml'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ActionChip(
                        label: const Text('+250 ml'),
                        onPressed: () => setState(() => _hydrationMl += 250),
                      ),
                      ActionChip(
                        label: const Text('+500 ml'),
                        onPressed: () => setState(() => _hydrationMl += 500),
                      ),
                      ActionChip(
                        label: const Text('Reiniciar'),
                        onPressed: () => setState(() => _hydrationMl = 0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mood Tags Section
            _buildSection(
              title: 'Estado de Ánimo y Cuerpo',
              icon: Icons.mood,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _availableMoods.map((mood) {
                  final isSelected = _selectedMoods.contains(mood);
                  return FilterChip(
                    label: Text(_moodLabels[mood] ?? mood),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedMoods.add(mood);
                        } else {
                          _selectedMoods.remove(mood);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Notes Section
            _buildSection(
              title: 'Notas Personales',
              icon: Icons.notes,
              child: TextField(
                key: const Key('wellness_notes_input'),
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '¿Cómo te sientes hoy? ¿Alguna observación física?',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              key: const Key('save_wellness_button_bottom'),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Guardar Registro Diario'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isLoading ? null : _saveWellness,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
