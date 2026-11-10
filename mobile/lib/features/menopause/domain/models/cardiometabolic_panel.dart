enum CardiometabolicRiskLevel {
  optimal('OPTIMAL'),
  borderline('BORDERLINE'),
  elevatedRisk('ELEVATED_RISK');

  final String value;
  const CardiometabolicRiskLevel(this.value);

  static CardiometabolicRiskLevel fromValue(String val) {
    return CardiometabolicRiskLevel.values.firstWhere(
      (e) => e.value == val,
      orElse: () => CardiometabolicRiskLevel.optimal,
    );
  }
}

class CardiometabolicPanel {
  final String id;
  final String userId;
  final DateTime measurementDate;
  final int? systolicBp;
  final int? diastolicBp;
  final double? totalCholesterol;
  final double? ldlCholesterol;
  final double? hdlCholesterol;
  final double? triglycerides;
  final double? fastingGlucose;
  final CardiometabolicRiskLevel riskLevel;
  final List<String> flaggedParameters;
  final String? notes;

  const CardiometabolicPanel({
    required this.id,
    required this.userId,
    required this.measurementDate,
    this.systolicBp,
    this.diastolicBp,
    this.totalCholesterol,
    this.ldlCholesterol,
    this.hdlCholesterol,
    this.triglycerides,
    this.fastingGlucose,
    this.riskLevel = CardiometabolicRiskLevel.optimal,
    this.flaggedParameters = const [],
    this.notes,
  });
}
