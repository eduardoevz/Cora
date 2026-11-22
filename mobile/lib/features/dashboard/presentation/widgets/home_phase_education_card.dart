import 'package:flutter/material.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/adolescence/presentation/pages/first_period_and_body_guide_page.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/fertility/presentation/pages/conception_hub_page.dart';
import 'package:mobile/features/menopause/presentation/pages/perimenopause_hub_page.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';

class HomePhaseEducationCard extends StatelessWidget {
  final UserProfileEntity profile;
  final CycleStatusEntity status;
  final List<FigoAlertEntity> alerts;
  final VoidCallback onOpenLibrary;

  const HomePhaseEducationCard({
    super.key,
    required this.profile,
    required this.status,
    this.alerts = const [],
    required this.onOpenLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);

    return CoraSurfaceCard(
      key: const Key('home_phase_education_card'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CoraEditorialImageBanner(
            assetPath: 'assets/images/home_follicular_editorial.jpg',
            height: 124,
            topBadge: 'GUÍA CLÍNICA DEL DÍA',
            bottomLeftBadge: 'Lectura clínica • 3 min',
          ),
          const SizedBox(height: 14),
          CoraSectionLabel(
            title: 'Acerca de tu periodo y fase actual',
            actionLabel: 'Biblioteca',
            onActionTap: onOpenLibrary,
          ),
          const SizedBox(height: 12),
          Text(
            status.phaseDescriptionEs,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          CoraBlushInsetBox(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tokens.verifiedSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bolt_outlined,
                    size: 18,
                    color: tokens.verified,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Recomendación biológica',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const CoraMintStatusPill(
                            label: 'Evidencia clínica',
                            variant: CoraStatusPillVariant.softMint,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.dailyTipEs,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                              height: 1.45,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CoraInfoCallout(
                  title: alert.titleEs,
                  subtitle: '${alert.descriptionEs} ${alert.recommendationEs}',
                  badgeText: 'Atención preventiva FIGO',
                  phaseKey: 'menstrual',
                  icon: Icons.info_outline_rounded,
                ),
              ),
            ),
          ],
          if (profile.currentLifeStage == LifeStage.adolescence) ...[
            const SizedBox(height: 12),
            CoraInfoCallout(
              key: const Key('dashboard_teen_guide_card'),
              title: 'Mi Primer Periodo',
              subtitle:
                  'Guía de desarrollo, mitos clínicos y PIN de privacidad.',
              badgeText: 'Adolescencia',
              phaseKey: 'follicular',
              icon: Icons.school_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FirstPeriodAndBodyGuidePage(),
                  ),
                );
              },
            ),
          ],
          if (profile.currentLifeStage == LifeStage.conceptionSearch) ...[
            const SizedBox(height: 12),
            CoraInfoCallout(
              key: const Key('dashboard_conception_hub_card'),
              title: 'Hub de Fertilidad y Concepción',
              subtitle:
                  'Curva BBT bifásica, moco, LH y checklist preconcepcional.',
              badgeText: 'Fertilidad',
              phaseKey: 'ovulatory',
              icon: Icons.biotech_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ConceptionHubPage(),
                  ),
                );
              },
            ),
          ],
          if (profile.currentLifeStage == LifeStage.perimenopause) ...[
            const SizedBox(height: 12),
            CoraInfoCallout(
              key: const Key('dashboard_perimenopause_card'),
              title: 'Perimenopausia y Menopausia',
              subtitle:
                  'Transición STRAW+10, gestor de sofocos y cardiometabolismo.',
              badgeText: 'STRAW+10',
              phaseKey: 'luteal',
              icon: Icons.waves_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PerimenopauseHubPage(),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('home_education_open_library_button'),
              onPressed: onOpenLibrary,
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('Explorar Biblioteca Clínica'),
            ),
          ),
        ],
      ),
    );
  }
}
