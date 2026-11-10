import 'package:mobile/features/senior_vitality/domain/models/dexa_bone_scan.dart';
import 'package:mobile/features/senior_vitality/domain/models/fall_risk_entry.dart';
import 'package:mobile/features/senior_vitality/domain/models/pelvic_floor_entry.dart';

class FallEvaluationResult {
  final FallRiskLevel level;
  final int score;
  final List<String> recommendations;

  const FallEvaluationResult({
    required this.level,
    required this.score,
    required this.recommendations,
  });
}

class SeniorVitalityOfflineEvaluator {
  const SeniorVitalityOfflineEvaluator();

  BoneDensityCategory classifyBoneDensity(
    double tScore, {
    bool previousFracture = false,
  }) {
    if (tScore <= -2.5) {
      return previousFracture
          ? BoneDensityCategory.severeOsteoporosis
          : BoneDensityCategory.osteoporosis;
    } else if (tScore < -1.0) {
      return BoneDensityCategory.osteopenia;
    } else {
      return BoneDensityCategory.normal;
    }
  }

  FallEvaluationResult evaluateFallRisk({
    required int fallsPastYear,
    required bool hasGaitUnsteadiness,
    required bool usesWalkingAid,
    double? timedUpAndGoSeconds,
  }) {
    int score = 0;
    final List<String> actions = [];

    if (fallsPastYear >= 2) {
      score += 3;
      actions.add('Historial de caídas recurrentes: consulta integral.');
    } else if (fallsPastYear == 1) {
      score += 2;
      actions.add('Caída reciente: revisar factores de riesgo.');
    }

    if (hasGaitUnsteadiness) {
      score += 2;
      actions.add('Inestabilidad de marcha: ejercicios de equilibrio.');
    }

    if (usesWalkingAid) {
      score += 1;
    }

    if (timedUpAndGoSeconds != null && timedUpAndGoSeconds > 12.0) {
      score += 2;
      actions.add('Prueba motriz sugiere lentitud o riesgo.');
    }

    FallRiskLevel level;
    if (score >= 4) {
      level = FallRiskLevel.high;
      actions.add('Riesgo alto: barras de apoyo e iluminación nocturna.');
    } else if (score >= 2) {
      level = FallRiskLevel.moderate;
      actions.add('Riesgo moderado: fortalecimiento y marcha.');
    } else {
      level = FallRiskLevel.low;
      actions.add('Riesgo bajo: mantener caminatas y vida activa.');
    }

    return FallEvaluationResult(
      level: level,
      score: score,
      recommendations: actions,
    );
  }

  bool isHighFractureRisk({
    required BoneDensityCategory boneCategory,
    required FallRiskLevel fallLevel,
  }) {
    final boneAtRisk = boneCategory == BoneDensityCategory.osteopenia ||
        boneCategory == BoneDensityCategory.osteoporosis ||
        boneCategory == BoneDensityCategory.severeOsteoporosis;
    final fallAtRisk =
        fallLevel == FallRiskLevel.moderate || fallLevel == FallRiskLevel.high;
    return boneAtRisk && fallAtRisk;
  }

  bool requiresPelvicConsult(PelvicFloorEntry entry) {
    return entry.incontinenceType != IncontinenceType.none ||
        entry.hasDyspareunia ||
        entry.vaginalDrynessLevel >= 2 ||
        entry.hasPelvicHeaviness;
  }
}
