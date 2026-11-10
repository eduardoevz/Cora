import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/postpartum/domain/entities/postpartum_entities.dart';
import 'package:mobile/features/postpartum/presentation/providers/postpartum_providers.dart';
import 'package:uuid/uuid.dart';

class EpdsMentalHealthPage extends ConsumerStatefulWidget {
  const EpdsMentalHealthPage({super.key});

  @override
  ConsumerState<EpdsMentalHealthPage> createState() =>
      _EpdsMentalHealthPageState();
}

class _EpdsMentalHealthPageState extends ConsumerState<EpdsMentalHealthPage> {
  final int _daysPostpartum = 14;
  final Map<String, int> _responses = {
    'item_1': 0,
    'item_2': 0,
    'item_3': 3, // 0 pts inverted
    'item_4': 0,
    'item_5': 3, // 0 pts inverted
    'item_6': 3, // 0 pts inverted
    'item_7': 3, // 0 pts inverted
    'item_8': 3, // 0 pts inverted
    'item_9': 3, // 0 pts inverted
    'item_10': 3, // 0 pts inverted (Nunca)
  };

  bool _isSaving = false;

  static const List<Map<String, dynamic>> _questions = [
    {
      'id': 'item_1',
      'title': '1. He sido capaz de reír y ver el lado divertido de las cosas',
      'options': [
        'Tanto como siempre', // 0 pts
        'No tanto ahora', // 1 pt
        'Mucho menos ahora', // 2 pts
        'No, en absoluto', // 3 pts
      ],
    },
    {
      'id': 'item_2',
      'title': '2. He mirado el futuro con placer o entusiasmo',
      'options': [
        'Tanto como siempre', // 0 pts
        'Menos de lo que solía hacer', // 1 pt
        'Definitivamente menos', // 2 pts
        'Prácticamente nunca', // 3 pts
      ],
    },
    {
      'id': 'item_3',
      'title': '3. Me he culpado sin necesidad cuando las cosas marchaban mal',
      'options': [
        'Sí, la mayor parte del tiempo', // 3 pts
        'Sí, algunas veces', // 2 pts
        'Casi nunca', // 1 pt
        'No, nunca', // 0 pts
      ],
    },
    {
      'id': 'item_4',
      'title': '4. He estado ansiosa o preocupada sin motivo aparente',
      'options': [
        'No, en absoluto', // 0 pts
        'Casi nunca', // 1 pt
        'Sí, a veces', // 2 pts
        'Sí, muy a menudo', // 3 pts
      ],
    },
    {
      'id': 'item_5',
      'title': '5. He sentido miedo o pánico sin motivo alguno',
      'options': [
        'Sí, mucho', // 3 pts
        'Sí, a veces', // 2 pts
        'No, casi nunca', // 1 pt
        'No, en absoluto', // 0 pts
      ],
    },
    {
      'id': 'item_6',
      'title': '6. Las cosas me sobrepasan o siento que no puedo con todo',
      'options': [
        'Sí, la mayor parte del tiempo no puedo afrontarlo', // 3 pts
        'Sí, a veces no puedo afrontarlo tan bien como solía', // 2 pts
        'No, la mayor parte del tiempo puedo con ello', // 1 pt
        'No, estoy afrontándolo tan bien como siempre', // 0 pts
      ],
    },
    {
      'id': 'item_7',
      'title': '7. Me he sentido tan desdichada que he tenido dificultad para dormir',
      'options': [
        'Sí, la mayor parte del tiempo', // 3 pts
        'Sí, a veces', // 2 pts
        'No muy a menudo', // 1 pt
        'No, en absoluto', // 0 pts
      ],
    },
    {
      'id': 'item_8',
      'title': '8. Me he sentido triste o desgraciada',
      'options': [
        'Sí, casi todo el tiempo', // 3 pts
        'Sí, con bastante frecuencia', // 2 pts
        'Casi nunca', // 1 pt
        'No, en absoluto', // 0 pts
      ],
    },
    {
      'id': 'item_9',
      'title': '9. He estado tan desdichada que he llorado',
      'options': [
        'Sí, la mayor parte del tiempo', // 3 pts
        'Sí, con frecuencia', // 2 pts
        'Solo de vez en cuando', // 1 pt
        'No, nunca', // 0 pts
      ],
    },
    {
      'id': 'item_10',
      'title': '10. Se me ha pasado por la cabeza la idea de hacerme daño',
      'options': [
        'Sí, con bastante frecuencia', // 3 pts
        'A veces', // 2 pts
        'Casi nunca', // 1 pt
        'Nunca', // 0 pts
      ],
    },
  ];

  EpdsScreening get _currentEvaluation {
    final user = ref.read(activeUserProfileProvider);
    return EpdsOfflineScoringService.evaluate(
      id: 'preview',
      userId: user?.id ?? 'preview_user',
      daysPostpartum: _daysPostpartum,
      responses: _responses,
    );
  }

  Future<void> _saveScreening() async {
    final user = ref.read(activeUserProfileProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final evaluation = EpdsOfflineScoringService.evaluate(
        id: const Uuid().v4(),
        userId: user.id,
        daysPostpartum: _daysPostpartum,
        responses: _responses,
      );

      final repo = ref.read(postpartumRepositoryProvider);
      await repo.saveEpdsScreening(evaluation);

      ref.invalidate(latestEpdsScreeningProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tamizaje EPDS guardado con éxito'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar tamizaje: $e'),
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
    final theme = Theme.of(context);
    final evaluation = _currentEvaluation;
    final latestScreeningAsync = ref.watch(latestEpdsScreeningProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salud Emocional (EPDS)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Intro Card
            Card(
              elevation: 0,
              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.spa_outlined,
                            color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'Escala de Edimburgo (EPDS)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Responde cómo te has sentido en los últimos 7 días. '
                      'No hay respuestas correctas ni incorrectas: tus emociones importan y cuidarte es prioritario.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Inviolable Emergency Banner: Self Harm Risk (Item 10 > 0)
            if (evaluation.selfHarmRisk) ...[
              Container(
                key: const Key('banner_immediate_crisis_support'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade700, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.health_and_safety,
                            color: Colors.red.shade700, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No estás sola. Apoyo Inmediato Disponible',
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Has indicado pensamientos de autolesión o sufrimiento profundo. '
                      'El posparto es una etapa de enormes cambios hormonales y emocionales. '
                      'Por favor, permite que profesionales te acompañen ahora mismo.',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('btn_call_crisis_hotline'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Llamando a Línea de la Vida / Crisis Perinatal: 800 911 2000 (gratuita 24/7)',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone_in_talk),
                      label: const Text(
                        'Línea de Apoyo 24/7 (800 911 2000)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Current Score Gauge Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: evaluation.selfHarmRisk
                          ? Colors.red.shade100
                          : evaluation.totalScore >= 13
                              ? Colors.orange.shade100
                              : evaluation.totalScore >= 10
                                  ? Colors.amber.shade100
                                  : Colors.teal.shade100,
                      child: Text(
                        '${evaluation.totalScore}',
                        key: const Key('text_epds_score'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: evaluation.selfHarmRisk
                              ? Colors.red.shade800
                              : evaluation.totalScore >= 13
                                  ? Colors.orange.shade800
                                  : evaluation.totalScore >= 10
                                      ? Colors.amber.shade900
                                      : Colors.teal.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Puntuación total: ${evaluation.totalScore} / 30',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            evaluation.clinicalSummary,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Question List
            ..._questions.map((q) {
              final qId = q['id'] as String;
              final title = q['title'] as String;
              final options = q['options'] as List<String>;
              final selectedIndex = _responses[qId] ?? 0;

              return Card(
                key: Key('card_question_$qId'),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: qId == 'item_10' && selectedIndex < 3
                        ? Colors.red.shade300
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(options.length, (optIdx) {
                        return RadioListTile<int>(
                          key: Key('option_${qId}_$optIdx'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(options[optIdx]),
                          value: optIdx,
                          // ignore: deprecated_member_use
                          groupValue: selectedIndex,
                          // ignore: deprecated_member_use
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _responses[qId] = val);
                            }
                          },
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Save Screening Button
            FilledButton.icon(
              key: const Key('btn_save_epds_screening'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _isSaving ? null : _saveScreening,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text(
                'Guardar Tamizaje EPDS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // Historical summary
            Text(
              'Último Tamizaje Registrado',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            latestScreeningAsync.when(
              data: (latest) {
                if (latest == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No hay tamizajes previos guardados.'),
                  );
                }
                return Card(
                  key: const Key('card_latest_screening'),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: latest.selfHarmRisk
                          ? Colors.red.shade100
                          : Colors.teal.shade100,
                      child: Icon(
                        latest.selfHarmRisk
                            ? Icons.warning_amber
                            : Icons.psychology,
                        color: latest.selfHarmRisk ? Colors.red : Colors.teal,
                      ),
                    ),
                    title: Text(
                      'Puntaje: ${latest.totalScore}/30 — Día ${latest.daysPostpartum} posparto',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      latest.clinicalSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }
}
