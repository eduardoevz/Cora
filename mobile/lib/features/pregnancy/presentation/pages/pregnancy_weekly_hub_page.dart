import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/pregnancy/domain/entities/pregnancy_entities.dart';
import 'package:mobile/features/pregnancy/presentation/pages/birth_plan_and_appointments_page.dart';
import 'package:mobile/features/pregnancy/presentation/pages/contraction_and_kick_timers_page.dart';
import 'package:mobile/features/pregnancy/presentation/pages/maternal_vitals_page.dart';
import 'package:mobile/features/pregnancy/presentation/providers/pregnancy_providers.dart';

class PregnancyWeeklyHubPage extends ConsumerWidget {
  const PregnancyWeeklyHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(pregnancySummaryProvider);

    final tokens = CoraTheme.tokensOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Embarazo Semana a Semana'),
      ),
      body: summaryAsync.when(
        data: (summary) {
          if (summary == null) {
            return _buildNoActivePregnancy(context, ref);
          }
          final weeks = summary.gestationalWeeks;
          final days = summary.gestationalDays;
          final trimester = summary.trimester;
          final daysToEdd = summary.daysToEdd;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero Gestational Header Card
              CoraSurfaceCard(
                backgroundColor: tokens.follicularSurface,
                borderColor: tokens.follicular.withValues(alpha: 0.35),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Semana $weeks + $days días',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: tokens.follicular,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Trimestre $trimester • $daysToEdd días para FPP',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  color: tokens.textSecondary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tokens.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: tokens.borderSubtle),
                          ),
                          child: Icon(
                            Icons.child_friendly_outlined,
                            size: 30,
                            color: tokens.follicular,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (weeks / 40.0).clamp(0.0, 1.0),
                        backgroundColor: tokens.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          tokens.follicular,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Developmental highlights
              CoraSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.eco_outlined, color: tokens.follicular),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tamaño de tu bebé en la semana $weeks',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tokens.follicularSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.borderSubtle),
                      ),
                      child: Text(
                        _getFruitDescription(weeks),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getMilestoneHighlight(weeks),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: tokens.textSecondary,
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const CoraSectionLabel(
                  title: 'Herramientas Clínicas Obstétricas'),
              const SizedBox(height: 10),

              // Action Tiles
              _buildFeatureTile(
                context: context,
                icon: Icons.monitor_heart_outlined,
                color: tokens.alertUrgent,
                title: 'Signos Vitales y Alertas ACOG',
                subtitle:
                    'Monitor de presión arterial, glucemia, peso y síntomas de alarma',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MaternalVitalsPage(episode: summary.episode),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildFeatureTile(
                context: context,
                icon: Icons.timer_outlined,
                color: tokens.luteal,
                title: 'Cronómetro de Contracciones y Patadas',
                subtitle:
                    'Regla 5-1-1 / Pretérmino y Contador Cardiff de 10 patadas',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ContractionAndKickTimersPage(
                        episode: summary.episode,
                        gestationalWeeks: weeks,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildFeatureTile(
                context: context,
                icon: Icons.assignment_outlined,
                color: tokens.follicular,
                title: 'Plan de Parto y Citas Prenatales',
                subtitle:
                    'Preferencias de parto, acompañamiento y agenda médica',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BirthPlanAndAppointmentsPage(
                        episode: summary.episode,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error al cargar datos del embarazo: $err'),
        ),
      ),
    );
  }

  Widget _buildNoActivePregnancy(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: CoraEmptyStateCard(
          icon: Icons.pregnant_woman_outlined,
          title: 'No tienes un episodio de embarazo activo',
          subtitle:
              'Configura tu fecha de última menstruación o fecha probable de parto para iniciar el seguimiento.',
          actionLabel: 'Iniciar Seguimiento de Embarazo',
          onAction: () => _showStartPregnancyDialog(context, ref),
        ),
      ),
    );
  }

  void _showStartPregnancyDialog(BuildContext context, WidgetRef ref) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 70)),
      firstDate: DateTime.now().subtract(const Duration(days: 300)),
      lastDate: DateTime.now(),
      helpText: 'Selecciona la fecha de tu última menstruación (FUM)',
    );

    if (pickedDate != null) {
      final user = ref.read(activeUserProfileProvider);
      if (user == null) return;
      final repo = ref.read(pregnancyRepositoryProvider);
      final clinicalEdd = pickedDate.add(const Duration(days: 280));
      final episode = PregnancyEpisodeEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        clinicalEdd: clinicalEdd,
        lastMenstrualPeriod: pickedDate,
        isActive: true,
        startedAt: DateTime.now(),
      );
      await repo.saveEpisode(episode);
      ref.invalidate(activePregnancyEpisodeProvider);
    }
  }

  Widget _buildFeatureTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final tokens = CoraTheme.tokensOf(context);
    return CoraSurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
          ),
          trailing: Icon(Icons.chevron_right, color: tokens.textSecondary),
          onTap: onTap,
        ),
      ),
    );
  }

  String _getFruitDescription(int week) {
    if (week <= 8) return 'Tamaño de una frambuesa (~1.6 cm, 1 g)';
    if (week <= 12) return 'Tamaño de una ciruela (~5.4 cm, 14 g)';
    if (week <= 16) return 'Tamaño de un aguacate (~11.6 cm, 100 g)';
    if (week <= 20) return 'Tamaño de un plátano (~25 cm, 300 g)';
    if (week <= 24) return 'Tamaño de una espiga de maíz (~30 cm, 600 g)';
    if (week <= 28) {
      return 'Tamaño de una berenjena grande (~37.6 cm, 1000 g)';
    }
    if (week <= 32) return 'Tamaño de una piña (~42.4 cm, 1700 g)';
    if (week <= 36) {
      return 'Tamaño de un manojo de acelgas (~47.4 cm, 2600 g)';
    }
    return 'Tamaño de una sandía madura (~51 cm, 3500 g)';
  }

  String _getMilestoneHighlight(int week) {
    if (week <= 12) {
      return 'Desarrollo de órganos vitales y extremidades. Momento clave para ecografía de semana 11-14 y translucencia nucal.';
    } else if (week <= 20) {
      return 'El feto comienza a escuchar sonidos y percibir luz. Próximamente ecografía morfológica detallada.';
    } else if (week <= 28) {
      return 'Inicio de producción de surfactante en alvéolos pulmonares. Momento para tamizaje de glucosa O\'Sullivan.';
    } else {
      return 'Tercer trimestre: el feto gana peso aceleradamente y prepara sus reflejos para el nacimiento. Inicia conteo diario de patadas.';
    }
  }
}
