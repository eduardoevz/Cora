enum ScreeningUrgency {
  dueNow('due_now', 'Pendiente Prioritario'),
  upcoming('upcoming', 'Próximamente'),
  upToDate('up_to_date', 'Al Día');

  final String value;
  final String displayName;
  const ScreeningUrgency(this.value, this.displayName);

  static ScreeningUrgency fromString(String val) {
    return ScreeningUrgency.values.firstWhere(
      (u) => u.value == val,
      orElse: () => ScreeningUrgency.upcoming,
    );
  }
}

class PreventiveScreeningItem {
  final String screeningCode;
  final String title;
  final String description;
  final String recommendedAgeRange;
  final String frequencyGuideline;
  final ScreeningUrgency urgency;
  final DateTime? lastPerformedAt;
  final DateTime? dueDate;

  const PreventiveScreeningItem({
    required this.screeningCode,
    required this.title,
    required this.description,
    required this.recommendedAgeRange,
    required this.frequencyGuideline,
    required this.urgency,
    this.lastPerformedAt,
    this.dueDate,
  });

  factory PreventiveScreeningItem.fromJson(Map<String, dynamic> json) {
    return PreventiveScreeningItem(
      screeningCode: json['screening_code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      recommendedAgeRange: json['recommended_age_range'] as String,
      frequencyGuideline: json['frequency_guideline'] as String,
      urgency: ScreeningUrgency.fromString(json['urgency'] as String),
      lastPerformedAt: json['last_performed_at'] != null
          ? DateTime.parse(json['last_performed_at'] as String)
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
    );
  }
}
