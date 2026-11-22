import 'package:flutter/material.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/presentation/pages/cycle_monitor_page.dart';
import 'package:mobile/features/cycle/presentation/widgets/cycle_wheel_painter.dart';
import 'package:mobile/features/cycle/presentation/widgets/menstrual_month_grid.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/postpartum/presentation/pages/epds_mental_health_page.dart';
import 'package:mobile/features/postpartum/presentation/pages/lactation_and_milk_bank_page.dart';
import 'package:mobile/features/postpartum/presentation/pages/postpartum_recovery_page.dart';
import 'package:mobile/features/pregnancy/presentation/pages/pregnancy_weekly_hub_page.dart';
import 'package:mobile/features/senior_vitality/presentation/pages/senior_vitality_hub_page.dart';

class HomeCycleHeroCard extends StatelessWidget {
  final UserProfileEntity profile;
  final CalendarMonthProjectionEntity projection;
  final DateTime referenceToday;
  final VoidCallback onRegisterToday;

  const HomeCycleHeroCard({
    super.key,
    required this.profile,
    required this.projection,
    required this.referenceToday,
    required this.onRegisterToday,
  });

  String _phaseLabel(String? phase) {
    switch (phase?.toLowerCase()) {
      case 'menstrual':
        return 'Fase Menstrual';
      case 'follicular':
        return 'Fase Folicular';
      case 'ovulatory':
        return 'Fase Ovulatoria';
      case 'luteal':
        return 'Fase Lútea';
      case 'hormonally_managed':
        return 'Gestión Hormonal';
      default:
        return 'Fase Folicular';
    }
  }

  String _formatDateWithCountdown(DateTime target) {
    final monthName =
        MenstrualMonthGrid.monthNamesEs[(target.month - 1).clamp(0, 11)];
    final delta = target.difference(referenceToday).inDays;
    if (delta == 0) {
      return 'Hoy (${target.day} de $monthName)';
    }
    if (delta > 0) {
      return 'En $delta días (${target.day} de $monthName)';
    }
    return '${target.day} de $monthName';
  }

  @override
  Widget build(BuildContext context) {
    final stage = profile.currentLifeStage;
    if (stage == LifeStage.pregnancy) {
      return _buildPregnancyHero(context);
    }
    if (stage == LifeStage.postpartum) {
      return _buildPostpartumHero(context);
    }
    if (stage == LifeStage.seniorVitality) {
      return _buildSeniorHero(context);
    }

    final tokens = CoraTheme.tokensOf(context);
    final currentDay = projection.currentCycleDay ?? 1;
    final totalDays = projection.estimatedCycleLengthDays;
    final phaseKey = projection.currentPhase ?? 'follicular';

    return CoraSurfaceCard(
      key: const Key('home_cycle_hero_card'),
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              CoraPhasePill(
                phaseKey: phaseKey,
                label: _phaseLabel(projection.currentPhase),
                icon: Icons.spa_outlined,
              ),
              InkWell(
                key: const Key('dashboard_cycle_card'),
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CycleMonitorPage(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Monitoreo del Ciclo',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: tokens.accentPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: tokens.accentPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 196,
              height: 196,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(196, 196),
                    painter: CycleWheelPainter(
                      currentDay: currentDay,
                      totalDays: totalDays,
                      phase: phaseKey,
                      isHormonallyManaged: projection.isHormonallyManaged,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Día $currentDay',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'de $totalDays días',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (!projection.isHormonallyManaged &&
              projection.ovulationDate != null) ...[
            CoraInfoCallout(
              title: 'Ventana fértil y ovulación',
              subtitle:
                  'Ovulación estimada: ${_formatDateWithCountdown(projection.ovulationDate!)}',
              badgeText: phaseKey == 'ovulatory' ? 'Alta prob.' : 'Fértil',
              phaseKey: 'ovulatory',
              icon: Icons.favorite_border_rounded,
            ),
            const SizedBox(height: 10),
          ],
          if (projection.predictedNextPeriod != null) ...[
            CoraInfoCallout(
              title: 'Próximo periodo menstrual',
              subtitle:
                  'Esperado: ${_formatDateWithCountdown(projection.predictedNextPeriod!)}',
              badgeText: projection.hasExtendedUncertainty
                  ? 'Rango flexible'
                  : 'Ciclo de $totalDays d',
              phaseKey: 'menstrual',
              icon: Icons.water_drop_outlined,
            ),
            const SizedBox(height: 16),
          ],
          CoraPrimaryActionButton(
            key: const Key('home_hero_primary_cta_button'),
            label: 'Registrar biomarcadores de hoy',
            icon: Icons.edit_calendar_rounded,
            onPressed: onRegisterToday,
          ),
        ],
      ),
    );
  }

  Widget _buildPregnancyHero(BuildContext context) {
    return CoraSurfaceCard(
      key: const Key('dashboard_pregnancy_hub_card'),
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PregnancyWeeklyHubPage(),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              CoraPhasePill(
                phaseKey: 'hormonally_managed',
                label: 'Seguimiento Gestacional ACOG',
                icon: Icons.pregnant_woman_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Mi Embarazo Semana a Semana',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Desarrollo fetal, tensión arterial ACOG, movimientos fetales y cronómetro 5-1-1.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          CoraPrimaryActionButton(
            key: const Key('home_hero_primary_cta_button'),
            label: 'Abrir Hub Semanal de Embarazo',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PregnancyWeeklyHubPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostpartumHero(BuildContext context) {
    return CoraSurfaceCard(
      key: const Key('dashboard_postpartum_hub_card'),
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              CoraPhasePill(
                phaseKey: 'luteal',
                label: 'Puerperio y Lactancia',
                icon: Icons.child_care_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Recuperación Posparto Integral',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Seguimiento de loquios, cicatrización, banco de leche y bienestar emocional EPDS.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.favorite_outline, size: 16),
                label: const Text('Recuperación'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PostpartumRecoveryPage(),
                    ),
                  );
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.timer_outlined, size: 16),
                label: const Text('Lactancia'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LactationAndMilkBankPage(),
                    ),
                  );
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.psychology_outlined, size: 16),
                label: const Text('EPDS'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EpdsMentalHealthPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          CoraPrimaryActionButton(
            key: const Key('home_hero_primary_cta_button'),
            label: 'Registrar recuperación de hoy',
            icon: Icons.edit_calendar_rounded,
            onPressed: onRegisterToday,
          ),
        ],
      ),
    );
  }

  Widget _buildSeniorHero(BuildContext context) {
    return CoraSurfaceCard(
      key: const Key('dashboard_senior_vitality_card'),
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SeniorVitalityHubPage(),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              CoraPhasePill(
                phaseKey: 'hormonally_managed',
                label: 'Alta Legibilidad WCAG AAA',
                icon: Icons.health_and_safety_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Plenitud y Vitalidad Sénior',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Densitometría ósea DEXA, prevención de caídas, piso pélvico y contacto de apoyo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          CoraPrimaryActionButton(
            key: const Key('home_hero_primary_cta_button'),
            label: 'Abrir Hub de Plenitud y Salud Ósea',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SeniorVitalityHubPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
