class MenstrualCycleEntity {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final int? cycleLengthDays;
  final int? bleedingDurationDays;
  final bool isCurrent;

  const MenstrualCycleEntity({
    required this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
    this.cycleLengthDays,
    this.bleedingDurationDays,
    this.isCurrent = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
        'cycle_length_days': cycleLengthDays,
        'bleeding_duration_days': bleedingDurationDays,
        'is_current': isCurrent,
      };

  factory MenstrualCycleEntity.fromJson(Map<String, dynamic> json) {
    return MenstrualCycleEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      cycleLengthDays: json['cycle_length_days'] as int?,
      bleedingDurationDays: json['bleeding_duration_days'] as int?,
      isCurrent: json['is_current'] as bool? ?? true,
    );
  }
}

class CycleSymptomEntity {
  final String id;
  final String userId;
  final String? cycleId;
  final DateTime logDate;
  final String bleedingFlow; // none, spotting, light, medium, heavy
  final int? pelvicPain; // 0-10
  final int? dysmenorrhea; // 0-10
  final bool? dyspareunia;
  final int? acneSeverity; // 0-10
  final bool? hirsutism;
  final int? fatigueLevel; // 0-10
  final List<String> giSymptoms;
  final String? notes;

  const CycleSymptomEntity({
    required this.id,
    required this.userId,
    this.cycleId,
    required this.logDate,
    this.bleedingFlow = 'none',
    this.pelvicPain,
    this.dysmenorrhea,
    this.dyspareunia,
    this.acneSeverity,
    this.hirsutism,
    this.fatigueLevel,
    this.giSymptoms = const [],
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'cycle_id': cycleId,
        'log_date': logDate.toIso8601String().split('T').first,
        'bleeding_flow': bleedingFlow,
        'pelvic_pain': pelvicPain,
        'dysmenorrhea': dysmenorrhea,
        'dyspareunia': dyspareunia,
        'acne_severity': acneSeverity,
        'hirsutism': hirsutism,
        'fatigue_level': fatigueLevel,
        'gi_symptoms': giSymptoms,
        'notes': notes,
      };

  factory CycleSymptomEntity.fromJson(Map<String, dynamic> json) {
    return CycleSymptomEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cycleId: json['cycle_id'] as String?,
      logDate: DateTime.parse(json['log_date'] as String),
      bleedingFlow: json['bleeding_flow'] as String? ?? 'none',
      pelvicPain: json['pelvic_pain'] as int?,
      dysmenorrhea: json['dysmenorrhea'] as int?,
      dyspareunia: json['dyspareunia'] as bool?,
      acneSeverity: json['acne_severity'] as int?,
      hirsutism: json['hirsutism'] as bool?,
      fatigueLevel: json['fatigue_level'] as int?,
      giSymptoms: (json['gi_symptoms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      notes: json['notes'] as String?,
    );
  }
}

class CycleStatusEntity {
  final String? currentCycleId;
  final int? dayInCycle;
  final String
      currentPhase; // menstrual, follicular, ovulatory, luteal, hormonally_managed
  final DateTime? predictedNextPeriod;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;
  final DateTime? ovulationDate;
  final bool isHormonallyManaged;
  final bool hasExtendedUncertainty;
  final String phaseDescriptionEs;
  final String dailyTipEs;

  const CycleStatusEntity({
    this.currentCycleId,
    this.dayInCycle,
    required this.currentPhase,
    this.predictedNextPeriod,
    this.fertileWindowStart,
    this.fertileWindowEnd,
    this.ovulationDate,
    required this.isHormonallyManaged,
    required this.hasExtendedUncertainty,
    required this.phaseDescriptionEs,
    required this.dailyTipEs,
  });

  factory CycleStatusEntity.fromJson(Map<String, dynamic> json) {
    return CycleStatusEntity(
      currentCycleId: json['current_cycle_id'] as String?,
      dayInCycle: json['day_in_cycle'] as int?,
      currentPhase: json['current_phase'] as String? ?? 'follicular',
      predictedNextPeriod: json['predicted_next_period'] != null
          ? DateTime.parse(json['predicted_next_period'] as String)
          : null,
      fertileWindowStart: json['fertile_window_start'] != null
          ? DateTime.parse(json['fertile_window_start'] as String)
          : null,
      fertileWindowEnd: json['fertile_window_end'] != null
          ? DateTime.parse(json['fertile_window_end'] as String)
          : null,
      ovulationDate: json['ovulation_date'] != null
          ? DateTime.parse(json['ovulation_date'] as String)
          : null,
      isHormonallyManaged: json['is_hormonally_managed'] as bool? ?? false,
      hasExtendedUncertainty:
          json['has_extended_uncertainty'] as bool? ?? false,
      phaseDescriptionEs: json['phase_description_es'] as String? ?? '',
      dailyTipEs: json['daily_tip_es'] as String? ?? '',
    );
  }
}

class FigoAlertEntity {
  final String alertType;
  final String severity; // info, attention, clinical_recommendation
  final String titleEs;
  final String descriptionEs;
  final String recommendationEs;
  final Map<String, dynamic> evidence;

  const FigoAlertEntity({
    required this.alertType,
    required this.severity,
    required this.titleEs,
    required this.descriptionEs,
    required this.recommendationEs,
    this.evidence = const {},
  });

  factory FigoAlertEntity.fromJson(Map<String, dynamic> json) {
    return FigoAlertEntity(
      alertType: json['alert_type'] as String,
      severity: json['severity'] as String,
      titleEs: json['title_es'] as String,
      descriptionEs: json['description_es'] as String,
      recommendationEs: json['recommendation_es'] as String,
      evidence: (json['evidence'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

class CycleOverviewEntity {
  final MenstrualCycleEntity? currentCycle;
  final CycleStatusEntity status;
  final List<FigoAlertEntity> alerts;
  final List<MenstrualCycleEntity> recentCycles;

  const CycleOverviewEntity({
    this.currentCycle,
    required this.status,
    this.alerts = const [],
    this.recentCycles = const [],
  });

  factory CycleOverviewEntity.fromJson(Map<String, dynamic> json) {
    return CycleOverviewEntity(
      currentCycle: json['current_cycle'] != null
          ? MenstrualCycleEntity.fromJson(
              json['current_cycle'] as Map<String, dynamic>)
          : null,
      status:
          CycleStatusEntity.fromJson(json['status'] as Map<String, dynamic>),
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((e) => FigoAlertEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recentCycles: (json['recent_cycles'] as List<dynamic>?)
              ?.map((e) =>
                  MenstrualCycleEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

enum CalendarDayMarker {
  recordedPeriod('recorded_period'),
  predictedPeriod('predicted_period'),
  fertileWindow('fertile_window'),
  predictedOvulation('predicted_ovulation'),
  spotting('spotting'),
  none('none');

  final String value;
  const CalendarDayMarker(this.value);

  static CalendarDayMarker fromValue(String val) =>
      CalendarDayMarker.values.firstWhere(
        (e) => e.value == val,
        orElse: () => CalendarDayMarker.none,
      );
}

enum FertilityProbability {
  none('none'),
  low('low'),
  medium('medium'),
  high('high');

  final String value;
  const FertilityProbability(this.value);

  static FertilityProbability fromValue(String val) =>
      FertilityProbability.values.firstWhere(
        (e) => e.value == val,
        orElse: () => FertilityProbability.none,
      );
}

enum CalendarDisplayMode {
  standardCycle('standard_cycle'),
  adolescenceFlexible('adolescence_flexible'),
  conceptionFertility('conception_fertility'),
  hormonallyManaged('hormonally_managed'),
  pregnancyGestational('pregnancy_gestational'),
  postpartumRecovery('postpartum_recovery'),
  perimenopauseStraw10('perimenopause_straw10'),
  seniorPreventive('senior_preventive');

  final String value;
  const CalendarDisplayMode(this.value);

  static CalendarDisplayMode fromValue(String val) =>
      CalendarDisplayMode.values.firstWhere(
        (e) => e.value == val,
        orElse: () => CalendarDisplayMode.standardCycle,
      );
}

class CalendarDayProjectionEntity {
  final DateTime date;
  final int? dayInCycle;
  final String? phase;
  final CalendarDayMarker dayMarker;
  final FertilityProbability fertilityProbability;
  final bool hasLoggedSymptoms;
  final String bleedingFlow;
  final int? pelvicPain;
  final String dailySummaryEs;
  final String phaseEducationEs;

  const CalendarDayProjectionEntity({
    required this.date,
    this.dayInCycle,
    this.phase,
    required this.dayMarker,
    required this.fertilityProbability,
    required this.hasLoggedSymptoms,
    required this.bleedingFlow,
    this.pelvicPain,
    required this.dailySummaryEs,
    required this.phaseEducationEs,
  });

  factory CalendarDayProjectionEntity.fromJson(Map<String, dynamic> json) {
    return CalendarDayProjectionEntity(
      date: DateTime.parse(json['date'] as String),
      dayInCycle: json['day_in_cycle'] as int?,
      phase: json['phase'] as String?,
      dayMarker: CalendarDayMarker.fromValue(
        json['day_marker'] as String? ?? 'none',
      ),
      fertilityProbability: FertilityProbability.fromValue(
        json['fertility_probability'] as String? ?? 'none',
      ),
      hasLoggedSymptoms: json['has_logged_symptoms'] as bool? ?? false,
      bleedingFlow: json['bleeding_flow'] as String? ?? 'none',
      pelvicPain: json['pelvic_pain'] as int?,
      dailySummaryEs: json['daily_summary_es'] as String? ?? '',
      phaseEducationEs: json['phase_education_es'] as String? ?? '',
    );
  }
}

class CalendarMonthProjectionEntity {
  final int year;
  final int month;
  final CalendarDisplayMode displayMode;
  final int estimatedCycleLengthDays;
  final int estimatedBleedingDurationDays;
  final bool isHormonallyManaged;
  final bool hasExtendedUncertainty;
  final int? currentCycleDay;
  final String? currentPhase;
  final DateTime? predictedNextPeriod;
  final DateTime? ovulationDate;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;
  final List<CalendarDayProjectionEntity> days;

  const CalendarMonthProjectionEntity({
    required this.year,
    required this.month,
    required this.displayMode,
    required this.estimatedCycleLengthDays,
    required this.estimatedBleedingDurationDays,
    required this.isHormonallyManaged,
    required this.hasExtendedUncertainty,
    this.currentCycleDay,
    this.currentPhase,
    this.predictedNextPeriod,
    this.ovulationDate,
    this.fertileWindowStart,
    this.fertileWindowEnd,
    required this.days,
  });

  factory CalendarMonthProjectionEntity.fromJson(Map<String, dynamic> json) {
    return CalendarMonthProjectionEntity(
      year: json['year'] as int,
      month: json['month'] as int,
      displayMode: CalendarDisplayMode.fromValue(
        json['display_mode'] as String? ?? 'standard_cycle',
      ),
      estimatedCycleLengthDays:
          json['estimated_cycle_length_days'] as int? ?? 28,
      estimatedBleedingDurationDays:
          json['estimated_bleeding_duration_days'] as int? ?? 5,
      isHormonallyManaged: json['is_hormonally_managed'] as bool? ?? false,
      hasExtendedUncertainty:
          json['has_extended_uncertainty'] as bool? ?? false,
      currentCycleDay: json['current_cycle_day'] as int?,
      currentPhase: json['current_phase'] as String?,
      predictedNextPeriod: json['predicted_next_period'] != null
          ? DateTime.parse(json['predicted_next_period'] as String)
          : null,
      ovulationDate: json['ovulation_date'] != null
          ? DateTime.parse(json['ovulation_date'] as String)
          : null,
      fertileWindowStart: json['fertile_window_start'] != null
          ? DateTime.parse(json['fertile_window_start'] as String)
          : null,
      fertileWindowEnd: json['fertile_window_end'] != null
          ? DateTime.parse(json['fertile_window_end'] as String)
          : null,
      days: (json['days'] as List<dynamic>?)
              ?.map((e) => CalendarDayProjectionEntity.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
