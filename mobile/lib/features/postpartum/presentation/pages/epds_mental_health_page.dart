import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
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
      'title':
          '7. Me he sentido tan desdichada que he tenido dificultad para dormir',
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
        final tokens = CoraTheme.tokensOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tamizaje EPDS guardado con éxito'),
            backgroundColor: tokens.follicular,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final tokens = CoraTheme.tokensOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar tamizaje: $e'),
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
    final theme = Theme.of(context);
    final tokens = CoraTheme.tokensOf(context);
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
            const CoraStitchPageHeader(
              eyebrow: 'BIENESTAR EMOCIONAL POSPARTO',
              title: 'Cuestionario Clínico',
              subtitle:
                  'Tu salud mental es tan importante como tu recuperación física.',
              eyebrowIcon: Icons.spa_outlined,
              mintEyebrow: true,
            ),
            const SizedBox(height: 12),
            CoraBlushInsetBox(
              backgroundColor: tokens.verifiedSurface,
              borderColor: tokens.verified.withValues(alpha: 0.25),
              child: Row(
                children: [
                  Icon(Icons.support_agent_outlined, color: tokens.verified),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Apoyo confidencial 24/7 disponible si lo necesitas.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.verified,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Intro Card
            const CoraInfoCallout(
              title: 'Escala de Edimburgo (EPDS)',
              subtitle: 'Responde cómo te has sentido en los últimos 7 días. '
                  'No hay respuestas correctas ni incorrectas: tus emociones importan y cuidarte es prioritario.',
              icon: Icons.spa_outlined,
              phaseKey: 'follicular',
            ),
            const SizedBox(height: 16),

            // Inviolable Emergency Banner: Self Harm Risk (Item 10 > 0)
            if (evaluation.selfHarmRisk) ...[
              Container(
                key: const Key('banner_immediate_crisis_support'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.alertUrgent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.alertUrgent, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.health_and_safety_outlined,
                            color: tokens.alertUrgent, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No estás sola. Apoyo Inmediato Disponible',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: tokens.alertUrgent,
                              fontWeight: FontWeight.w700,
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('btn_call_crisis_hotline'),
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.alertUrgent,
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
            CoraSurfaceCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: evaluation.selfHarmRisk
                        ? tokens.alertUrgent.withValues(alpha: 0.14)
                        : evaluation.totalScore >= 13
                            ? tokens.alertPreventive.withValues(alpha: 0.18)
                            : evaluation.totalScore >= 10
                                ? tokens.ovulatorySurface
                                : tokens.follicularSurface,
                    child: Text(
                      '${evaluation.totalScore}',
                      key: const Key('text_epds_score'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: evaluation.selfHarmRisk
                            ? tokens.alertUrgent
                            : evaluation.totalScore >= 13
                                ? tokens.alertPreventive
                                : evaluation.totalScore >= 10
                                    ? tokens.menstrual
                                    : tokens.follicular,
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
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          evaluation.clinicalSummary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Question List
            ..._questions.map((q) {
              final qId = q['id'] as String;
              final title = q['title'] as String;
              final options = q['options'] as List<String>;
              final selectedIndex = _responses[qId] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: CoraSurfaceCard(
                  key: Key('card_question_$qId'),
                  borderColor: qId == 'item_10' && selectedIndex < 3
                      ? tokens.alertUrgent
                      : tokens.borderSubtle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: Colors.transparent,
                        child: Column(
                          children: List.generate(options.length, (optIdx) {
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
                        ),
                      ),
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
                return CoraSurfaceCard(
                  key: const Key('card_latest_screening'),
                  padding: EdgeInsets.zero,
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: latest.selfHarmRisk
                            ? tokens.alertUrgent.withValues(alpha: 0.14)
                            : tokens.follicularSurface,
                        child: Icon(
                          latest.selfHarmRisk
                              ? Icons.warning_amber
                              : Icons.psychology_outlined,
                          color: latest.selfHarmRisk
                              ? tokens.alertUrgent
                              : tokens.follicular,
                        ),
                      ),
                      title: Text(
                        'Puntaje: ${latest.totalScore}/30 — Día ${latest.daysPostpartum} posparto',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      subtitle: Text(
                        latest.clinicalSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
