import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/pregnancy/domain/entities/pregnancy_entities.dart';
import 'package:uuid/uuid.dart';

abstract class IPregnancyRepository {
  Future<PregnancyEpisodeEntity?> getActiveEpisode(String userId);
  Future<void> saveEpisode(PregnancyEpisodeEntity episode);
  Future<void> saveVitals(MaternalVitalsEntity vitals);
  Future<List<MaternalVitalsEntity>> getRecentVitals(String episodeId,
      {int limit = 20});
  Future<void> saveContractionSession(ContractionSessionEntity session);
  Future<List<ContractionSessionEntity>> getContractionSessions(
      String episodeId);
  Future<void> saveKickSession(KickSessionEntity session);
  Future<List<KickSessionEntity>> getKickSessions(String episodeId);
  Future<BirthPlanEntity?> getBirthPlan(String episodeId);
  Future<void> saveBirthPlan(
      String episodeId, String userId, BirthPlanEntity plan);
  Future<List<PrenatalAppointmentEntity>> getAppointments(String episodeId);
  Future<void> saveAppointment(
      PrenatalAppointmentEntity appointment, String userId);
  Future<void> toggleAppointmentCompletion(
      String appointmentId, bool isCompleted);
}

class PregnancyRepositoryImpl implements IPregnancyRepository {
  final AppDatabase _db;
  final SyncCoordinator _syncCoordinator;
  final _uuid = const Uuid();

  PregnancyRepositoryImpl(this._db, this._syncCoordinator);

  @override
  Future<PregnancyEpisodeEntity?> getActiveEpisode(String userId) async {
    final query = _db.select(_db.pregnancyEpisodeEntries)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.isActive.equals(true))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)])
      ..limit(1);

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return PregnancyEpisodeEntity(
      id: row.id,
      userId: row.userId,
      clinicalEdd: row.clinicalEdd,
      lastMenstrualPeriod: row.lastMenstrualPeriod,
      ultrasoundEdd: row.ultrasoundEdd,
      isActive: row.isActive,
      startedAt: row.startedAt,
    );
  }

  @override
  Future<void> saveEpisode(PregnancyEpisodeEntity episode) async {
    final companion = PregnancyEpisodeEntriesCompanion(
      id: Value(episode.id),
      userId: Value(episode.userId),
      clinicalEdd: Value(episode.clinicalEdd),
      lastMenstrualPeriod: Value(episode.lastMenstrualPeriod),
      ultrasoundEdd: Value(episode.ultrasoundEdd),
      isActive: Value(episode.isActive),
      startedAt: Value(episode.startedAt),
      updatedAt: Value(DateTime.now()),
    );

    await _db
        .into(_db.pregnancyEpisodeEntries)
        .insertOnConflictUpdate(companion);

    final payload = {
      'last_menstrual_period': episode.lastMenstrualPeriod?.toIso8601String(),
      'ultrasound_edd': episode.ultrasoundEdd?.toIso8601String(),
      'clinical_edd': episode.clinicalEdd.toIso8601String(),
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'pregnancy_episode',
      entityId: episode.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<void> saveVitals(MaternalVitalsEntity vitals) async {
    final companion = MaternalVitalsEntriesCompanion(
      id: Value(vitals.id),
      pregnancyEpisodeId: Value(vitals.pregnancyEpisodeId),
      userId: const Value('current_user'),
      measuredAt: Value(vitals.measuredAt),
      gestationalWeeks: Value(vitals.gestationalWeeks),
      systolicMmhg: Value(vitals.systolicMmhg),
      diastolicMmhg: Value(vitals.diastolicMmhg),
      glucoseMgDl: Value(vitals.glucoseMgDl),
      glucoseTiming: Value(vitals.glucoseTiming),
      weightKg: Value(vitals.weightKg),
      symptomsJson: Value(jsonEncode(vitals.symptoms)),
      alertsJson: Value(jsonEncode(vitals.alerts.map((a) => a.toJson()).toList())),
      createdAt: Value(vitals.measuredAt),
    );

    await _db.into(_db.maternalVitalsEntries).insertOnConflictUpdate(companion);

    final payload = {
      'systolic_mmhg': vitals.systolicMmhg,
      'diastolic_mmhg': vitals.diastolicMmhg,
      'glucose_mg_dl': vitals.glucoseMgDl,
      'glucose_timing': vitals.glucoseTiming,
      'weight_kg': vitals.weightKg,
      'symptoms': vitals.symptoms,
      'measured_at': vitals.measuredAt.toIso8601String(),
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'maternal_vitals',
      entityId: vitals.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<List<MaternalVitalsEntity>> getRecentVitals(String episodeId,
      {int limit = 20}) async {
    final query = _db.select(_db.maternalVitalsEntries)
      ..where((tbl) => tbl.pregnancyEpisodeId.equals(episodeId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.measuredAt)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map((r) {
      final alertsRaw = jsonDecode(r.alertsJson) as List<dynamic>? ?? [];
      final alerts = alertsRaw
          .map((a) => MaternalAlertEntity.fromJson(a as Map<String, dynamic>))
          .toList();
      final symptomsRaw = jsonDecode(r.symptomsJson) as List<dynamic>? ?? [];
      final symptoms =
          symptomsRaw.map((s) => s as Map<String, dynamic>).toList();

      return MaternalVitalsEntity(
        id: r.id,
        pregnancyEpisodeId: r.pregnancyEpisodeId,
        measuredAt: r.measuredAt,
        gestationalWeeks: r.gestationalWeeks,
        systolicMmhg: r.systolicMmhg,
        diastolicMmhg: r.diastolicMmhg,
        glucoseMgDl: r.glucoseMgDl,
        glucoseTiming: r.glucoseTiming,
        weightKg: r.weightKg,
        symptoms: symptoms,
        alerts: alerts,
      );
    }).toList();
  }

  @override
  Future<void> saveContractionSession(ContractionSessionEntity session) async {
    final companion = ContractionSessionEntriesCompanion(
      id: Value(session.id),
      pregnancyEpisodeId: Value(session.pregnancyEpisodeId),
      userId: const Value('current_user'),
      startedAt: Value(session.startedAt),
      endedAt: Value(session.endedAt),
      gestationalWeeks: Value(session.gestationalWeeks),
      pattern: Value(session.pattern),
      totalContractions: Value(session.totalContractions),
      avgIntervalSeconds: Value(session.avgIntervalSeconds),
      avgDurationSeconds: Value(session.avgDurationSeconds),
      eventsJson: Value(jsonEncode(session.events)),
      alertJson: Value(
          session.alert != null ? jsonEncode(session.alert!.toJson()) : null),
      createdAt: Value(session.startedAt),
    );

    await _db
        .into(_db.contractionSessionEntries)
        .insertOnConflictUpdate(companion);

    final payload = {
      'events': session.events,
      'ended_at': session.endedAt?.toIso8601String(),
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'contraction_session',
      entityId: session.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<List<ContractionSessionEntity>> getContractionSessions(
      String episodeId) async {
    final query = _db.select(_db.contractionSessionEntries)
      ..where((tbl) => tbl.pregnancyEpisodeId.equals(episodeId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)]);

    final rows = await query.get();
    return rows.map((r) {
      MaternalAlertEntity? alert;
      if (r.alertJson != null) {
        alert = MaternalAlertEntity.fromJson(
            jsonDecode(r.alertJson!) as Map<String, dynamic>);
      }
      final eventsRaw = jsonDecode(r.eventsJson) as List<dynamic>? ?? [];
      final events = eventsRaw.map((e) => e as Map<String, dynamic>).toList();

      return ContractionSessionEntity(
        id: r.id,
        pregnancyEpisodeId: r.pregnancyEpisodeId,
        startedAt: r.startedAt,
        endedAt: r.endedAt,
        gestationalWeeks: r.gestationalWeeks,
        pattern: r.pattern,
        totalContractions: r.totalContractions,
        avgIntervalSeconds: r.avgIntervalSeconds,
        avgDurationSeconds: r.avgDurationSeconds,
        events: events,
        alert: alert,
      );
    }).toList();
  }

  @override
  Future<void> saveKickSession(KickSessionEntity session) async {
    final companion = KickSessionEntriesCompanion(
      id: Value(session.id),
      pregnancyEpisodeId: Value(session.pregnancyEpisodeId),
      userId: const Value('current_user'),
      startedAt: Value(session.startedAt),
      durationMinutes: Value(session.durationMinutes),
      gestationalWeeks: Value(session.gestationalWeeks),
      kicksCount: Value(session.kicksCount),
      targetReached: Value(session.targetReached),
      targetReachedAtMinutes: Value(session.targetReachedAtMinutes),
      isReassuring: Value(session.isReassuring),
      alertJson: Value(
          session.alert != null ? jsonEncode(session.alert!.toJson()) : null),
      createdAt: Value(session.startedAt),
    );

    await _db.into(_db.kickSessionEntries).insertOnConflictUpdate(companion);

    final payload = {
      'kicks_count': session.kicksCount,
      'duration_minutes': session.durationMinutes,
      'target_reached_at_minutes': session.targetReachedAtMinutes,
      'started_at': session.startedAt.toIso8601String(),
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'kick_session',
      entityId: session.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<List<KickSessionEntity>> getKickSessions(String episodeId) async {
    final query = _db.select(_db.kickSessionEntries)
      ..where((tbl) => tbl.pregnancyEpisodeId.equals(episodeId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)]);

    final rows = await query.get();
    return rows.map((r) {
      MaternalAlertEntity? alert;
      if (r.alertJson != null) {
        alert = MaternalAlertEntity.fromJson(
            jsonDecode(r.alertJson!) as Map<String, dynamic>);
      }

      return KickSessionEntity(
        id: r.id,
        pregnancyEpisodeId: r.pregnancyEpisodeId,
        startedAt: r.startedAt,
        durationMinutes: r.durationMinutes,
        gestationalWeeks: r.gestationalWeeks,
        kicksCount: r.kicksCount,
        targetReached: r.targetReached,
        targetReachedAtMinutes: r.targetReachedAtMinutes,
        isReassuring: r.isReassuring,
        alert: alert,
      );
    }).toList();
  }

  @override
  Future<BirthPlanEntity?> getBirthPlan(String episodeId) async {
    final query = _db.select(_db.birthPlanEntries)
      ..where((tbl) => tbl.pregnancyEpisodeId.equals(episodeId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final companions = (jsonDecode(row.companionPreferencesJson) as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final pain = (jsonDecode(row.painManagementJson) as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final env = (jsonDecode(row.deliveryEnvironmentJson) as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final post = (jsonDecode(row.immediatePostpartumJson) as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return BirthPlanEntity(
      companionPreferences: companions,
      painManagement: pain,
      deliveryEnvironment: env,
      immediatePostpartum: post,
      specialRequests: row.specialRequests,
    );
  }

  @override
  Future<void> saveBirthPlan(
      String episodeId, String userId, BirthPlanEntity plan) async {
    final companion = BirthPlanEntriesCompanion(
      pregnancyEpisodeId: Value(episodeId),
      userId: Value(userId),
      companionPreferencesJson: Value(jsonEncode(plan.companionPreferences)),
      painManagementJson: Value(jsonEncode(plan.painManagement)),
      deliveryEnvironmentJson: Value(jsonEncode(plan.deliveryEnvironment)),
      immediatePostpartumJson: Value(jsonEncode(plan.immediatePostpartum)),
      specialRequests: Value(plan.specialRequests),
      updatedAt: Value(DateTime.now()),
    );

    await _db.into(_db.birthPlanEntries).insertOnConflictUpdate(companion);

    final payload = {
      'companion_preferences': plan.companionPreferences,
      'pain_management': plan.painManagement,
      'delivery_environment': plan.deliveryEnvironment,
      'immediate_postpartum': plan.immediatePostpartum,
      'special_requests': plan.specialRequests,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'birth_plan',
      entityId: episodeId,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<List<PrenatalAppointmentEntity>> getAppointments(
      String episodeId) async {
    final query = _db.select(_db.prenatalAppointmentEntries)
      ..where((tbl) => tbl.pregnancyEpisodeId.equals(episodeId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.scheduledAt)]);

    final rows = await query.get();
    return rows.map((r) {
      final topics = (jsonDecode(r.topicsToDiscussJson) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      return PrenatalAppointmentEntity(
        id: r.id,
        pregnancyEpisodeId: r.pregnancyEpisodeId,
        scheduledAt: r.scheduledAt,
        doctorOrClinic: r.doctorOrClinic,
        gestationalWeek: r.gestationalWeek,
        topicsToDiscuss: topics,
        notes: r.notes,
        isCompleted: r.isCompleted,
      );
    }).toList();
  }

  @override
  Future<void> saveAppointment(
      PrenatalAppointmentEntity appointment, String userId) async {
    final companion = PrenatalAppointmentEntriesCompanion(
      id: Value(appointment.id),
      pregnancyEpisodeId: Value(appointment.pregnancyEpisodeId),
      userId: Value(userId),
      scheduledAt: Value(appointment.scheduledAt),
      doctorOrClinic: Value(appointment.doctorOrClinic),
      gestationalWeek: Value(appointment.gestationalWeek),
      topicsToDiscussJson: Value(jsonEncode(appointment.topicsToDiscuss)),
      notes: Value(appointment.notes),
      isCompleted: Value(appointment.isCompleted),
      updatedAt: Value(DateTime.now()),
    );

    await _db
        .into(_db.prenatalAppointmentEntries)
        .insertOnConflictUpdate(companion);

    final payload = {
      'scheduled_at': appointment.scheduledAt.toIso8601String(),
      'doctor_or_clinic': appointment.doctorOrClinic,
      'gestational_week': appointment.gestationalWeek,
      'topics_to_discuss': appointment.topicsToDiscuss,
      'notes': appointment.notes,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'prenatal_appointment',
      entityId: appointment.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<void> toggleAppointmentCompletion(
      String appointmentId, bool isCompleted) async {
    final updateQuery = _db.update(_db.prenatalAppointmentEntries)
      ..where((tbl) => tbl.id.equals(appointmentId));

    await updateQuery.write(PrenatalAppointmentEntriesCompanion(
      isCompleted: Value(isCompleted),
      updatedAt: Value(DateTime.now()),
    ));

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'prenatal_appointment_toggle',
      entityId: appointmentId,
      operation: 'upsert',
      payloadJson: jsonEncode({'is_completed': isCompleted}),
    );
  }
}
