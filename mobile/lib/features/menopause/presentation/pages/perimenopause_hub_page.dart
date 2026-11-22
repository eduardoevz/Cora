import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
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
    final tokens = CoraTheme.tokensOf(context);
    final user = ref.watch(activeUserProfileProvider);
    final hotFlashesAsync = ref.watch(recentHotFlashesProvider);
    final cardioAsync = ref.watch(latestCardiometabolicProvider);
    final bleedingAsync = ref.watch(recentBleedingRecordsProvider);
    final evaluator = ref.watch(menopauseOfflineEvaluatorProvider);

    final int userAge = user != null
        ? (DateTime.now().year - user.onboardingContext.birthYear)
        : 48;

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
                final alertRecord =
                    records.where((r) => r.isAlertTriggered).firstOrNull;
                if (alertRecord != null) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: CoraAlertBanner(
                      key: Key('postmenopausal_bleeding_alert_banner'),
                      title: 'Alerta de Sangrado Posmenopáusico',
                      description:
                          'Se registró sangrado tras 12+ meses de amenorrea. '
                          'Es fundamental consultar con ginecología para una '
                          'ecografía endometrial.',
                      isUrgent: true,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // 2. STRAW+10 Transition Card
            CoraSurfaceCard(
              backgroundColor: tokens.lutealSurface,
              borderColor: tokens.luteal.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timeline_rounded, color: tokens.luteal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Transición Hormonal (STRAW+10)',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Etapa evaluada para tus $userAge años:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  CoraPhasePill(
                    label: switch (evaluator.classifyStraw10(
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
                    phaseKey: 'luteal',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Hot Flash Summary & Quick Action Card
            CoraSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Síntomas Vasomotores',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Sin episodios registrados en los últimos días.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        );
                      }
                      final dayCount = episodes
                          .where((e) => e.flashType == HotFlashType.daytime)
                          .length;
                      final nightCount = episodes
                          .where((e) => e.flashType == HotFlashType.nightSweats)
                          .length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total episodios recientes: ${episodes.length} '
                            '($dayCount diurnos / $nightCount nocturnos)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Último: ${episodes.first.flashType == HotFlashType.nightSweats ? "Sudor nocturno" : "Sofoco diurno"} '
                            '(Intensidad: ${episodes.first.severity.value}/4)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
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
            const SizedBox(height: 16),

            // 4. Cardiometabolic Card
            CoraSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite_outline, color: tokens.menstrual),
                      const SizedBox(width: 8),
                      Text(
                        'Salud Cardiometabólica',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  cardioAsync.when(
                    data: (panel) {
                      if (panel == null) {
                        return Text(
                          'Aún no has registrado análisis de lípidos o tensión arterial.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.textSecondary,
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (panel.systolicBp != null &&
                              panel.diastolicBp != null)
                            Text(
                              'Tensión arterial: ${panel.systolicBp}/${panel.diastolicBp} mmHg',
                              style: const TextStyle(
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          if (panel.ldlCholesterol != null)
                            Text(
                              'Colesterol LDL: ${panel.ldlCholesterol} mg/dL',
                              style: const TextStyle(
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          if (panel.hdlCholesterol != null)
                            Text(
                              'Colesterol HDL: ${panel.hdlCholesterol} mg/dL',
                              style: const TextStyle(
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            'Nivel de riesgo: ${panel.riskLevel.value}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: panel.riskLevel.value == 'OPTIMAL'
                                  ? tokens.follicular
                                  : tokens.alertUrgent,
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
          ],
        ),
      ),
    );
  }
}
