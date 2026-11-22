import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/adolescence/presentation/pages/first_period_and_body_guide_page.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/presentation/pages/chronic_conditions_tracker_page.dart';
import 'package:mobile/features/cycle/presentation/providers/menstrual_calendar_providers.dart';
import 'package:mobile/features/cycle/presentation/widgets/calendar_day_detail_panel.dart';
import 'package:mobile/features/cycle/presentation/widgets/calendar_day_log_sheet.dart';
import 'package:mobile/features/cycle/presentation/widgets/menstrual_month_grid.dart';
import 'package:mobile/features/fertility/presentation/pages/conception_hub_page.dart';
import 'package:mobile/features/menopause/presentation/pages/perimenopause_hub_page.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/postpartum/presentation/pages/postpartum_recovery_page.dart';
import 'package:mobile/features/pregnancy/presentation/pages/pregnancy_weekly_hub_page.dart';
import 'package:mobile/features/senior_vitality/presentation/pages/senior_vitality_hub_page.dart';

class MenstrualCalendarPage extends ConsumerWidget {
  const MenstrualCalendarPage({super.key});

  String _formatShortDate(DateTime dt) {
    final monthName =
        MenstrualMonthGrid.monthNamesEs[(dt.month - 1).clamp(0, 11)];
    return '${dt.day} de $monthName';
  }

  void _openDayLogSheet(
    BuildContext context,
    DateTime selectedDate,
    CycleSymptomEntity? existingLog,
  ) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CoraTheme.tokensOf(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CalendarDayLogSheet(
        selectedDate: selectedDate,
        initialSymptomLog: existingLog,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeUserProfileProvider);
    final lifeStage = profile?.currentLifeStage ?? LifeStage.regularAdult;
    final refToday = ref.watch(calendarReferenceTodayProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final monthProjectionAsync =
        ref.watch(activeCalendarMonthProjectionProvider);
    final selectedDayAsync = ref.watch(selectedCalendarDayProjectionProvider);
    final selectedSymptomLog = ref.watch(selectedDaySymptomLogProvider);
    final controller = ref.watch(menstrualCalendarControllerProvider);

    Widget content = Scaffold(
      appBar: AppBar(
        title: const Text('Calendario Menstrual'),
        actions: [
          TextButton.icon(
            key: const Key('calendar_today_button'),
            onPressed: controller.goToToday,
            icon: const Icon(Icons.today_rounded, size: 18),
            label: const Text('Hoy'),
          ),
        ],
      ),
      body: monthProjectionAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Error al proyectar calendario: $err'),
          ),
        ),
        data: (projection) {
          final selectedDay = selectedDayAsync.valueOrNull ??
              (projection.days.isNotEmpty ? projection.days.first : null);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StageAdaptationCard(lifeStage: lifeStage),
                if (projection.predictedNextPeriod != null ||
                    projection.ovulationDate != null) ...[
                  const SizedBox(height: 14),
                  _PredictionHighlightsRow(
                    predictedNextPeriod: projection.predictedNextPeriod,
                    ovulationDate: projection.ovulationDate,
                    formatDate: _formatShortDate,
                  ),
                ],
                const SizedBox(height: 16),
                MenstrualMonthGrid(
                  projection: projection,
                  selectedDate: selectedDate,
                  referenceToday: refToday,
                  onDaySelected: controller.selectDate,
                  onPreviousMonth: controller.previousMonth,
                  onNextMonth: controller.nextMonth,
                ),
                if (selectedDay != null) ...[
                  const SizedBox(height: 16),
                  CalendarDayDetailPanel(
                    dayProjection: selectedDay,
                    displayMode: projection.displayMode,
                    symptomLog: selectedSymptomLog,
                    onOpenLogSheet: () => _openDayLogSheet(
                      context,
                      selectedDay.date,
                      selectedSymptomLog,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );

    if (lifeStage == LifeStage.seniorVitality) {
      content = Theme(
        data: CoraTheme.highLegibility(),
        child: content,
      );
    }

    return content;
  }
}

class _PredictionHighlightsRow extends StatelessWidget {
  final DateTime? predictedNextPeriod;
  final DateTime? ovulationDate;
  final String Function(DateTime) formatDate;

  const _PredictionHighlightsRow({
    required this.predictedNextPeriod,
    required this.ovulationDate,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        if (predictedNextPeriod != null)
          CoraInfoCallout(
            title: 'Próximo periodo estimado',
            subtitle: formatDate(predictedNextPeriod!),
            badgeText: 'Predicción',
            phaseKey: 'menstrual',
            icon: Icons.water_drop_outlined,
          ),
        if (ovulationDate != null)
          CoraInfoCallout(
            title: 'Ovulación estimada',
            subtitle: formatDate(ovulationDate!),
            badgeText: 'Ventana fértil',
            phaseKey: 'ovulatory',
            icon: Icons.favorite_border_rounded,
          ),
      ],
    );
  }
}

class _StageAdaptationCard extends StatelessWidget {
  final LifeStage lifeStage;

  const _StageAdaptationCard({required this.lifeStage});

  ({
    String title,
    String subtitle,
    String actionLabel,
    String phaseKey,
    IconData icon,
    Widget Function() pageBuilder,
  }) _stageConfig() {
    switch (lifeStage) {
      case LifeStage.adolescence:
        return (
          title: 'Ciclo en Adolescencia (Tolerancia FIGO 21–45 días)',
          subtitle:
              'Durante los primeros años posmenarquia la variabilidad es fisiológica. Explora tu guía educativa o protege tu diario con PIN.',
          actionLabel: 'Abrir Guía de Adolescencia',
          phaseKey: 'follicular',
          icon: Icons.school_outlined,
          pageBuilder: () => const FirstPeriodAndBodyGuidePage(),
        );
      case LifeStage.regularAdult:
        return (
          title: 'Seguimiento Cíclico de 4 Fases',
          subtitle:
              'Visualiza tu periodo registrado, pronóstico del próximo ciclo, ventana fértil, ovulación y patrones preventivos FIGO.',
          actionLabel: 'Monitoreo SOP y Endometriosis',
          phaseKey: 'menstrual',
          icon: Icons.timeline_rounded,
          pageBuilder: () => const ChronicConditionsTrackerPage(),
        );
      case LifeStage.conceptionSearch:
        return (
          title: 'Ventana Fértil y Concepción Sintotérmica',
          subtitle:
              'Identifica tus días de alta fertilidad y combina el calendario con temperatura basal (BBT), pico de LH y moco cervical.',
          actionLabel: 'Abrir Hub de Fertilidad (BBT/LH)',
          phaseKey: 'ovulatory',
          icon: Icons.biotech_outlined,
          pageBuilder: () => const ConceptionHubPage(),
        );
      case LifeStage.pregnancy:
        return (
          title: 'Seguimiento Gestacional ACOG (Sin predicción menstrual)',
          subtitle:
              'La ovulación y el ciclo menstrual permanecen en pausa durante el embarazo. Registra tus controles prenatales y signos maternos.',
          actionLabel: 'Abrir Hub Semanal de Embarazo',
          phaseKey: 'hormonally_managed',
          icon: Icons.pregnant_woman_rounded,
          pageBuilder: () => const PregnancyWeeklyHubPage(),
        );
      case LifeStage.postpartum:
        return (
          title: 'Recuperación Posparto, Lactancia y Bienestar EPDS',
          subtitle:
              'El retorno menstrual tras el parto es progresivo. Monitorea loquios, lactancia y tu salud emocional.',
          actionLabel: 'Abrir Recuperación Posparto',
          phaseKey: 'luteal',
          icon: Icons.child_care_rounded,
          pageBuilder: () => const PostpartumRecoveryPage(),
        );
      case LifeStage.perimenopause:
        return (
          title: 'Transición Hormonal STRAW+10 (Variabilidad >= 7 días)',
          subtitle:
              'Registra variaciones en la duración entre ciclos, intervalos sin sangrado y episodios vasomotores.',
          actionLabel: 'Abrir Hub de Perimenopausia',
          phaseKey: 'luteal',
          icon: Icons.waves_rounded,
          pageBuilder: () => const PerimenopauseHubPage(),
        );
      case LifeStage.seniorVitality:
        return (
          title:
              'Calendario Preventivo de Plenitud (Alta Legibilidad WCAG AAA)',
          subtitle:
              'Enfocado en vitalidad ósea, piso pélvico, salud cardiometabólica y controles médicos con contraste >= 7:1.',
          actionLabel: 'Abrir Salud Ósea y Chequeos',
          phaseKey: 'hormonally_managed',
          icon: Icons.health_and_safety_outlined,
          pageBuilder: () => const SeniorVitalityHubPage(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _stageConfig();
    return KeyedSubtree(
      key: Key('calendar_stage_banner_${lifeStage.value}'),
      child: CoraInfoCallout(
        title: cfg.title,
        subtitle: cfg.subtitle,
        badgeText: cfg.actionLabel,
        phaseKey: cfg.phaseKey,
        icon: cfg.icon,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => cfg.pageBuilder()),
          );
        },
      ),
    );
  }
}
