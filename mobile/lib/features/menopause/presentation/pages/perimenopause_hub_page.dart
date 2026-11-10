import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/menopause/domain/models/hot_flash_episode.dart';
import 'package:mobile/features/menopause/domain/services/menopause_offline_evaluator.dart';
import 'package:mobile/features/menopause/presentation/pages/hot_flash_tracker_page.dart';
import 'package:mobile/features/menopause/presentation/providers/menopause_providers.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

class PerimenopauseHubPage extends ConsumerWidget {
  const PerimenopauseHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(activeUserProfileProvider);
    final hotFlashesAsync = ref.watch(recentHotFlashesProvider);
    final cardioAsync = ref.watch(latestCardiometabolicProvider);
    final bleedingAsync = ref.watch(recentBleedingRecordsProvider);
    final evaluator = ref.watch(menopauseOfflineEvaluatorProvider);

    final int userAge =
        user != null ? (DateTime.now().year - user.onboardingContext.birthYear) : 48;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perimenopausia y Menopausia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Registrar Sofoco',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const HotFlashTrackerPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Inviolable Postmenopausal Bleeding Banner
            bleedingAsync.when(
              data: (records) {
                final alertRecord = records.where((r) => r.isAlertTriggered).firstOrNull;
                if (alertRecord != null) {
                  return Container(
                    key: const Key('postmenopausal_bleeding_alert_banner'),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.error,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: theme.colorScheme.error, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Alerta de Sangrado Posmenopáusico',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Se registró sangrado tras 12+ meses de amenorrea. '
                          'Es fundamental consultar con ginecología para una '
                          'ecografía endometrial.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // 2. STRAW+10 Transition Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timeline_rounded,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Transición Hormonal (STRAW+10)',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Etapa evaluada para tus $userAge años:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        switch (evaluator.classifyStraw10(
                          age: userAge,
                          consecutiveCycleLengths: [28, 36],
                          daysSinceLastMenstruation: 45,
                        )) {
                          Straw10Stage.lateReproductive =>
                            'Etapa Reproductiva Tardía (-3)',
                          Straw10Stage.earlyTransition =>
                            'Perimenopausia Temprana (-2)',
                          Straw10Stage.lateTransition =>
                            'Perimenopausia Tardía (-1)',
                          Straw10Stage.postmenopause =>
                            'Posmenopausia Establecida (+1/+2)',
                        },
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Hot Flash Summary & Quick Action Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Síntomas Vasomotores',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          key: const Key('quick_log_hot_flash_button'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const HotFlashTrackerPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Registrar'),
                        ),
                      ],
                    ),
                    hotFlashesAsync.when(
                      data: (episodes) {
                        if (episodes.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Sin episodios registrados en los últimos días.',
                            ),
                          );
                        }
                        final dayCount = episodes
                            .where((e) => e.flashType == HotFlashType.daytime)
                            .length;
                        final nightCount = episodes
                            .where(
                                (e) => e.flashType == HotFlashType.nightSweats)
                            .length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total episodios recientes: ${episodes.length} '
                              '(☀️ $dayCount diurnos / 🌙 $nightCount nocturnos)',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Último: ${episodes.first.flashType == HotFlashType.nightSweats ? "Sudor nocturno" : "Sofoco diurno"} '
                              '(Intensidad: ${episodes.first.severity.value}/4)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error al cargar: $err'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Cardiometabolic Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite_rounded,
                            color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Text(
                          'Salud Cardiometabólica',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    cardioAsync.when(
                      data: (panel) {
                        if (panel == null) {
                          return const Text(
                            'Aún no has registrado análisis de lípidos o tensión arterial.',
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (panel.systolicBp != null &&
                                panel.diastolicBp != null)
                              Text(
                                  'Tensión arterial: ${panel.systolicBp}/${panel.diastolicBp} mmHg'),
                            if (panel.ldlCholesterol != null)
                              Text('Colesterol LDL: ${panel.ldlCholesterol} mg/dL'),
                            if (panel.hdlCholesterol != null)
                              Text('Colesterol HDL: ${panel.hdlCholesterol} mg/dL'),
                            const SizedBox(height: 4),
                            Text(
                              'Nivel de riesgo: ${panel.riskLevel.value}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: panel.riskLevel.value == 'OPTIMAL'
                                    ? Colors.green
                                    : theme.colorScheme.error,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error al cargar: $err'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
