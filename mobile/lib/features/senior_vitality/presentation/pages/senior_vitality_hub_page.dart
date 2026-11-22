import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/senior_vitality/domain/models/dexa_bone_scan.dart';
import 'package:mobile/features/senior_vitality/domain/models/fall_risk_entry.dart';
import 'package:mobile/features/senior_vitality/domain/models/pelvic_floor_entry.dart';
import 'package:mobile/features/senior_vitality/presentation/providers/senior_vitality_providers.dart';
import 'package:mobile/features/senior_vitality/presentation/widgets/trusted_contact_quick_action_card.dart';

class SeniorVitalityHubPage extends ConsumerWidget {
  const SeniorVitalityHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dexaAsync = ref.watch(latestDexaScanProvider);
    final fallAsync = ref.watch(latestFallRiskProvider);
    final pelvicAsync = ref.watch(recentPelvicLogsProvider);
    final evaluator = ref.watch(seniorVitalityOfflineEvaluatorProvider);

    return Theme(
      data: CoraTheme.highLegibility(),
      child: Builder(
        builder: (themedContext) {
          final tokens = CoraTheme.tokensOf(themedContext);
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Plenitud y Vitalidad',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: CoraMintStatusPill(
                      label: 'Lectura AAA • Contraste Máximo',
                      icon: Icons.visibility_outlined,
                      variant: CoraStatusPillVariant.softMint,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const CoraStitchPageHeader(
                    eyebrow: 'SALUD PREVENTIVA SÉNIOR',
                    title: 'Vitalidad & Densidad Ósea',
                    subtitle:
                        'Monitoreo de densitometría DXA, prevención de caídas y red de apoyo.',
                    eyebrowIcon: Icons.health_and_safety_outlined,
                  ),
                  const SizedBox(height: 12),
                  const CoraEditorialImageBanner(
                    assetPath: 'assets/images/senior_vitality_outdoor.jpg',
                    height: 110,
                    topBadge: 'ALTA LEGIBILIDAD WCAG AAA',
                    bottomLeftBadge: 'Bienestar y autonomía sénior',
                  ),
                  const SizedBox(height: 12),
                  CoraSurfaceCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Referencia DXA T-Score',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Container(
                                  height: 8,
                                  color: tokens.verified,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Container(
                                  height: 8,
                                  color: tokens.primaryDeep,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Container(
                                  height: 8,
                                  color: tokens.alertUrgent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            CoraMintStatusPill(
                              label: 'Normal >= -1.0',
                              variant: CoraStatusPillVariant.softMint,
                            ),
                            CoraMintStatusPill(
                              label: 'Osteopenia -1.0 a -2.5',
                              variant: CoraStatusPillVariant.blush,
                            ),
                            CoraMintStatusPill(
                              label: 'Osteoporosis <= -2.5',
                              variant: CoraStatusPillVariant.urgent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 1. Primary Support Contact Action
                  const TrustedContactQuickActionCard(),
                  const SizedBox(height: 16),

                  // 2. High Fracture Risk Warning (if low bone density + high fall risk)
                  Builder(
                    builder: (context) {
                      final dexa = dexaAsync.valueOrNull;
                      final fall = fallAsync.valueOrNull;
                      if (dexa != null && fall != null) {
                        final isHighRisk = evaluator.isHighFractureRisk(
                          boneCategory: dexa.category,
                          fallLevel: fall.riskLevel,
                        );
                        if (isHighRisk) {
                          return Container(
                            key: const Key('high_fracture_risk_banner'),
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: tokens.alertUrgentSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: tokens.alertUrgent,
                                width: 2.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_rounded,
                                    color: tokens.alertUrgent, size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Alerta Preventiva de Fractura',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: tokens.alertUrgent,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Se detectó riesgo de caídas junto con densidad ósea reducida. '
                                        'Se sugiere fisioterapia motriz y retirar obstáculos en casa.',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: tokens.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // 3. Bone Density (DXA) Card
                  CoraSurfaceCard(
                    borderColor: tokens.textPrimary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.accessibility_new_rounded,
                                size: 28, color: tokens.accentPrimary),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Salud Ósea (Densitometría)',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        dexaAsync.when(
                          data: (scan) {
                            if (scan == null) {
                              return const Text(
                                'No se ha registrado densitometría DXA reciente.',
                                style: TextStyle(fontSize: 16),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resultado T-score: ${scan.tScore.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Clasificación: ${switch (scan.category) {
                                    BoneDensityCategory.normal => "Normal",
                                    BoneDensityCategory.osteopenia =>
                                      "Osteopenia",
                                    BoneDensityCategory.osteoporosis =>
                                      "Osteoporosis",
                                    BoneDensityCategory.severeOsteoporosis =>
                                      "Osteoporosis Severa",
                                  }}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  'Sitio explorado: ${scan.anatomicalSite.value}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Text('Error: $err'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Fall Risk Card
                  CoraSurfaceCard(
                    borderColor: tokens.textPrimary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.elderly_rounded,
                                size: 28, color: tokens.accentPrimary),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Prevención de Caídas',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        fallAsync.when(
                          data: (fall) {
                            if (fall == null) {
                              return const Text(
                                'Sin tamizaje de marcha o caídas registrado.',
                                style: TextStyle(fontSize: 16),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nivel de riesgo: ${switch (fall.riskLevel) {
                                    FallRiskLevel.low => "Bajo",
                                    FallRiskLevel.moderate => "Moderado",
                                    FallRiskLevel.high => "Alto",
                                  }}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Caídas último año: ${fall.fallsPastYear}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                if (fall.timedUpAndGoSeconds != null)
                                  Text(
                                    'Prueba TUG: ${fall.timedUpAndGoSeconds} s',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Text('Error: $err'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Urogynecology & Pelvic Floor Card
                  CoraSurfaceCard(
                    borderColor: tokens.textPrimary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.water_drop_outlined,
                                size: 28, color: tokens.accentPrimary),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Suelo Pélvico y Continencia',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        pelvicAsync.when(
                          data: (logs) {
                            if (logs.isEmpty) {
                              return const Text(
                                'Sin síntomas de continencia registrados.',
                                style: TextStyle(fontSize: 16),
                              );
                            }
                            final latest = logs.first;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Incontinencia reportada: ${switch (latest.incontinenceType) {
                                    IncontinenceType.none => "Ninguna",
                                    IncontinenceType.stress => "De esfuerzo",
                                    IncontinenceType.urge => "De urgencia",
                                    IncontinenceType.mixed => "Mixta",
                                    IncontinenceType.overflow =>
                                      "Por rebosamiento",
                                  }}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (latest.dailyPadCount > 0)
                                  Text(
                                    'Protectores por día: ${latest.dailyPadCount}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Text('Error: $err'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
