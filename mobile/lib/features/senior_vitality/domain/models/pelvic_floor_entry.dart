enum IncontinenceType {
  none('NONE'),
  stress('STRESS'),
  urge('URGE'),
  mixed('MIXED'),
  overflow('OVERFLOW');

  final String value;
  const IncontinenceType(this.value);

  static IncontinenceType fromValue(String val) {
    return IncontinenceType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => IncontinenceType.none,
    );
  }
}

class PelvicFloorEntry {
  final String id;
  final String userId;
  final DateTime logDate;
  final IncontinenceType incontinenceType;
  final int dailyPadCount;
  final bool hasPelvicHeaviness;
  final int vaginalDrynessLevel;
  final bool hasDyspareunia;
  final String? notes;

  const PelvicFloorEntry({
    required this.id,
    required this.userId,
    required this.logDate,
    this.incontinenceType = IncontinenceType.none,
    this.dailyPadCount = 0,
    this.hasPelvicHeaviness = false,
    this.vaginalDrynessLevel = 0,
    this.hasDyspareunia = false,
    this.notes,
  });
}
