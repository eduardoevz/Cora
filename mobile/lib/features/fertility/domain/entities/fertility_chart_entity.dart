class DailyFertilityEntity {
  final String id;
  final String userId;
  final DateTime logDate;
  final double? bbtCelsius;
  final bool isDisturbed;
  final String? disturbanceReason;
  final String? measuredAtTime;
  final String? cervicalMucus;
  final String? lhResult;
  final bool intercourseHad;
  final String intercourseType;
  final String? notes;

  const DailyFertilityEntity({
    required this.id,
    required this.userId,
    required this.logDate,
    this.bbtCelsius,
    this.isDisturbed = false,
    this.disturbanceReason,
    this.measuredAtTime,
    this.cervicalMucus,
    this.lhResult,
    this.intercourseHad = false,
    this.intercourseType = 'none',
    this.notes,
  });

  double? get bbtFahrenheit {
    if (bbtCelsius == null) return null;
    final f = (bbtCelsius! * 9 / 5) + 32;
    return double.parse(f.toStringAsFixed(2));
  }

  bool get isFever => bbtCelsius != null && bbtCelsius! >= 38.0;

  DailyFertilityEntity copyWith({
    String? id,
    String? userId,
    DateTime? logDate,
    double? bbtCelsius,
    bool? isDisturbed,
    String? disturbanceReason,
    String? measuredAtTime,
    String? cervicalMucus,
    String? lhResult,
    bool? intercourseHad,
    String? intercourseType,
    String? notes,
  }) {
    return DailyFertilityEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      logDate: logDate ?? this.logDate,
      bbtCelsius: bbtCelsius ?? this.bbtCelsius,
      isDisturbed: isDisturbed ?? this.isDisturbed,
      disturbanceReason: disturbanceReason ?? this.disturbanceReason,
      measuredAtTime: measuredAtTime ?? this.measuredAtTime,
      cervicalMucus: cervicalMucus ?? this.cervicalMucus,
      lhResult: lhResult ?? this.lhResult,
      intercourseHad: intercourseHad ?? this.intercourseHad,
      intercourseType: intercourseType ?? this.intercourseType,
      notes: notes ?? this.notes,
    );
  }
}

class FertilityChartPoint {
  final DateTime logDate;
  final int cycleDay;
  final double? bbtCelsius;
  final double? bbtFahrenheit;
  final bool isDisturbed;
  final String? disturbanceReason;
  final String? cervicalMucus;
  final String? lhResult;
  final bool intercourseHad;
  final String intercourseType;

  const FertilityChartPoint({
    required this.logDate,
    required this.cycleDay,
    this.bbtCelsius,
    this.bbtFahrenheit,
    this.isDisturbed = false,
    this.disturbanceReason,
    this.cervicalMucus,
    this.lhResult,
    this.intercourseHad = false,
    this.intercourseType = 'none',
  });
}

class FertilityCycleChartData {
  final String? cycleId;
  final DateTime? cycleStartDate;
  final int? cycleDay;
  final String status;
  final double? coverlineCelsius;
  final double? coverlineFahrenheit;
  final DateTime? ovulationConfirmedDate;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;
  final bool isBiphasicShiftDetected;
  final String evaluationNotesEs;
  final String? activeSeekingGuidanceEs;
  final List<FertilityChartPoint> dailyEntries;

  const FertilityCycleChartData({
    this.cycleId,
    this.cycleStartDate,
    this.cycleDay,
    required this.status,
    this.coverlineCelsius,
    this.coverlineFahrenheit,
    this.ovulationConfirmedDate,
    this.fertileWindowStart,
    this.fertileWindowEnd,
    this.isBiphasicShiftDetected = false,
    required this.evaluationNotesEs,
    this.activeSeekingGuidanceEs,
    required this.dailyEntries,
  });
}

class PreconceptionChecklistEntity {
  final String userId;
  final bool takingFolicAcid;
  final int? folicAcidDoseMcg;
  final bool medicalCheckupDone;
  final bool rubellaImmunityChecked;
  final bool dentalCheckupDone;
  final bool toxicHabitsStopped;
  final bool partnerEvaluationPlanned;
  final int activeSeekingMonths;
  final DateTime updatedAt;

  const PreconceptionChecklistEntity({
    required this.userId,
    this.takingFolicAcid = false,
    this.folicAcidDoseMcg = 400,
    this.medicalCheckupDone = false,
    this.rubellaImmunityChecked = false,
    this.dentalCheckupDone = false,
    this.toxicHabitsStopped = false,
    this.partnerEvaluationPlanned = false,
    this.activeSeekingMonths = 0,
    required this.updatedAt,
  });

  bool get isFolicAcidAdequate =>
      takingFolicAcid && (folicAcidDoseMcg == null || folicAcidDoseMcg! >= 400);

  int get completionPercentage {
    final items = [
      isFolicAcidAdequate,
      medicalCheckupDone,
      rubellaImmunityChecked,
      dentalCheckupDone,
      toxicHabitsStopped,
      partnerEvaluationPlanned,
    ];
    final done = items.where((i) => i).length;
    return ((done / items.length) * 100).round();
  }

  PreconceptionChecklistEntity copyWith({
    String? userId,
    bool? takingFolicAcid,
    int? folicAcidDoseMcg,
    bool? medicalCheckupDone,
    bool? rubellaImmunityChecked,
    bool? dentalCheckupDone,
    bool? toxicHabitsStopped,
    bool? partnerEvaluationPlanned,
    int? activeSeekingMonths,
    DateTime? updatedAt,
  }) {
    return PreconceptionChecklistEntity(
      userId: userId ?? this.userId,
      takingFolicAcid: takingFolicAcid ?? this.takingFolicAcid,
      folicAcidDoseMcg: folicAcidDoseMcg ?? this.folicAcidDoseMcg,
      medicalCheckupDone: medicalCheckupDone ?? this.medicalCheckupDone,
      rubellaImmunityChecked:
          rubellaImmunityChecked ?? this.rubellaImmunityChecked,
      dentalCheckupDone: dentalCheckupDone ?? this.dentalCheckupDone,
      toxicHabitsStopped: toxicHabitsStopped ?? this.toxicHabitsStopped,
      partnerEvaluationPlanned:
          partnerEvaluationPlanned ?? this.partnerEvaluationPlanned,
      activeSeekingMonths: activeSeekingMonths ?? this.activeSeekingMonths,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
