enum HotFlashSeverity {
  mild(1),
  moderate(2),
  severe(3),
  verySevere(4);

  final int value;
  const HotFlashSeverity(this.value);

  static HotFlashSeverity fromValue(int val) {
    return HotFlashSeverity.values.firstWhere(
      (e) => e.value == val,
      orElse: () => HotFlashSeverity.moderate,
    );
  }
}

enum HotFlashType {
  daytime('DAYTIME'),
  nightSweats('NIGHT_SWEATS');

  final String value;
  const HotFlashType(this.value);

  static HotFlashType fromValue(String val) {
    return HotFlashType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => HotFlashType.daytime,
    );
  }
}

class HotFlashEpisode {
  final String id;
  final String userId;
  final DateTime occurredAt;
  final HotFlashSeverity severity;
  final HotFlashType flashType;
  final int durationMinutes;
  final List<String> triggers;
  final int sleepDisruptionLevel;
  final bool associatedWithHrt;
  final String? notes;

  const HotFlashEpisode({
    required this.id,
    required this.userId,
    required this.occurredAt,
    required this.severity,
    required this.flashType,
    required this.durationMinutes,
    this.triggers = const [],
    this.sleepDisruptionLevel = 0,
    this.associatedWithHrt = false,
    this.notes,
  });
}
