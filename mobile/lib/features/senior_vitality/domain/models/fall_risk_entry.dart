enum FallRiskLevel {
  low('LOW'),
  moderate('MODERATE'),
  high('HIGH');

  final String value;
  const FallRiskLevel(this.value);

  static FallRiskLevel fromValue(String val) {
    return FallRiskLevel.values.firstWhere(
      (e) => e.value == val,
      orElse: () => FallRiskLevel.low,
    );
  }
}

class FallRiskEntry {
  final String id;
  final String userId;
  final DateTime assessmentDate;
  final int fallsPastYear;
  final bool hasGaitUnsteadiness;
  final bool usesWalkingAid;
  final double? timedUpAndGoSeconds;
  final FallRiskLevel riskLevel;
  final int compositeScore;
  final List<String> environmentalHazards;
  final String? notes;

  const FallRiskEntry({
    required this.id,
    required this.userId,
    required this.assessmentDate,
    required this.fallsPastYear,
    this.hasGaitUnsteadiness = false,
    this.usesWalkingAid = false,
    this.timedUpAndGoSeconds,
    this.riskLevel = FallRiskLevel.low,
    this.compositeScore = 0,
    this.environmentalHazards = const [],
    this.notes,
  });
}
