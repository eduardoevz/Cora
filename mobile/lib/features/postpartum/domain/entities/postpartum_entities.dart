enum LochiaStage {
  rubra,
  serosa,
  alba,
  none;

  static LochiaStage fromString(String val) {
    return LochiaStage.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => LochiaStage.rubra,
    );
  }

  String get displayName {
    switch (this) {
      case LochiaStage.rubra:
        return 'Loquios Rojos (Rubra)';
      case LochiaStage.serosa:
        return 'Loquios Rosados/Marrones (Serosa)';
      case LochiaStage.alba:
        return 'Loquios Amarillos/Blancos (Alba)';
      case LochiaStage.none:
        return 'Sin Loquios';
    }
  }
}

enum LochiaFlow {
  none,
  light,
  moderate,
  heavy,
  severeHemorrhage;

  static LochiaFlow fromString(String val) {
    if (val.contains('heavy_soaking') || val.contains('hemorrhage')) {
      return LochiaFlow.severeHemorrhage;
    }
    return LochiaFlow.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => LochiaFlow.moderate,
    );
  }

  String toApiValue() {
    switch (this) {
      case LochiaFlow.none:
        return 'none';
      case LochiaFlow.light:
        return 'light';
      case LochiaFlow.moderate:
        return 'moderate';
      case LochiaFlow.heavy:
        return 'heavy';
      case LochiaFlow.severeHemorrhage:
        return 'severe_hemorrhage';
    }
  }

  String get displayName {
    switch (this) {
      case LochiaFlow.none:
        return 'Nulo / Ausente';
      case LochiaFlow.light:
        return 'Escaso (Manchado leve)';
      case LochiaFlow.moderate:
        return 'Moderado (Compresa normal)';
      case LochiaFlow.heavy:
        return 'Abundante (Llenado rápido)';
      case LochiaFlow.severeHemorrhage:
        return 'Alerta Hemorrágica (Empapa < 1h)';
    }
  }
}

enum PerinealWoundStatus {
  healingWell,
  mildPain,
  severePain,
  erythemaEdema,
  purulentDischarge,
  woundDehiscence,
  notApplicable;

  static PerinealWoundStatus fromString(String? val) {
    if (val == null) return PerinealWoundStatus.notApplicable;
    switch (val) {
      case 'healing_well':
        return PerinealWoundStatus.healingWell;
      case 'mild_pain':
        return PerinealWoundStatus.mildPain;
      case 'severe_pain':
        return PerinealWoundStatus.severePain;
      case 'erythema_edema':
        return PerinealWoundStatus.erythemaEdema;
      case 'purulent_discharge':
        return PerinealWoundStatus.purulentDischarge;
      case 'wound_dehiscence':
        return PerinealWoundStatus.woundDehiscence;
      default:
        return PerinealWoundStatus.notApplicable;
    }
  }

  String toApiValue() {
    switch (this) {
      case PerinealWoundStatus.healingWell:
        return 'healing_well';
      case PerinealWoundStatus.mildPain:
        return 'mild_pain';
      case PerinealWoundStatus.severePain:
        return 'severe_pain';
      case PerinealWoundStatus.erythemaEdema:
        return 'erythema_edema';
      case PerinealWoundStatus.purulentDischarge:
        return 'purulent_discharge';
      case PerinealWoundStatus.woundDehiscence:
        return 'wound_dehiscence';
      case PerinealWoundStatus.notApplicable:
        return 'not_applicable';
    }
  }

  String get displayName {
    switch (this) {
      case PerinealWoundStatus.healingWell:
        return 'Cicatrizando adecuadamente';
      case PerinealWoundStatus.mildPain:
        return 'Molestia o dolor leve';
      case PerinealWoundStatus.severePain:
        return 'Dolor intenso / tirantez marcada';
      case PerinealWoundStatus.erythemaEdema:
        return 'Enrojecimiento o hinchazón pronunciada';
      case PerinealWoundStatus.purulentDischarge:
        return 'Secreción amarillenta o purulenta';
      case PerinealWoundStatus.woundDehiscence:
        return 'Apertura de puntos (dehiscencia)';
      case PerinealWoundStatus.notApplicable:
        return 'No aplica (sin herida perineal)';
    }
  }
}

enum CesareanWoundStatus {
  intactClean,
  erythemaInduration,
  fluidDischarge,
  severePain,
  gapingDehiscence,
  notApplicable;

  static CesareanWoundStatus fromString(String? val) {
    if (val == null) return CesareanWoundStatus.notApplicable;
    switch (val) {
      case 'intact_clean':
        return CesareanWoundStatus.intactClean;
      case 'erythema_induration':
        return CesareanWoundStatus.erythemaInduration;
      case 'fluid_discharge':
        return CesareanWoundStatus.fluidDischarge;
      case 'severe_pain':
        return CesareanWoundStatus.severePain;
      case 'gaping_dehiscence':
        return CesareanWoundStatus.gapingDehiscence;
      default:
        return CesareanWoundStatus.notApplicable;
    }
  }

  String toApiValue() {
    switch (this) {
      case CesareanWoundStatus.intactClean:
        return 'intact_clean';
      case CesareanWoundStatus.erythemaInduration:
        return 'erythema_induration';
      case CesareanWoundStatus.fluidDischarge:
        return 'fluid_discharge';
      case CesareanWoundStatus.severePain:
        return 'severe_pain';
      case CesareanWoundStatus.gapingDehiscence:
        return 'gaping_dehiscence';
      case CesareanWoundStatus.notApplicable:
        return 'not_applicable';
    }
  }

  String get displayName {
    switch (this) {
      case CesareanWoundStatus.intactClean:
        return 'Herida intacta, seca y limpia';
      case CesareanWoundStatus.erythemaInduration:
        return 'Bordes enrojecidos o endurecidos';
      case CesareanWoundStatus.fluidDischarge:
        return 'Supuración de líquido o sangre';
      case CesareanWoundStatus.severePain:
        return 'Dolor punzante incapacitante';
      case CesareanWoundStatus.gapingDehiscence:
        return 'Bordes separados (apertura de herida)';
      case CesareanWoundStatus.notApplicable:
        return 'No aplica (parto vaginal)';
    }
  }
}

enum PelvicFloorSymptom {
  normal,
  urinaryIncontinence,
  fecalIncontinence,
  pelvicHeavinessProlapse,
  dyspareunia;

  static PelvicFloorSymptom fromString(String val) {
    switch (val) {
      case 'urinary_incontinence':
        return PelvicFloorSymptom.urinaryIncontinence;
      case 'fecal_incontinence':
        return PelvicFloorSymptom.fecalIncontinence;
      case 'pelvic_heaviness_prolapse':
        return PelvicFloorSymptom.pelvicHeavinessProlapse;
      case 'dyspareunia':
        return PelvicFloorSymptom.dyspareunia;
      default:
        return PelvicFloorSymptom.normal;
    }
  }

  String toApiValue() {
    switch (this) {
      case PelvicFloorSymptom.normal:
        return 'normal';
      case PelvicFloorSymptom.urinaryIncontinence:
        return 'urinary_incontinence';
      case PelvicFloorSymptom.fecalIncontinence:
        return 'fecal_incontinence';
      case PelvicFloorSymptom.pelvicHeavinessProlapse:
        return 'pelvic_heaviness_prolapse';
      case PelvicFloorSymptom.dyspareunia:
        return 'dyspareunia';
    }
  }

  String get displayName {
    switch (this) {
      case PelvicFloorSymptom.normal:
        return 'Tono y continencia normales';
      case PelvicFloorSymptom.urinaryIncontinence:
        return 'Pérdidas de orina (al toser/reír)';
      case PelvicFloorSymptom.fecalIncontinence:
        return 'Dificultad para retener gases o heces';
      case PelvicFloorSymptom.pelvicHeavinessProlapse:
        return 'Sensación de pesadez o bulto vaginal';
      case PelvicFloorSymptom.dyspareunia:
        return 'Molestia o dolor en relaciones sexuales';
    }
  }
}

enum StorageLocation {
  roomTemp,
  refrigerator,
  freezer,
  deepFreezer;

  static StorageLocation fromString(String val) {
    switch (val) {
      case 'room_temp':
        return StorageLocation.roomTemp;
      case 'refrigerator':
        return StorageLocation.refrigerator;
      case 'freezer':
        return StorageLocation.freezer;
      case 'deep_freezer':
        return StorageLocation.deepFreezer;
      default:
        return StorageLocation.refrigerator;
    }
  }

  String toApiValue() {
    switch (this) {
      case StorageLocation.roomTemp:
        return 'room_temp';
      case StorageLocation.refrigerator:
        return 'refrigerator';
      case StorageLocation.freezer:
        return 'freezer';
      case StorageLocation.deepFreezer:
        return 'deep_freezer';
    }
  }

  String get displayName {
    switch (this) {
      case StorageLocation.roomTemp:
        return 'Temperatura Ambiente (hasta 4 horas)';
      case StorageLocation.refrigerator:
        return 'Refrigerador (hasta 4 días)';
      case StorageLocation.freezer:
        return 'Congelador Estándar (hasta 6 meses)';
      case StorageLocation.deepFreezer:
        return 'Ultracongelador Profundo (hasta 12 meses)';
    }
  }
}

enum OfferedBreast {
  left,
  right,
  both,
  none;

  static OfferedBreast fromString(String val) {
    return OfferedBreast.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => OfferedBreast.none,
    );
  }

  String get displayName {
    switch (this) {
      case OfferedBreast.left:
        return 'Pecho Izquierdo';
      case OfferedBreast.right:
        return 'Pecho Derecho';
      case OfferedBreast.both:
        return 'Ambos Pechos';
      case OfferedBreast.none:
        return 'Ninguno / Extracción';
    }
  }
}

enum FeedingType {
  breastOnly,
  bottleExpressed,
  bottleFormula,
  mixed;

  static FeedingType fromString(String val) {
    switch (val) {
      case 'bottle_expressed':
        return FeedingType.bottleExpressed;
      case 'bottle_formula':
        return FeedingType.bottleFormula;
      case 'mixed':
        return FeedingType.mixed;
      default:
        return FeedingType.breastOnly;
    }
  }

  String toApiValue() {
    switch (this) {
      case FeedingType.breastOnly:
        return 'breast_only';
      case FeedingType.bottleExpressed:
        return 'bottle_expressed';
      case FeedingType.bottleFormula:
        return 'bottle_formula';
      case FeedingType.mixed:
        return 'mixed';
    }
  }

  String get displayName {
    switch (this) {
      case FeedingType.breastOnly:
        return 'Pecho Directo Exclusivo';
      case FeedingType.bottleExpressed:
        return 'Biberón con Leche Materna';
      case FeedingType.bottleFormula:
        return 'Biberón con Fórmula';
      case FeedingType.mixed:
        return 'Alimentación Mixta';
    }
  }
}

enum PostpartumAlertSeverity {
  routineObservation,
  highPriorityConsult,
  urgentEmergency,
  immediateCrisisSupport,
  reassuring;

  static PostpartumAlertSeverity fromString(String val) {
    switch (val) {
      case 'urgent_emergency':
        return PostpartumAlertSeverity.urgentEmergency;
      case 'immediate_crisis_support':
        return PostpartumAlertSeverity.immediateCrisisSupport;
      case 'high_priority_consult':
        return PostpartumAlertSeverity.highPriorityConsult;
      case 'routine_observation':
        return PostpartumAlertSeverity.routineObservation;
      default:
        return PostpartumAlertSeverity.reassuring;
    }
  }
}

class PostpartumClinicalAlert {
  final PostpartumAlertSeverity severity;
  final String category;
  final String title;
  final String message;
  final String actionRecommended;

  const PostpartumClinicalAlert({
    required this.severity,
    required this.category,
    required this.title,
    required this.message,
    required this.actionRecommended,
  });

  Map<String, dynamic> toJson() => {
        'severity': severity.name,
        'category': category,
        'title': title,
        'message': message,
        'action_recommended': actionRecommended,
      };

  factory PostpartumClinicalAlert.fromJson(Map<String, dynamic> json) {
    return PostpartumClinicalAlert(
      severity: PostpartumAlertSeverity.fromString(
        json['severity'] as String? ?? '',
      ),
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      actionRecommended: json['action_recommended'] as String? ?? '',
    );
  }
}

class PostpartumRecoveryLog {
  final String id;
  final String userId;
  final DateTime loggedAt;
  final int daysPostpartum;
  final LochiaStage lochiaStage;
  final LochiaFlow lochiaFlow;
  final bool foulOdor;
  final double? maternalTemperatureC;
  final PerinealWoundStatus? perinealWoundStatus;
  final CesareanWoundStatus? cesareanWoundStatus;
  final List<PelvicFloorSymptom> pelvicFloorSymptoms;
  final String? notes;
  final List<PostpartumClinicalAlert> alerts;

  const PostpartumRecoveryLog({
    required this.id,
    required this.userId,
    required this.loggedAt,
    required this.daysPostpartum,
    required this.lochiaStage,
    required this.lochiaFlow,
    this.foulOdor = false,
    this.maternalTemperatureC,
    this.perinealWoundStatus,
    this.cesareanWoundStatus,
    this.pelvicFloorSymptoms = const [],
    this.notes,
    this.alerts = const [],
  });
}

class LactationSession {
  final String id;
  final String userId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int leftDurationSeconds;
  final int rightDurationSeconds;
  final int totalDurationSeconds;
  final OfferedBreast lastOfferedBreast;
  final OfferedBreast suggestedNextBreast;
  final double? bottleVolumeMl;
  final FeedingType feedingType;
  final String? notes;

  const LactationSession({
    required this.id,
    required this.userId,
    required this.startedAt,
    required this.endedAt,
    this.leftDurationSeconds = 0,
    this.rightDurationSeconds = 0,
    required this.totalDurationSeconds,
    required this.lastOfferedBreast,
    required this.suggestedNextBreast,
    this.bottleVolumeMl,
    required this.feedingType,
    this.notes,
  });

  static OfferedBreast calculateNextBreast(OfferedBreast last) {
    if (last == OfferedBreast.left) return OfferedBreast.right;
    if (last == OfferedBreast.right) return OfferedBreast.left;
    return OfferedBreast.left;
  }
}

class MilkStashEntry {
  final String id;
  final String userId;
  final DateTime pumpedAt;
  final double volumeMl;
  final StorageLocation storageLocation;
  final DateTime expiresAt;
  final bool isConsumed;
  final DateTime? consumedAt;
  final String? notes;

  const MilkStashEntry({
    required this.id,
    required this.userId,
    required this.pumpedAt,
    required this.volumeMl,
    required this.storageLocation,
    required this.expiresAt,
    this.isConsumed = false,
    this.consumedAt,
    this.notes,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime => expiresAt.difference(DateTime.now());

  static DateTime calculateExpiration(
    DateTime pumpedAt,
    StorageLocation location,
  ) {
    switch (location) {
      case StorageLocation.roomTemp:
        return pumpedAt.add(const Duration(hours: 4));
      case StorageLocation.refrigerator:
        return pumpedAt.add(const Duration(days: 4));
      case StorageLocation.freezer:
        return pumpedAt.add(const Duration(days: 180));
      case StorageLocation.deepFreezer:
        return pumpedAt.add(const Duration(days: 365));
    }
  }
}

class EpdsScreening {
  final String id;
  final String userId;
  final DateTime screenedAt;
  final int daysPostpartum;
  final Map<String, int> responses;
  final int totalScore;
  final int item10Score;
  final bool selfHarmRisk;
  final PostpartumAlertSeverity severity;
  final String clinicalSummary;
  final String actionRecommended;

  const EpdsScreening({
    required this.id,
    required this.userId,
    required this.screenedAt,
    required this.daysPostpartum,
    required this.responses,
    required this.totalScore,
    required this.item10Score,
    required this.selfHarmRisk,
    required this.severity,
    required this.clinicalSummary,
    required this.actionRecommended,
  });
}

class PostpartumOfflineEvaluator {
  static List<PostpartumClinicalAlert> evaluate({
    required int daysPostpartum,
    required LochiaStage lochiaStage,
    required LochiaFlow lochiaFlow,
    required bool foulOdor,
    double? maternalTemperatureC,
    PerinealWoundStatus? perinealWoundStatus,
    CesareanWoundStatus? cesareanWoundStatus,
    List<PelvicFloorSymptom> pelvicFloorSymptoms = const [],
  }) {
    final alerts = <PostpartumClinicalAlert>[];

    // 1. Secondary Postpartum Hemorrhage
    if (lochiaFlow == LochiaFlow.severeHemorrhage) {
      alerts.add(
        const PostpartumClinicalAlert(
          severity: PostpartumAlertSeverity.urgentEmergency,
          category: 'secondary_postpartum_hemorrhage',
          title: 'Sospecha de Hemorragia Posparto Secundaria',
          message:
              'Empapar una compresa grande en menos de 1 hora requiere atención urgente.',
          actionRecommended:
              'Acude de inmediato a urgencias obstétricas sin demora.',
        ),
      );
    }

    // 2. Lochia progression abnormality
    if (daysPostpartum > 14 && lochiaStage == LochiaStage.rubra) {
      alerts.add(
        const PostpartumClinicalAlert(
          severity: PostpartumAlertSeverity.highPriorityConsult,
          category: 'lochia_progression',
          title: 'Loquios Rojos Persistentes',
          message:
              'A las 2 semanas del parto, los loquios habitualmente deben ser claros o ausentes.',
          actionRecommended:
              'Consulta con tu ginecología u obstetricia para descartar restos o subinvolución.',
        ),
      );
    }

    // 3. Endometritis / puerperal sepsis
    final hasFever =
        maternalTemperatureC != null && maternalTemperatureC >= 38.0;
    if (hasFever && foulOdor) {
      alerts.add(
        const PostpartumClinicalAlert(
          severity: PostpartumAlertSeverity.urgentEmergency,
          category: 'endometritis_infection',
          title: 'Alerta de Infección Puerperal (Endometritis)',
          message:
              'La combinación de fiebre materna (≥ 38.0°C) y loquios de olor fétido es señal de alarma.',
          actionRecommended:
              'Requiere evaluación médica hospitalaria inmediata para inicio de antibióticos.',
        ),
      );
    } else if (foulOdor) {
      alerts.add(
        const PostpartumClinicalAlert(
          severity: PostpartumAlertSeverity.highPriorityConsult,
          category: 'foul_lochia',
          title: 'Olor Fétido en Loquios',
          message: 'Los loquios no deben tener mal olor. Puede haber vaginosis o infección incipiente.',
          actionRecommended:
              'Monitorea tu temperatura corporal y agenda consulta prioritaria.',
        ),
      );
    } else if (hasFever) {
      alerts.add(
        const PostpartumClinicalAlert(
          severity: PostpartumAlertSeverity.highPriorityConsult,
          category: 'puerperal_fever',
          title: 'Fiebre Puerperal',
          message: 'Temperatura superior a 38.0°C en el posparto.',
          actionRecommended:
              'Consulta a tu equipo médico para descartar mastitis, infección urinaria o herida.',
        ),
      );
    }

    // 4. Perineal wound
    if (perinealWoundStatus == PerinealWoundStatus.woundDehiscence ||
        perinealWoundStatus == PerinealWoundStatus.purulentDischarge) {
      alerts.add(
        const PostpartumClinicalAlert(
          severity: PostpartumAlertSeverity.urgentEmergency,
          category: 'perineal_wound_complication',
          title: 'Complicación en Desgarro o Episiotomía',
          message: 'Secreción purulenta o separación de suturas perineales.',
          actionRecommended:
              'Acude a revisión presencial hoy mismo para valoración de la herida.',
        ),
      );
    }

    // 5. Cesarean wound
    if (cesareanWoundStatus == CesareanWoundStatus.gapingDehiscence ||
        cesareanWoundStatus == CesareanWoundStatus.fluidDischarge) {
      alerts.add(
        const PostpartumClinicalAlert(
          severity: PostpartumAlertSeverity.urgentEmergency,
          category: 'cesarean_wound_complication',
          title: 'Complicación en Cicatriz de Cesárea',
          message: 'Apertura de bordes o salida activa de líquido en herida quirúrgica.',
          actionRecommended:
              'Acude a urgencias para evitar infección profunda o dehiscencia de pared.',
        ),
      );
    }

    // 6. Pelvic floor
    if (pelvicFloorSymptoms.contains(PelvicFloorSymptom.fecalIncontinence) ||
        pelvicFloorSymptoms
            .contains(PelvicFloorSymptom.pelvicHeavinessProlapse)) {
      alerts.add(
        const PostpartumClinicalAlert(
          severity: PostpartumAlertSeverity.highPriorityConsult,
          category: 'pelvic_floor_dysfunction',
          title: 'Síntoma Significativo de Suelo Pélvico',
          message: 'Incontinencia fecal o sensación de bulto requieren valoración experta.',
          actionRecommended:
              'Consulta con fisioterapia de suelo pélvico especializada en posparto.',
        ),
      );
    }

    return alerts;
  }
}

class EpdsOfflineScoringService {
  static EpdsScreening evaluate({
    required String id,
    required String userId,
    required int daysPostpartum,
    required Map<String, int> responses,
  }) {
    // Normal items: 1, 2, 4 (0, 1, 2, 3)
    // Reverse items: 3, 5, 6, 7, 8, 9, 10 (3, 2, 1, 0)
    final itemScores = <String, int>{
      'item_1': responses['item_1'] ?? 0,
      'item_2': responses['item_2'] ?? 0,
      'item_3': 3 - (responses['item_3'] ?? 3),
      'item_4': responses['item_4'] ?? 0,
      'item_5': 3 - (responses['item_5'] ?? 3),
      'item_6': 3 - (responses['item_6'] ?? 3),
      'item_7': 3 - (responses['item_7'] ?? 3),
      'item_8': 3 - (responses['item_8'] ?? 3),
      'item_9': 3 - (responses['item_9'] ?? 3),
      'item_10': 3 - (responses['item_10'] ?? 3),
    };

    final totalScore = itemScores.values.fold<int>(0, (sum, val) => sum + val);
    final item10Score = itemScores['item_10'] ?? 0;
    final selfHarmRisk = item10Score > 0;

    PostpartumAlertSeverity severity;
    String summary;
    String action;

    if (selfHarmRisk) {
      severity = PostpartumAlertSeverity.immediateCrisisSupport;
      summary =
          'Puntaje global EPDS: $totalScore/30 con respuesta positiva en pensamientos de autolesión (ítem 10 = $item10Score pts).';
      action =
          'Por favor, comunícate de inmediato con una línea de apoyo en crisis, acude a urgencias o contacta a un profesional de salud mental perinatal. No estás sola y hay acompañamiento disponible.';
    } else if (totalScore >= 13) {
      severity = PostpartumAlertSeverity.highPriorityConsult;
      summary =
          'Puntaje global EPDS: $totalScore/30 (Riesgo alto de depresión posparto mayor).';
      action =
          'Se recomienda derivación prioritaria para valoración clínica diagnóstica y apoyo multidisciplinario.';
    } else if (totalScore >= 10) {
      severity = PostpartumAlertSeverity.routineObservation;
      summary =
          'Puntaje global EPDS: $totalScore/30 (Sintomatología depresiva moderada / corte preventivo).';
      action =
          'Se aconseja seguimiento cercano en 1-2 semanas y evaluación por profesional de atención primaria.';
    } else {
      severity = PostpartumAlertSeverity.reassuring;
      summary =
          'Puntaje global EPDS: $totalScore/30 (Sin evidencia de sintomatología depresiva clínicamente significativa).';
      action =
          'Continuar con los cuidados generales del posparto y tamizaje de rutina si surgen nuevas dudas.';
    }

    return EpdsScreening(
      id: id,
      userId: userId,
      screenedAt: DateTime.now(),
      daysPostpartum: daysPostpartum,
      responses: responses,
      totalScore: totalScore,
      item10Score: item10Score,
      selfHarmRisk: selfHarmRisk,
      severity: severity,
      clinicalSummary: summary,
      actionRecommended: action,
    );
  }
}
