import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Embarazo Semana a Semana'),
        backgroundColor: Colors.pink.shade50,
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
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.pink.shade100.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Semana $weeks + $days días',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Trimestre $trimester • $daysToEdd días para FPP',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.shade200,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.child_friendly,
                              size: 32,
                              color: Colors.pink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: (weeks / 40.0).clamp(0.0, 1.0),
                        backgroundColor: Colors.white,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Fruit comparison & developmental highlights
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.eco, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Tamaño de tu bebé en la semana $weeks',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getFruitDescription(weeks),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getMilestoneHighlight(weeks),
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Herramientas Clínicas Obstétricas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Action Tiles
              _buildFeatureTile(
                context: context,
                icon: Icons.monitor_heart,
                color: Colors.red.shade400,
                title: 'Signos Vitales y Alertas ACOG',
                subtitle:
                    'Monitor de presión arterial, glucemia, peso y síntomas de alarma',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MaternalVitalsPage(episode: summary.episode),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildFeatureTile(
                context: context,
                icon: Icons.timer,
                color: Colors.purple.shade400,
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
                icon: Icons.assignment,
                color: Colors.teal.shade500,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pregnant_woman, size: 72, color: Colors.pink),
            const SizedBox(height: 16),
            const Text(
              'No tienes un episodio de embarazo activo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Configura tu fecha de última menstruación o fecha probable de parto para iniciar el seguimiento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showStartPregnancyDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Iniciar Seguimiento de Embarazo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
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
      final repo = ref.read(pregnancyRepositoryProvider);
      final clinicalEdd = pickedDate.add(const Duration(days: 280));
      final episode = PregnancyEpisodeEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user',
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
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _getFruitDescription(int week) {
    if (week <= 8) return '🌱 Tamaño de una frambuesa (~1.6 cm, 1 g)';
    if (week <= 12) return '🫐 Tamaño de una ciruela (~5.4 cm, 14 g)';
    if (week <= 16) return '🥑 Tamaño de un aguacate (~11.6 cm, 100 g)';
    if (week <= 20) return '🍌 Tamaño de un plátano (~25 cm, 300 g)';
    if (week <= 24) return '🌽 Tamaño de una espiga de maíz (~30 cm, 600 g)';
    if (week <= 28) return '🍆 Tamaño de una berenjena grande (~37.6 cm, 1000 g)';
    if (week <= 32) return '🍍 Tamaño de una piña (~42.4 cm, 1700 g)';
    if (week <= 36) return '🥬 Tamaño de un manojo de acelgas (~47.4 cm, 2600 g)';
    return '🍉 Tamaño de una sandía madura (~51 cm, 3500 g)';
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
