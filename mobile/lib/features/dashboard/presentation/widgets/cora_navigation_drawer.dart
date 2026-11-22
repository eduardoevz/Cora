import 'package:flutter/material.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/adolescence/presentation/pages/first_period_and_body_guide_page.dart';
import 'package:mobile/features/cycle/presentation/pages/chronic_conditions_tracker_page.dart';
import 'package:mobile/features/cycle/presentation/pages/cycle_monitor_page.dart';
import 'package:mobile/features/cycle/presentation/pages/menstrual_calendar_page.dart';
import 'package:mobile/features/dashboard/presentation/widgets/life_stage_switcher_sheet.dart';
import 'package:mobile/features/dashboard/presentation/widgets/module_preferences_page.dart';
import 'package:mobile/features/fertility/presentation/pages/conception_hub_page.dart';
import 'package:mobile/features/menopause/presentation/pages/perimenopause_hub_page.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/postpartum/presentation/pages/postpartum_recovery_page.dart';
import 'package:mobile/features/pregnancy/presentation/pages/pregnancy_weekly_hub_page.dart';
import 'package:mobile/features/records/presentation/pages/doctor_report_export_page.dart';
import 'package:mobile/features/records/presentation/pages/medical_folder_hub_page.dart';
import 'package:mobile/features/senior_vitality/presentation/pages/senior_vitality_hub_page.dart';
import 'package:mobile/features/treatments/presentation/pages/pillbox_and_treatments_page.dart';
import 'package:mobile/features/wellness/presentation/pages/wellness_tracker_page.dart';

class CoraNavigationDrawer extends StatelessWidget {
  final UserProfileEntity profile;
  final VoidCallback onOpenAssistant;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenPartnerSharing;
  final VoidCallback onOpenPrivacy;

  const CoraNavigationDrawer({
    super.key,
    required this.profile,
    required this.onOpenAssistant,
    required this.onOpenLibrary,
    required this.onOpenPartnerSharing,
    required this.onOpenPrivacy,
  });

  ({
    String title,
    String subtitle,
    IconData icon,
    Widget Function() pageBuilder,
  }) _stageHubItem(LifeStage stage) {
    switch (stage) {
      case LifeStage.adolescence:
        return (
          title: 'Mi Primer Periodo y PIN',
          subtitle: 'Guía de desarrollo y privacidad',
          icon: Icons.school_outlined,
          pageBuilder: () => const FirstPeriodAndBodyGuidePage(),
        );
      case LifeStage.regularAdult:
        return (
          title: 'SOP y Endometriosis',
          subtitle: 'Seguimiento ginecológico especializado',
          icon: Icons.tune_rounded,
          pageBuilder: () => const ChronicConditionsTrackerPage(),
        );
      case LifeStage.conceptionSearch:
        return (
          title: 'Hub de Fertilidad (BBT/LH)',
          subtitle: 'Temperatura basal y ventana fértil',
          icon: Icons.biotech_outlined,
          pageBuilder: () => const ConceptionHubPage(),
        );
      case LifeStage.pregnancy:
        return (
          title: 'Mi Embarazo Semana a Semana',
          subtitle: 'Signos vitales ACOG y movimientos',
          icon: Icons.pregnant_woman_rounded,
          pageBuilder: () => const PregnancyWeeklyHubPage(),
        );
      case LifeStage.postpartum:
        return (
          title: 'Recuperación Posparto y EPDS',
          subtitle: 'Loquios, lactancia y salud mental',
          icon: Icons.child_care_rounded,
          pageBuilder: () => const PostpartumRecoveryPage(),
        );
      case LifeStage.perimenopause:
        return (
          title: 'Perimenopausia y Sofocos',
          subtitle: 'Transición STRAW+10 y síntomas',
          icon: Icons.waves_rounded,
          pageBuilder: () => const PerimenopauseHubPage(),
        );
      case LifeStage.seniorVitality:
        return (
          title: 'Plenitud y Vitalidad Sénior',
          subtitle: 'Salud ósea, caídas y chequeos',
          icon: Icons.health_and_safety_outlined,
          pageBuilder: () => const SeniorVitalityHubPage(),
        );
    }
  }

  void _navigateToPage(BuildContext context, Widget Function() builder) {
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute(builder: (_) => builder()));
  }

  void _runActionAfterClose(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final initial = profile.firstName.trim().isNotEmpty
        ? profile.firstName.trim()[0].toUpperCase()
        : 'C';
    final fullName = '${profile.firstName} ${profile.lastName}'.trim();
    final stageItem = _stageHubItem(profile.currentLifeStage);

    return Drawer(
      backgroundColor: tokens.surface,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                decoration: BoxDecoration(
                  color: tokens.blushInset,
                  border: Border(
                    bottom: BorderSide(color: tokens.borderSubtle),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                        CoraMintStatusPill(
                          label: profile.currentLifeStage.label,
                          icon: Icons.circle,
                          variant: CoraStatusPillVariant.softMint,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: tokens.primaryDeep,
                          foregroundColor: Colors.white,
                          child: Text(
                            initial,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      fullName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: tokens.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.verified_outlined,
                                    size: 16,
                                    color: tokens.primaryDeep,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Plan Cora Clínico Integral',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: tokens.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CoraSurfaceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      borderRadius: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: tokens.accentSurface,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.water_drop_outlined,
                                  size: 16,
                                  color: tokens.primaryDeep,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ETAPA ACTIVA',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: tokens.textSecondary,
                                            fontSize: 10,
                                          ),
                                    ),
                                    Text(
                                      profile.currentLifeStage.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ActionChip(
                              key: const Key('drawer_switch_stage_button'),
                              backgroundColor: tokens.accentSurface,
                              side: BorderSide(color: tokens.borderSubtle),
                              label: Text(
                                'Cambiar etapa',
                                style: TextStyle(
                                  color: tokens.primaryDeep,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              onPressed: () {
                                final parentContext =
                                    Navigator.of(context).context;
                                Navigator.of(context).pop();
                                LifeStageSwitcherSheet.show(
                                    parentContext, profile);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const _DrawerSectionHeader(title: 'MI SALUD DIARIA'),
              _DrawerNavTile(
                tileKey: const Key('drawer_item_home'),
                icon: Icons.home_rounded,
                title: 'Inicio',
                subtitle: 'Resumen de tu día y ciclo actual',
                isSelected: true,
                onTap: () => Navigator.of(context).pop(),
              ),
              _DrawerNavTile(
                tileKey: const Key('drawer_item_menstrual_calendar'),
                icon: Icons.calendar_month_rounded,
                title: 'Calendario Menstrual',
                subtitle: 'Predicciones, ventana fértil y registro por fecha',
                onTap: () => _navigateToPage(
                  context,
                  () => const MenstrualCalendarPage(),
                ),
              ),
              _DrawerNavTile(
                tileKey: const Key('drawer_item_cycle_monitor'),
                icon: Icons.donut_large_rounded,
                title: 'Monitoreo del Ciclo',
                subtitle: 'Rueda de 4 fases y alertas preventivas FIGO',
                onTap: () => _navigateToPage(
                  context,
                  () => const CycleMonitorPage(),
                ),
              ),
              _DrawerNavTile(
                tileKey: const Key('drawer_item_stage_hub'),
                icon: stageItem.icon,
                title: stageItem.title,
                subtitle: stageItem.subtitle,
                onTap: () => _navigateToPage(context, stageItem.pageBuilder),
              ),
              _DrawerNavTile(
                tileKey: const Key('drawer_item_wellness'),
                icon: Icons.spa_outlined,
                title: 'Bienestar Diario',
                subtitle: 'Sueño, hidratación, energía y estado de ánimo',
                onTap: () => _navigateToPage(
                  context,
                  () => const WellnessTrackerPage(),
                ),
              ),
              _DrawerNavTile(
                tileKey: const Key('drawer_item_treatments'),
                icon: Icons.medication_outlined,
                title: 'Pastillero Virtual',
                subtitle: 'Tratamientos, tomas diarias y recordatorios',
                onTap: () => _navigateToPage(
                  context,
                  () => const PillboxAndTreatmentsPage(),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Divider(color: tokens.borderSubtle, height: 1),
              ),
              const _DrawerSectionHeader(
                title: 'EXPEDIENTE E INTELIGENCIA CLÍNICA',
              ),
              _DrawerNavTile(
                tileKey: const Key('drawer_item_medical_folder'),
                icon: Icons.folder_shared_outlined,
                title: 'Carpeta Clínica Digital',
                subtitle: 'Estudios, vacunas y directorio de especialistas',
                onTap: () => _navigateToPage(
                  context,
                  () => const MedicalFolderHubPage(),
                ),
              ),
              _DrawerNavTile(
                tileKey: const Key('drawer_item_doctor_pdf'),
                icon: Icons.picture_as_pdf_outlined,
                title: 'Doctor-Ready PDF',
                subtitle: 'Reporte clínico estructurado para consulta médica',
                trailingBadge: 'PDF',
                onTap: () => _navigateToPage(
                  context,
                  () => const DoctorReportExportPage(),
                ),
              ),
              _DrawerNavTile(
                tileKey: const Key('drawer_item_assistant'),
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Asistente Clínico Cora',
                subtitle: 'Orientación clínica RAG con triaje determinista',
                onTap: () => _runActionAfterClose(context, onOpenAssistant),
              ),
              _DrawerNavTile(
                tileKey: const Key('drawer_item_library'),
                icon: Icons.menu_book_outlined,
                title: 'Biblioteca Clínica',
                subtitle: 'Guías médicas basadas en evidencia OMS y ACOG',
                onTap: () => _runActionAfterClose(context, onOpenLibrary),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Divider(color: tokens.borderSubtle, height: 1),
              ),
              const _DrawerSectionHeader(title: 'PERSONALIZACIÓN Y PRIVACIDAD'),
              _DrawerNavTile(
                tileKey: const Key('drawer_item_partner'),
                icon: Icons.people_outline_rounded,
                title: 'Modo Acompañante',
                subtitle: 'Compartir métricas seleccionadas con tu pareja',
                onTap: () =>
                    _runActionAfterClose(context, onOpenPartnerSharing),
              ),
              _DrawerNavTile(
                tileKey: const Key('drawer_item_modules'),
                icon: Icons.tune_rounded,
                title: 'Módulos a la Carta',
                subtitle: 'Activa o desactiva herramientas según tu prioridad',
                onTap: () => _navigateToPage(
                  context,
                  () => ModulePreferencesPage(profile: profile),
                ),
              ),
              _DrawerNavTile(
                tileKey: const Key('drawer_item_privacy'),
                icon: Icons.shield_outlined,
                title: 'Privacidad y GDPR',
                subtitle: 'Biometría, icono discreto, exportación y purga',
                onTap: () => _runActionAfterClose(context, onOpenPrivacy),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: CoraBlushInsetBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 15,
                            color: tokens.primaryDeep,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'SUGERENCIA CLÍNICA',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: tokens.primaryDeep,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mantén tu bitácora diaria al día para mejorar la precisión de tu reporte médico.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 13,
                      color: tokens.verified,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Cumplimiento HIPAA & RGPD • Cora v2.0',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  final String title;

  const _DrawerSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final String? trailingBadge;
  final VoidCallback onTap;

  const _DrawerNavTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isSelected = false,
    this.trailingBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    final minHeight = tokens.isHighLegibility ? 56.0 : 48.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? tokens.accentSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: tileKey,
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tokens.primaryDeep
                          : tokens.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: isSelected ? Colors.white : tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: isSelected
                                        ? tokens.primaryDeep
                                        : tokens.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                        ),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (trailingBadge != null) ...[
                    const SizedBox(width: 6),
                    CoraMintStatusPill(
                      label: trailingBadge!,
                      variant: CoraStatusPillVariant.mint,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
