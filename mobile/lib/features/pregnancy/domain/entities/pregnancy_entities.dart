class MaternalAlertEntity {
  final String severity;
  final String category;
  final String title;
  final String message;
  final String actionRecommended;

  const MaternalAlertEntity({
    required this.severity,
    required this.category,
    required this.title,
    required this.message,
    required this.actionRecommended,
  });

  factory MaternalAlertEntity.fromJson(Map<String, dynamic> json) {
    return MaternalAlertEntity(
      severity: json['severity'] as String? ?? 'info',
      category: json['category'] as String? ?? 'general_obstetric',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      actionRecommended: json['action_recommended'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'severity': severity,
        'category': category,
        'title': title,
        'message': message,
        'action_recommended': actionRecommended,
      };
}

class PregnancyEpisodeEntity {
  final String id;
  final String userId;
  final DateTime clinicalEdd;
  final DateTime? lastMenstrualPeriod;
  final DateTime? ultrasoundEdd;
  final bool isActive;
  final DateTime startedAt;

  const PregnancyEpisodeEntity({
    required this.id,
    required this.userId,
    required this.clinicalEdd,
    this.lastMenstrualPeriod,
    this.ultrasoundEdd,
    this.isActive = true,
    required this.startedAt,
  });
}

class FetalMilestoneEntity {
  final int week;
  final String fruitComparison;
  final double approximateLengthCm;
  final double approximateWeightGrams;
  final String anatomicalHighlights;
  final String clinicalRecommendations;
  final List<String> suggestedTests;

  const FetalMilestoneEntity({
    required this.week,
    required this.fruitComparison,
    required this.approximateLengthCm,
    required this.approximateWeightGrams,
    required this.anatomicalHighlights,
    required this.clinicalRecommendations,
    this.suggestedTests = const [],
  });

  factory FetalMilestoneEntity.fromJson(Map<String, dynamic> json) {
    return FetalMilestoneEntity(
      week: json['week'] as int? ?? 4,
      fruitComparison: json['fruit_comparison'] as String? ?? '',
      approximateLengthCm: (json['approximate_length_cm'] as num?)?.toDouble() ?? 0.0,
      approximateWeightGrams:
          (json['approximate_weight_grams'] as num?)?.toDouble() ?? 0.0,
      anatomicalHighlights: json['anatomical_highlights'] as String? ?? '',
      clinicalRecommendations:
          json['clinical_recommendations'] as String? ?? '',
      suggestedTests: (json['suggested_tests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class MaternalVitalsEntity {
  final String id;
  final String pregnancyEpisodeId;
  final DateTime measuredAt;
  final int gestationalWeeks;
  final int? systolicMmhg;
  final int? diastolicMmhg;
  final double? glucoseMgDl;
  final String? glucoseTiming;
  final double? weightKg;
  final List<Map<String, dynamic>> symptoms;
  final List<MaternalAlertEntity> alerts;

  const MaternalVitalsEntity({
    required this.id,
    required this.pregnancyEpisodeId,
    required this.measuredAt,
    required this.gestationalWeeks,
    this.systolicMmhg,
    this.diastolicMmhg,
    this.glucoseMgDl,
    this.glucoseTiming,
    this.weightKg,
    this.symptoms = const [],
    this.alerts = const [],
  });
}

class ContractionSessionEntity {
  final String id;
  final String pregnancyEpisodeId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int gestationalWeeks;
  final String pattern;
  final int totalContractions;
  final double? avgIntervalSeconds;
  final double? avgDurationSeconds;
  final List<Map<String, dynamic>> events;
  final MaternalAlertEntity? alert;

  const ContractionSessionEntity({
    required this.id,
    required this.pregnancyEpisodeId,
    required this.startedAt,
    this.endedAt,
    required this.gestationalWeeks,
    required this.pattern,
    required this.totalContractions,
    this.avgIntervalSeconds,
    this.avgDurationSeconds,
    this.events = const [],
    this.alert,
  });
}

class KickSessionEntity {
  final String id;
  final String pregnancyEpisodeId;
  final DateTime startedAt;
  final int durationMinutes;
  final int gestationalWeeks;
  final int kicksCount;
  final bool targetReached;
  final int? targetReachedAtMinutes;
  final bool isReassuring;
  final MaternalAlertEntity? alert;

  const KickSessionEntity({
    required this.id,
    required this.pregnancyEpisodeId,
    required this.startedAt,
    required this.durationMinutes,
    required this.gestationalWeeks,
    required this.kicksCount,
    required this.targetReached,
    this.targetReachedAtMinutes,
    required this.isReassuring,
    this.alert,
  });
}

class BirthPlanEntity {
  final List<String> companionPreferences;
  final List<String> painManagement;
  final List<String> deliveryEnvironment;
  final List<String> immediatePostpartum;
  final String? specialRequests;

  const BirthPlanEntity({
    this.companionPreferences = const [],
    this.painManagement = const [],
    this.deliveryEnvironment = const [],
    this.immediatePostpartum = const [],
    this.specialRequests,
  });
}

class PrenatalAppointmentEntity {
  final String id;
  final String pregnancyEpisodeId;
  final DateTime scheduledAt;
  final String doctorOrClinic;
  final int gestationalWeek;
  final List<String> topicsToDiscuss;
  final String? notes;
  final bool isCompleted;

  const PrenatalAppointmentEntity({
    required this.id,
    required this.pregnancyEpisodeId,
    required this.scheduledAt,
    required this.doctorOrClinic,
    required this.gestationalWeek,
    this.topicsToDiscuss = const [],
    this.notes,
    this.isCompleted = false,
  });
}

class MaternalOfflineEvaluator {
  static const severeSymptoms = {
    'persistent_severe_headache',
    'scotomas_visual_blur',
    'epigastric_ruq_pain',
    'sudden_facial_hand_edema',
  };

  static List<MaternalAlertEntity> evaluateOffline({
    int? systolic,
    int? diastolic,
    double? glucose,
    String? timing,
    List<String> symptoms = const [],
  }) {
    final alerts = <MaternalAlertEntity>[];

    if (systolic != null && diastolic != null) {
      if (systolic >= 160 || diastolic >= 110) {
        alerts.add(const MaternalAlertEntity(
          severity: 'urgent_emergency',
          category: 'preeclampsia_risk',
          title: 'Crisis Hipertensiva / Sospecha de Preeclampsia Severa',
          message:
              'Cifras tensionales en rango de severidad (>= 160/110 mmHg).',
          actionRecommended:
              'Acudir de inmediato al servicio de urgencias obstétricas.',
        ));
      } else if (systolic >= 140 || diastolic >= 90) {
        final hasSevereSymp = symptoms.any((s) => severeSymptoms.contains(s));
        if (hasSevereSymp) {
          alerts.add(const MaternalAlertEntity(
            severity: 'urgent_emergency',
            category: 'preeclampsia_risk',
            title: 'Preeclampsia con signos de alarma',
            message:
                'Presión elevada acompañada de cefalea severa, alteraciones visuales o dolor abdominal.',
            actionRecommended:
                'Acudir inmediatamente a valoración de urgencias obstétricas.',
          ));
        } else {
          alerts.add(const MaternalAlertEntity(
            severity: 'priority_consult',
            category: 'preeclampsia_risk',
            title: 'Hipertensión gestacional / Cifras tensionales elevadas',
            message:
                'Presión por encima del límite normal seguro (>= 140/90 mmHg).',
            actionRecommended:
                'Reposo 15 minutos sobre el lado izquierdo y repetir medición.',
          ));
        }
      }
    }

    if (glucose != null && timing != null) {
      if (timing == 'fasting' && glucose >= 95.0) {
        alerts.add(const MaternalAlertEntity(
          severity: 'priority_consult',
          category: 'gestational_diabetes_risk',
          title: 'Glucemia Basal Elevada',
          message: 'Glucemia en ayunas superior a 95 mg/dL.',
          actionRecommended:
              'Compartir este valor con su obstetra en el próximo control.',
        ));
      } else if (timing == 'postprandial_1h' && glucose >= 140.0) {
        alerts.add(const MaternalAlertEntity(
          severity: 'priority_consult',
          category: 'gestational_diabetes_risk',
          title: 'Glucemia Posprandial (1h) Elevada',
          message: 'Glucemia a 1 hora superior a 140 mg/dL.',
          actionRecommended: 'Comentar el valor para valorar plan nutricional.',
        ));
      } else if (timing == 'postprandial_2h' && glucose >= 120.0) {
        alerts.add(const MaternalAlertEntity(
          severity: 'priority_consult',
          category: 'gestational_diabetes_risk',
          title: 'Glucemia Posprandial (2h) Elevada',
          message: 'Glucemia a 2 horas superior a 120 mg/dL.',
          actionRecommended:
              'Registrar el valor para el próximo control prenatal.',
        ));
      }
    }

    return alerts;
  }

  static ({
    String pattern,
    MaternalAlertEntity? alert,
    double avgIntervalMinutes,
    double avgDurationSeconds,
    int totalContractions,
  }) evaluateContractions({
    required List<Map<String, dynamic>> events,
    required int gestationalWeeks,
  }) {
    if (events.length < 2) {
      final avgDur = events.isNotEmpty
          ? (events.first['duration_seconds'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      return (
        pattern: 'insufficient_data',
        alert: null,
        avgIntervalMinutes: 0.0,
        avgDurationSeconds: avgDur,
        totalContractions: events.length,
      );
    }

    // Sort events by started_at
    final sorted = List<Map<String, dynamic>>.from(events)
      ..sort((a, b) {
        final aTime = DateTime.parse(a['started_at'] as String);
        final bTime = DateTime.parse(b['started_at'] as String);
        return aTime.compareTo(bTime);
      });

    final total = sorted.length;
    final intervalsSec = <double>[];
    for (int i = 1; i < total; i++) {
      final t1 = DateTime.parse(sorted[i]['started_at'] as String);
      final t0 = DateTime.parse(sorted[i - 1]['started_at'] as String);
      intervalsSec.add(t1.difference(t0).inSeconds.toDouble());
    }

    final avgIntervalMin =
        (intervalsSec.reduce((a, b) => a + b) / intervalsSec.length) / 60.0;
    final totalDur = sorted
        .map((e) => (e['duration_seconds'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a + b);
    final avgDurationSec = totalDur / total;

    // 1. Preterm risk (< 37 weeks)
    if (gestationalWeeks < 37) {
      bool isPretermRisk = false;
      for (int i = 0; i < total; i++) {
        final t0 = DateTime.parse(sorted[i]['started_at'] as String);
        final count20m = sorted.where((e) {
          final diff = DateTime.parse(e['started_at'] as String)
              .difference(t0)
              .inSeconds;
          return diff >= 0 && diff <= 1200;
        }).length;
        final count60m = sorted.where((e) {
          final diff = DateTime.parse(e['started_at'] as String)
              .difference(t0)
              .inSeconds;
          return diff >= 0 && diff <= 3600;
        }).length;
        if (count20m >= 4 || count60m >= 8) {
          isPretermRisk = true;
          break;
        }
      }

      if (isPretermRisk) {
        return (
          pattern: 'preterm_labor_risk',
          alert: MaternalAlertEntity(
            severity: 'urgent_emergency',
            category: 'preterm_labor_risk',
            title: 'Contracciones Regulares / Riesgo Pretérmino',
            message:
                'Se registran $total contracciones regulares a las $gestationalWeeks semanas. Riesgo de parto pretérmino.',
            actionRecommended:
                'Acudir de inmediato a urgencias obstétricas para evaluación con tocodinamometría.',
          ),
          avgIntervalMinutes: avgIntervalMin,
          avgDurationSeconds: avgDurationSec,
          totalContractions: total,
        );
      }
    }

    // 2. Term 5-1-1 Rule (>= 37 weeks)
    final is511 = avgIntervalMin <= 5.0 && avgDurationSec >= 60.0 && total >= 8;
    if (is511) {
      return (
        pattern: 'active_labor_511',
        alert: MaternalAlertEntity(
          severity: 'priority_consult',
          category: 'general_obstetric',
          title: 'Patrón 5-1-1: Trabajo de Parto Activo',
          message:
              'Contracciones regulares cada ${avgIntervalMin.toStringAsFixed(1)} min, con ${avgDurationSec.toStringAsFixed(0)} s de duración.',
          actionRecommended:
              'Momento oportuno para contactar a tu equipo obstétrico o trasladarte a la maternidad.',
        ),
        avgIntervalMinutes: avgIntervalMin,
        avgDurationSeconds: avgDurationSec,
        totalContractions: total,
      );
    }

    if (avgIntervalMin <= 10.0 && total >= 4) {
      return (
        pattern: 'regular_early',
        alert: null,
        avgIntervalMinutes: avgIntervalMin,
        avgDurationSeconds: avgDurationSec,
        totalContractions: total,
      );
    }

    return (
      pattern: 'irregular_or_early',
      alert: null,
      avgIntervalMinutes: avgIntervalMin,
      avgDurationSeconds: avgDurationSec,
      totalContractions: total,
    );
  }

  static ({
    bool isReassuring,
    bool targetReached,
    MaternalAlertEntity? alert,
  }) evaluateKicks({
    required int kicksCount,
    required int durationMinutes,
  }) {
    if (kicksCount >= 10) {
      return (
        isReassuring: true,
        targetReached: true,
        alert: null,
      );
    }

    if (durationMinutes >= 120 && kicksCount < 10) {
      return (
        isReassuring: false,
        targetReached: false,
        alert: MaternalAlertEntity(
          severity: 'urgent_emergency',
          category: 'fetal_wellbeing_risk',
          title: 'Disminución de Movimientos Fetales (Cardiff < 10)',
          message:
              'Solo $kicksCount movimientos fetales en $durationMinutes min (meta: 10 en <= 120 min).',
          actionRecommended:
              'Estimular al bebé con algo frío o dulce y recostarse sobre el lado izquierdo. Si persiste, acudir a urgencias obstétricas.',
        ),
      );
    }

    return (
      isReassuring: true,
      targetReached: false,
      alert: null,
    );
  }
}
