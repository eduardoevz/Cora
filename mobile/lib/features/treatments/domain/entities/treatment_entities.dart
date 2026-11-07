class TreatmentRegimenEntity {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String dosage;
  final String scheduleType;
  final String scheduledTime;
  final int? activeDays;
  final int? breakDays;
  final int? intervalDays;
  final DateTime? replacementDate;
  final String? instructions;
  final DateTime startDate;
  final DateTime? endDate;
  final bool reminderEnabled;
  final bool discreetNotification;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TreatmentRegimenEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.dosage,
    required this.scheduleType,
    required this.scheduledTime,
    this.activeDays,
    this.breakDays,
    this.intervalDays,
    this.replacementDate,
    this.instructions,
    required this.startDate,
    this.endDate,
    this.reminderEnabled = true,
    this.discreetNotification = true,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'dosage': dosage,
      'schedule_type': scheduleType,
      'scheduled_time': scheduledTime,
      'active_days': activeDays,
      'break_days': breakDays,
      'interval_days': intervalDays,
      'replacement_date': replacementDate?.toIso8601String(),
      'instructions': instructions,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'reminder_enabled': reminderEnabled,
      'discreet_notification': discreetNotification,
      'is_active': isActive,
    };
  }
}

class DoseIntakeEntity {
  final String id;
  final String regimenId;
  final DateTime scheduledFor;
  final DateTime? takenAt;
  final String status;
  final String? notes;
  final String? clientMutationId;
  final DateTime? createdAt;

  const DoseIntakeEntity({
    required this.id,
    required this.regimenId,
    required this.scheduledFor,
    this.takenAt,
    required this.status,
    this.notes,
    this.clientMutationId,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'regimen_id': regimenId,
      'scheduled_for': scheduledFor.toIso8601String(),
      'taken_at': takenAt?.toIso8601String(),
      'status': status,
      'notes': notes,
      'client_mutation_id': clientMutationId,
    };
  }
}
