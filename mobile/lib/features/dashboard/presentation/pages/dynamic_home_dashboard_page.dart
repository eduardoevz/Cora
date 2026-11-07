import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/dashboard/presentation/widgets/life_stage_switcher_sheet.dart';
import 'package:mobile/features/dashboard/presentation/widgets/module_preferences_page.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/treatments/presentation/pages/pillbox_and_treatments_page.dart';
import 'package:mobile/features/wellness/presentation/pages/wellness_tracker_page.dart';

class DynamicHomeDashboardPage extends ConsumerWidget {
  const DynamicHomeDashboardPage({super.key});

  static const Map<String, ({String title, String description, IconData icon})>
      _moduleMetadata = {
    'cycle_tracking': (
      title: 'Ciclo Menstrual',
      description: 'Fase folicular, predicción de ventana fértil y síntomas.',
      icon: Icons.calendar_month,
    ),
    'ovulation_prediction': (
      title: 'Predicción de Ovulación',
      description: 'Detección basada en biomarcadores y calendario.',
      icon: Icons.bubble_chart,
    ),
    'symptom_diary': (
      title: 'Diario de Síntomas',
      description: 'Registro de dolor pélvico, humor y energía.',
      icon: Icons.edit_note,
    ),
    'contraceptive_management': (
      title: 'Control Anticonceptivo',
      description: 'Recordatorios de toma, cambio de parche o citas.',
      icon: Icons.medication,
    ),
    'fertility_bbt': (
      title: 'Temperatura Basal (BBT)',
      description: 'Registro térmico diario para detectar salto ovulatorio.',
      icon: Icons.thermostat,
    ),
    'lh_surge_prediction': (
      title: 'Tiras de LH',
      description: 'Identificación cuantitativa del pico preovulatorio.',
      icon: Icons.science,
    ),
    'cervical_mucus': (
      title: 'Moco Cervical',
      description: 'Patrón estrogénico y consistencia fértil.',
      icon: Icons.water_drop,
    ),
    'fetal_development': (
      title: 'Desarrollo Fetal',
      description: 'Semana a semana: tamaño, peso y órganos formados.',
      icon: Icons.child_friendly,
    ),
    'maternal_vitals': (
      title: 'Signos Vitales Maternos',
      description: 'Tensión arterial y detección preventiva de preeclampsia.',
      icon: Icons.favorite,
    ),
    'kick_counter': (
      title: 'Contador de Pataditas',
      description: 'Monitoreo de movimientos fetales y patrones activos.',
      icon: Icons.touch_app,
    ),
    'birth_plan': (
      title: 'Plan de Parto ACOG',
      description: 'Preferencias de alumbramiento, acompañamiento y analgesia.',
      icon: Icons.assignment,
    ),
    'postpartum_lochia': (
      title: 'Monitoreo de Loquios',
      description: 'Evolución de flujo rubra, serosa y alba con alertas.',
      icon: Icons.healing,
    ),
    'pelvic_floor': (
      title: 'Suelo Pélvico',
      description: 'Ejercicios de rehabilitación y valoración muscular.',
      icon: Icons.fitness_center,
    ),
    'epds_screening': (
      title: 'Tamizaje Emocional (EPDS)',
      description: 'Escala de Edimburgo para detección de depresión perinatal.',
      icon: Icons.sentiment_satisfied,
    ),
    'breastfeeding_tracker': (
      title: 'Registro de Lactancia',
      description: 'Tomas por pecho, duración y extracción.',
      icon: Icons.restaurant,
    ),
    'vasomotor_hot_flashes': (
      title: 'Sofocos y Síntomas',
      description: 'Frecuencia, intensidad y factores desencadenantes.',
      icon: Icons.wb_sunny,
    ),
    'cycle_variability': (
      title: 'Variabilidad STRAW+10',
      description: 'Seguimiento de la transición a la menopausia.',
      icon: Icons.timeline,
    ),
    'sleep_and_mood': (
      title: 'Sueño y Estado de Ánimo',
      description: 'Calidad del descanso y bienestar emocional.',
      icon: Icons.nightlight_round,
    ),
    'hormone_therapy': (
      title: 'Terapia Hormonal (TRH)',
      description: 'Dosis, adherencia y seguimiento con tu especialista.',
      icon: Icons.vaccines,
    ),
    'bone_muscle_health': (
      title: 'Salud Ósea y Muscular',
      description: 'Prevención de osteopenia, fuerza y absorción de calcio.',
      icon: Icons.accessibility_new,
    ),
    'urogynecology': (
      title: 'Prevención Uroginecológica',
      description: 'Salud vesical, confort íntimo y control preventivo.',
      icon: Icons.health_and_safety,
    ),
    'cardiovascular_prevention': (
      title: 'Prevención Cardiovascular',
      description: 'Presión arterial, perfil lipídico y caminatas.',
      icon: Icons.monitor_heart,
    ),
    'preventive_checkups': (
      title: 'Chequeos Periódicos',
      description: 'Mamografía, citología y densitometría ósea al día.',
      icon: Icons.medical_services,
    ),
    'education_body_basics': (
      title: 'Conoce tu Cuerpo',
      description: 'Educación basada en evidencia sobre fisiología femenina.',
      icon: Icons.menu_book,
    ),
    'wellness': (
      title: 'Bienestar Integral',
      description: 'Nutrición consciente, hidratación y balance vital.',
      icon: Icons.spa,
    ),
    'partner_sharing': (
      title: 'Partner View',
      description: 'Compartir métricas seleccionadas en tiempo real.',
      icon: Icons.people_outline,
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeUserProfileProvider);

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cora')),
        body: const Center(
          child: Text('Cargando perfil...'),
        ),
      );
    }

    final theme = Theme.of(context);
    final enabledModules = profile.enabledModules;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${profile.firstName}'),
        actions: [
          IconButton(
            key: const Key('open_module_preferences_button'),
            icon: const Icon(Icons.tune),
            tooltip: 'Configurar módulos a la carta',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ModulePreferencesPage(profile: profile),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Life Stage Badge Card
              _buildStageCard(context, profile, theme),
              const SizedBox(height: 16),

              // Transversal Quick Access Row
              Row(
                children: [
                  Expanded(
                    child: Card(
                      key: const Key('quick_action_wellness'),
                      elevation: 0,
                      color: theme.colorScheme.secondaryContainer
                          .withValues(alpha: 0.5),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const WellnessTrackerPage(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.spa,
                                  color: theme.colorScheme.primary),
                              const SizedBox(height: 8),
                              Text(
                                'Bienestar Diario',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Sueño, agua y ánimo',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      key: const Key('quick_action_treatments'),
                      elevation: 0,
                      color: theme.colorScheme.tertiaryContainer
                          .withValues(alpha: 0.5),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PillboxAndTreatmentsPage(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.medication,
                                  color: theme.colorScheme.tertiary),
                              const SizedBox(height: 8),
                              Text(
                                'Pastillero Virtual',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Tomas y alertas',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Tus Módulos Activos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${enabledModules.length} activos',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dynamic Module Cards
              ...enabledModules.map((moduleKey) {
                final meta = _moduleMetadata[moduleKey] ??
                    (
                      title: moduleKey.replaceAll('_', ' ').toUpperCase(),
                      description: 'Módulo clínico activo para tu etapa.',
                      icon: Icons.widgets_outlined,
                    );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    key: Key('card_$moduleKey'),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        child: Icon(meta.icon),
                      ),
                      title: Text(
                        meta.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          meta.description,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        if (moduleKey == 'wellness' ||
                            moduleKey == 'sleep_and_mood') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const WellnessTrackerPage(),
                            ),
                          );
                        } else if (moduleKey == 'contraceptive_management' ||
                            moduleKey == 'hormone_therapy') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PillboxAndTreatmentsPage(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageCard(
    BuildContext context,
    UserProfileEntity profile,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Etapa actual',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.currentLifeStage.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ActionChip(
                  key: const Key('switch_stage_chip_button'),
                  avatar: const Icon(Icons.sync_alt, size: 16),
                  label: const Text('Cambiar'),
                  onPressed: () {
                    LifeStageSwitcherSheet.show(context, profile);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
