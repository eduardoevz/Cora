import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/auth/auth_providers.dart';
import 'package:mobile/core/network/cora_api_client.dart';
import 'package:mobile/core/security/security_providers.dart';
import 'package:mobile/features/adolescence/presentation/pages/first_period_and_body_guide_page.dart';
import 'package:mobile/features/assistant/presentation/cora_assistant_chat_page.dart';
import 'package:mobile/features/assistant/presentation/providers/assistant_providers.dart';
import 'package:mobile/features/cycle/presentation/pages/cycle_monitor_page.dart';
import 'package:mobile/features/dashboard/presentation/widgets/life_stage_switcher_sheet.dart';
import 'package:mobile/features/dashboard/presentation/widgets/module_preferences_page.dart';
import 'package:mobile/features/education/presentation/clinical_library_page.dart';
import 'package:mobile/features/education/presentation/providers/education_providers.dart';
import 'package:mobile/features/fertility/presentation/pages/conception_hub_page.dart';
import 'package:mobile/features/menopause/presentation/pages/perimenopause_hub_page.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/partner/presentation/pages/partner_companion_view_page.dart';
import 'package:mobile/features/partner/presentation/pages/partner_sharing_settings_page.dart';
import 'package:mobile/features/partner/presentation/providers/partner_providers.dart';
import 'package:mobile/features/postpartum/presentation/pages/epds_mental_health_page.dart';
import 'package:mobile/features/postpartum/presentation/pages/lactation_and_milk_bank_page.dart';
import 'package:mobile/features/postpartum/presentation/pages/postpartum_recovery_page.dart';
import 'package:mobile/features/pregnancy/presentation/pages/pregnancy_weekly_hub_page.dart';
import 'package:mobile/features/privacy/presentation/pages/privacy_and_data_sovereignty_page.dart';
import 'package:mobile/features/records/presentation/pages/doctor_report_export_page.dart';
import 'package:mobile/features/records/presentation/pages/medical_folder_hub_page.dart';
import 'package:mobile/features/senior_vitality/presentation/pages/senior_vitality_hub_page.dart';
import 'package:mobile/features/treatments/presentation/pages/pillbox_and_treatments_page.dart';
import 'package:mobile/features/wellness/presentation/pages/wellness_tracker_page.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
            key: const Key('open_privacy_settings_button'),
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Privacidad y Soberanía',
            onPressed: () => _openPrivacyPage(context, ref, profile),
          ),
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

              // Cycle Wheel Quick Card
              Card(
                key: const Key('dashboard_cycle_card'),
                elevation: 0,
                color: const Color(0xFFFDF2F8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFFBCFE8)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF43F5E),
                    child: Icon(Icons.water_drop, color: Colors.white),
                  ),
                  title: const Text(
                    'Monitoreo del Ciclo Menstrual',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                      'Rueda de 4 fases, predicciones y alertas FIGO.'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CycleMonitorPage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Teen First Period Educational Card
              if (profile.currentLifeStage == LifeStage.adolescence) ...[
                Card(
                  key: const Key('dashboard_teen_guide_card'),
                  elevation: 0,
                  color: const Color(0xFFF5F3FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFDDD6FE)),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF8B5CF6),
                      child: Icon(Icons.auto_stories, color: Colors.white),
                    ),
                    title: const Text(
                      'Mi Primer Periodo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                        'Guía de desarrollo, mitos clínicos y PIN de privacidad.'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FirstPeriodAndBodyGuidePage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Conception Hub Quick Card
              if (profile.currentLifeStage == LifeStage.conceptionSearch) ...[
                Card(
                  key: const Key('dashboard_conception_hub_card'),
                  elevation: 0,
                  color: const Color(0xFFF0FDF4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFBBF7D0)),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF16A34A),
                      child: Icon(Icons.favorite, color: Colors.white),
                    ),
                    title: const Text(
                      'Hub de Fertilidad y Concepción',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                        'Curva BBT bifásica, moco, LH y checklist preconcepcional.'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ConceptionHubPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Pregnancy Hub Quick Card
              if (profile.currentLifeStage == LifeStage.pregnancy) ...[
                Card(
                  key: const Key('dashboard_pregnancy_hub_card'),
                  elevation: 0,
                  color: const Color(0xFFFDF2F8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFFBCFE8)),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFDB2777),
                      child: Icon(Icons.pregnant_woman, color: Colors.white),
                    ),
                    title: const Text(
                      'Mi Embarazo Semana a Semana',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                        'Desarrollo fetal, tensión arterial ACOG y cronómetro 5-1-1.'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PregnancyWeeklyHubPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Perimenopause Hub Quick Card
              if (profile.currentLifeStage == LifeStage.perimenopause) ...[
                Card(
                  key: const Key('dashboard_perimenopause_card'),
                  elevation: 0,
                  color: const Color(0xFFFDF4FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFF0ABFC)),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFC026D3),
                      child: Icon(Icons.wb_sunny_outlined, color: Colors.white),
                    ),
                    title: const Text(
                      'Perimenopausia y Menopausia',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                        'Transición STRAW+10, gestor de sofocos y cardiometabolismo.'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PerimenopauseHubPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Senior Vitality Hub Quick Card
              if (profile.currentLifeStage == LifeStage.seniorVitality) ...[
                Card(
                  key: const Key('dashboard_senior_vitality_card'),
                  elevation: 0,
                  color: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side:
                        const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF334155),
                      child: Icon(Icons.elderly_rounded, color: Colors.white),
                    ),
                    title: const Text(
                      'Plenitud y Vitalidad Sénior',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                        'Densitometría ósea, prevención de caídas y contacto de apoyo.'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SeniorVitalityHubPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

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
                              builder: (context) => const WellnessTrackerPage(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.spa, color: theme.colorScheme.primary),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      key: const Key('quick_action_medical_folder'),
                      elevation: 0,
                      color: const Color(0xFFE0F2FE),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MedicalFolderHubPage(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.folder_shared,
                                  color: Color(0xFF0284C7)),
                              const SizedBox(height: 8),
                              Text(
                                'Carpeta Clínica',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Estudios y vacunas',
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
                      key: const Key('quick_action_doctor_pdf'),
                      elevation: 0,
                      color: const Color(0xFFFEF3C7),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DoctorReportExportPage(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.picture_as_pdf,
                                  color: Color(0xFFD97706)),
                              const SizedBox(height: 8),
                              Text(
                                'Doctor-Ready PDF',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Reporte consulta',
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      key: const Key('quick_action_assistant'),
                      elevation: 0,
                      color: const Color(0xFFECFDF5),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openAssistant(context, ref),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.chat_bubble_outline,
                                  color: Color(0xFF059669)),
                              const SizedBox(height: 8),
                              Text(
                                'Asistente Cora',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Orientación clínica RAG',
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
                      key: const Key('quick_action_library'),
                      elevation: 0,
                      color: const Color(0xFFF3E8FF),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openLibrary(
                          context,
                          ref,
                          profile.currentLifeStage.value,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.menu_book_outlined,
                                  color: Color(0xFF7C3AED)),
                              const SizedBox(height: 8),
                              Text(
                                'Biblioteca Clínica',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Guías OMS y ACOG',
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      key: const Key('quick_action_partner'),
                      elevation: 0,
                      color: const Color(0xFFFFF1F2),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openPartnerSharing(context, ref),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.people_outline,
                                  color: Color(0xFFE11D48)),
                              const SizedBox(height: 8),
                              Text(
                                'Modo Acompañante',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Compartir en pareja',
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
                      key: const Key('quick_action_privacy'),
                      elevation: 0,
                      color: const Color(0xFFF1F5F9),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openPrivacyPage(context, ref, profile),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lock_outline,
                                  color: Color(0xFF334155)),
                              const SizedBox(height: 8),
                              Text(
                                'Privacidad y GDPR',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Biometría y exportación',
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
                        if (moduleKey == 'cycle_tracking' ||
                            moduleKey == 'ovulation_prediction' ||
                            moduleKey == 'symptom_diary') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CycleMonitorPage(),
                            ),
                          );
                        } else if (moduleKey == 'wellness' ||
                            moduleKey == 'sleep_and_mood') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const WellnessTrackerPage(),
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
                        } else if (moduleKey == 'fertility_bbt' ||
                            moduleKey == 'lh_surge_prediction' ||
                            moduleKey == 'cervical_mucus') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ConceptionHubPage(),
                            ),
                          );
                        } else if (moduleKey == 'fetal_development' ||
                            moduleKey == 'maternal_vitals' ||
                            moduleKey == 'kick_counter' ||
                            moduleKey == 'birth_plan') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PregnancyWeeklyHubPage(),
                            ),
                          );
                        } else if (moduleKey == 'postpartum_recovery' ||
                            moduleKey == 'postpartum_lochia' ||
                            moduleKey == 'pelvic_floor') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PostpartumRecoveryPage(),
                            ),
                          );
                        } else if (moduleKey == 'breastfeeding_tracker') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LactationAndMilkBankPage(),
                            ),
                          );
                        } else if (moduleKey == 'epds_screening') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EpdsMentalHealthPage(),
                            ),
                          );
                        } else if (moduleKey == 'vasomotor_hot_flashes' ||
                            moduleKey == 'cycle_variability' ||
                            moduleKey == 'sleep_and_mood') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PerimenopauseHubPage(),
                            ),
                          );
                        } else if (moduleKey == 'bone_muscle_health' ||
                            moduleKey == 'urogynecology' ||
                            moduleKey == 'cardiovascular_prevention') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SeniorVitalityHubPage(),
                            ),
                          );
                        } else if (moduleKey == 'preventive_checkups') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MedicalFolderHubPage(),
                            ),
                          );
                        } else if (moduleKey == 'education_body_basics') {
                          _openLibrary(
                            context,
                            ref,
                            profile.currentLifeStage.value,
                          );
                        } else if (moduleKey == 'partner_sharing') {
                          _openPartnerSharing(context, ref);
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

  Future<void> _openAssistant(BuildContext context, WidgetRef ref) async {
    final initialMessages = await ref.read(assistantMessagesProvider.future);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoraAssistantChatPage(
          initialMessages: initialMessages,
          onSendMessage: (query) =>
              ref.read(assistantServiceProvider).sendMessage(query),
        ),
      ),
    );
  }

  Future<void> _openLibrary(
    BuildContext context,
    WidgetRef ref,
    String lifeStage,
  ) async {
    final articles = await ref.read(educationArticlesProvider.future);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClinicalLibraryPage(
          articles: articles,
          initialLifeStage: null,
        ),
      ),
    );
  }

  Future<void> _openPartnerSharing(BuildContext context, WidgetRef ref) async {
    final service = ref.read(partnerServiceProvider);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => PartnerSharingSettingsPage(
          onGenerateCode: service.generateInvitationCode,
          onRedeemCode: service.redeemCode,
          onPermissionsChanged: (fertility, pregnancy, mood) {
            service.updatePermissions(
              fertility: fertility,
              pregnancy: pregnancy,
              mood: mood,
            );
          },
          onRevokeLink: service.revokeActiveLink,
          onOpenCompanionView: () async {
            final projection = await service.fetchSharedViewOrFallback();
            if (!pageContext.mounted) return;
            await Navigator.of(pageContext).push(
              MaterialPageRoute(
                builder: (_) => PartnerCompanionViewPage(
                  projection: projection,
                  onRefresh: () {},
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openPrivacyPage(
    BuildContext context,
    WidgetRef ref,
    UserProfileEntity profile,
  ) async {
    final biometricService = ref.read(biometricLockServiceProvider);
    final iconService = ref.read(discreetAppIconServiceProvider);
    final api = ref.read(coraApiClientProvider);
    final db = ref.read(appDatabaseProvider);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (privacyCtx) => PrivacyAndDataSovereigntyPage(
          biometricService: biometricService,
          iconService: iconService,
          onExportData: () async {
            try {
              final res =
                  await api.dio.post<List<int>>('/identity/me/data-export');
              if (res.data != null && res.data!.isNotEmpty) {
                final dir = await getApplicationDocumentsDirectory();
                final outFile =
                    File(p.join(dir.path, 'cora_export_${profile.id}.zip'));
                await outFile.writeAsBytes(res.data!, flush: true);
                return;
              }
            } catch (_) {
              // Offline fallback: write JSON export locally
            }
            final dir = await getApplicationDocumentsDirectory();
            final outFile =
                File(p.join(dir.path, 'cora_export_${profile.id}.json'));
            await outFile.writeAsString(
              '{"profile_id":"${profile.id}","first_name":"${profile.firstName}","life_stage":"${profile.currentLifeStage.value}"}',
              flush: true,
            );
          },
          onSignOut: () async {
            await ref.read(coraAuthServiceProvider).signOut();
            api.clearAuthToken();
            ref.read(activeUserProfileProvider.notifier).state = null;
            if (privacyCtx.mounted) {
              Navigator.of(privacyCtx).popUntil((route) => route.isFirst);
            }
          },
          onPurgeAccount: (phrase) async {
            try {
              await api.dio.delete(
                '/identity/me',
                data: {'confirm_phrase': phrase},
                options: Options(
                  sendTimeout: const Duration(seconds: 4),
                  receiveTimeout: const Duration(seconds: 4),
                ),
              );
            } catch (_) {
              // Proceed with local irreversible purge even if offline
            }
            await db.purgeAllLocalData();
            await ref.read(coraAuthServiceProvider).deleteCurrentUser();
            await ref.read(coraAuthServiceProvider).signOut();
            api.clearAuthToken();
            ref.read(activeUserProfileProvider.notifier).state = null;
            if (privacyCtx.mounted) {
              Navigator.of(privacyCtx).popUntil((route) => route.isFirst);
            }
          },
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
            if (profile.currentLifeStage == LifeStage.postpartum) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.favorite_outline, size: 16),
                      label: const Text('Recuperación'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const PostpartumRecoveryPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.timer_outlined, size: 16),
                      label: const Text('Lactancia'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const LactationAndMilkBankPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.psychology_outlined, size: 16),
                      label: const Text('EPDS'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EpdsMentalHealthPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
