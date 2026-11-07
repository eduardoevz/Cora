class DailyWellnessEntity {
  final String? id;
  final String userId;
  final DateTime logDate;
  final double? sleepHours;
  final int? sleepQuality;
  final int? energyLevel;
  final int? hydrationMl;
  final int? exerciseMinutes;
  final List<String> moodTags;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DailyWellnessEntity({
    this.id,
    required this.userId,
    required this.logDate,
    this.sleepHours,
    this.sleepQuality,
    this.energyLevel,
    this.hydrationMl,
    this.exerciseMinutes,
    this.moodTags = const [],
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  DailyWellnessEntity copyWith({
    String? id,
    String? userId,
    DateTime? logDate,
    double? sleepHours,
    int? sleepQuality,
    int? energyLevel,
    int? hydrationMl,
    int? exerciseMinutes,
    List<String>? moodTags,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyWellnessEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      logDate: logDate ?? this.logDate,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      energyLevel: energyLevel ?? this.energyLevel,
      hydrationMl: hydrationMl ?? this.hydrationMl,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      moodTags: moodTags ?? this.moodTags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sleep_hours': sleepHours,
      'sleep_quality': sleepQuality,
      'energy_level': energyLevel,
      'hydration_ml': hydrationMl,
      'exercise_minutes': exerciseMinutes,
      'mood_tags': moodTags,
      'notes': notes,
    };
  }
}
