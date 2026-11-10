import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mobile/core/database/app_database.dart' hide MilkStashEntry;
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/postpartum/domain/entities/postpartum_entities.dart';
import 'package:uuid/uuid.dart';

abstract class IPostpartumRepository {
  Future<void> saveRecoveryLog(PostpartumRecoveryLog log);
  Future<List<PostpartumRecoveryLog>> getRecentRecoveryLogs(String userId,
      {int limit = 20});
  Future<void> saveLactationSession(LactationSession session);
  Future<List<LactationSession>> getRecentLactationSessions(String userId,
      {int limit = 20});
  Future<void> saveMilkStashEntry(MilkStashEntry entry);
  Future<List<MilkStashEntry>> getActiveMilkStash(String userId);
  Future<void> markMilkStashConsumed(String stashId);
  Future<void> saveEpdsScreening(EpdsScreening screening);
  Future<EpdsScreening?> getLatestEpdsScreening(String userId);
}

class PostpartumRepositoryImpl implements IPostpartumRepository {
  final AppDatabase _db;
  final SyncCoordinator _syncCoordinator;
  final _uuid = const Uuid();

  PostpartumRepositoryImpl(this._db, this._syncCoordinator);

  @override
  Future<void> saveRecoveryLog(PostpartumRecoveryLog log) async {
    final companion = PostpartumRecoveryEntriesCompanion(
      id: Value(log.id),
      userId: Value(log.userId),
      loggedAt: Value(log.loggedAt),
      daysPostpartum: Value(log.daysPostpartum),
      lochiaStage: Value(log.lochiaStage.name),
      lochiaFlow: Value(log.lochiaFlow.toApiValue()),
      foulOdor: Value(log.foulOdor),
      maternalTemperatureC: Value(log.maternalTemperatureC),
      perinealWoundStatus: Value(log.perinealWoundStatus?.toApiValue()),
      cesareanWoundStatus: Value(log.cesareanWoundStatus?.toApiValue()),
      pelvicFloorSymptomsJson: Value(
        jsonEncode(log.pelvicFloorSymptoms.map((s) => s.toApiValue()).toList()),
      ),
      notes: Value(log.notes),
      alertsJson: Value(
        jsonEncode(log.alerts.map((a) => a.toJson()).toList()),
      ),
    );

    await _db
        .into(_db.postpartumRecoveryEntries)
        .insertOnConflictUpdate(companion);

    final payload = {
      'days_postpartum': log.daysPostpartum,
      'lochia_stage': log.lochiaStage.name,
      'lochia_flow': log.lochiaFlow.toApiValue(),
      'foul_odor': log.foulOdor,
      'maternal_temperature_c': log.maternalTemperatureC,
      'perineal_wound_status': log.perinealWoundStatus?.toApiValue(),
      'cesarean_wound_status': log.cesareanWoundStatus?.toApiValue(),
      'pelvic_floor_symptoms':
          log.pelvicFloorSymptoms.map((s) => s.toApiValue()).toList(),
      'notes': log.notes,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'postpartum_recovery_log',
      entityId: log.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<List<PostpartumRecoveryLog>> getRecentRecoveryLogs(String userId,
      {int limit = 20}) async {
    final query = _db.select(_db.postpartumRecoveryEntries)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.loggedAt)])
      ..limit(limit);

    final rows = await query.get();

    return rows.map((r) {
      final pelvicSymptomsRaw =
          (jsonDecode(r.pelvicFloorSymptomsJson) as List<dynamic>)
              .cast<String>();
      final alertsRaw =
          (jsonDecode(r.alertsJson) as List<dynamic>).cast<Map<String, dynamic>>();

      return PostpartumRecoveryLog(
        id: r.id,
        userId: r.userId,
        loggedAt: r.loggedAt,
        daysPostpartum: r.daysPostpartum,
        lochiaStage: LochiaStage.fromString(r.lochiaStage),
        lochiaFlow: LochiaFlow.fromString(r.lochiaFlow),
        foulOdor: r.foulOdor,
        maternalTemperatureC: r.maternalTemperatureC,
        perinealWoundStatus:
            PerinealWoundStatus.fromString(r.perinealWoundStatus),
        cesareanWoundStatus:
            CesareanWoundStatus.fromString(r.cesareanWoundStatus),
        pelvicFloorSymptoms: pelvicSymptomsRaw
            .map((s) => PelvicFloorSymptom.fromString(s))
            .toList(),
        notes: r.notes,
        alerts: alertsRaw
            .map((a) => PostpartumClinicalAlert.fromJson(a))
            .toList(),
      );
    }).toList();
  }

  @override
  Future<void> saveLactationSession(LactationSession session) async {
    final companion = LactationSessionEntriesCompanion(
      id: Value(session.id),
      userId: Value(session.userId),
      startedAt: Value(session.startedAt),
      endedAt: Value(session.endedAt),
      leftDurationSeconds: Value(session.leftDurationSeconds),
      rightDurationSeconds: Value(session.rightDurationSeconds),
      totalDurationSeconds: Value(session.totalDurationSeconds),
      lastOfferedBreast: Value(session.lastOfferedBreast.name),
      suggestedNextBreast: Value(session.suggestedNextBreast.name),
      bottleVolumeMl: Value(session.bottleVolumeMl),
      feedingType: Value(session.feedingType.toApiValue()),
      notes: Value(session.notes),
      createdAt: Value(DateTime.now()),
    );

    await _db
        .into(_db.lactationSessionEntries)
        .insertOnConflictUpdate(companion);

    final payload = {
      'started_at': session.startedAt.toIso8601String(),
      'ended_at': session.endedAt.toIso8601String(),
      'left_duration_seconds': session.leftDurationSeconds,
      'right_duration_seconds': session.rightDurationSeconds,
      'last_offered_breast': session.lastOfferedBreast.name,
      'bottle_volume_ml': session.bottleVolumeMl,
      'feeding_type': session.feedingType.toApiValue(),
      'notes': session.notes,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'lactation_session',
      entityId: session.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<List<LactationSession>> getRecentLactationSessions(String userId,
      {int limit = 20}) async {
    final query = _db.select(_db.lactationSessionEntries)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)])
      ..limit(limit);

    final rows = await query.get();

    return rows.map((r) {
      return LactationSession(
        id: r.id,
        userId: r.userId,
        startedAt: r.startedAt,
        endedAt: r.endedAt,
        leftDurationSeconds: r.leftDurationSeconds,
        rightDurationSeconds: r.rightDurationSeconds,
        totalDurationSeconds: r.totalDurationSeconds,
        lastOfferedBreast: OfferedBreast.fromString(r.lastOfferedBreast),
        suggestedNextBreast: OfferedBreast.fromString(r.suggestedNextBreast),
        bottleVolumeMl: r.bottleVolumeMl,
        feedingType: FeedingType.fromString(r.feedingType),
        notes: r.notes,
      );
    }).toList();
  }

  @override
  Future<void> saveMilkStashEntry(MilkStashEntry entry) async {
    final companion = MilkStashEntriesCompanion(
      id: Value(entry.id),
      userId: Value(entry.userId),
      pumpedAt: Value(entry.pumpedAt),
      volumeMl: Value(entry.volumeMl),
      storageLocation: Value(entry.storageLocation.toApiValue()),
      expiresAt: Value(entry.expiresAt),
      isConsumed: Value(entry.isConsumed),
      consumedAt: Value(entry.consumedAt),
      notes: Value(entry.notes),
      createdAt: Value(DateTime.now()),
    );

    await _db.into(_db.milkStashEntries).insertOnConflictUpdate(companion);

    final payload = {
      'pumped_at': entry.pumpedAt.toIso8601String(),
      'volume_ml': entry.volumeMl,
      'storage_location': entry.storageLocation.toApiValue(),
      'notes': entry.notes,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'milk_stash_entry',
      entityId: entry.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<List<MilkStashEntry>> getActiveMilkStash(String userId) async {
    final query = _db.select(_db.milkStashEntries)
      ..where((tbl) => tbl.userId.equals(userId) & tbl.isConsumed.equals(false))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.expiresAt)]);

    final rows = await query.get();

    return rows.map((r) {
      return MilkStashEntry(
        id: r.id,
        userId: r.userId,
        pumpedAt: r.pumpedAt,
        volumeMl: r.volumeMl,
        storageLocation: StorageLocation.fromString(r.storageLocation),
        expiresAt: r.expiresAt,
        isConsumed: r.isConsumed,
        consumedAt: r.consumedAt,
        notes: r.notes,
      );
    }).toList();
  }

  @override
  Future<void> markMilkStashConsumed(String stashId) async {
    final now = DateTime.now();
    await (_db.update(_db.milkStashEntries)
          ..where((tbl) => tbl.id.equals(stashId)))
        .write(
      MilkStashEntriesCompanion(
        isConsumed: const Value(true),
        consumedAt: Value(now),
      ),
    );

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'milk_stash_consume',
      entityId: stashId,
      operation: 'patch',
      payloadJson: jsonEncode({'is_consumed': true, 'consumed_at': now.toIso8601String()}),
    );
  }

  @override
  Future<void> saveEpdsScreening(EpdsScreening screening) async {
    final companion = EpdsScreeningEntriesCompanion(
      id: Value(screening.id),
      userId: Value(screening.userId),
      screenedAt: Value(screening.screenedAt),
      daysPostpartum: Value(screening.daysPostpartum),
      responsesJson: Value(jsonEncode(screening.responses)),
      totalScore: Value(screening.totalScore),
      item10Score: Value(screening.item10Score),
      selfHarmRisk: Value(screening.selfHarmRisk),
      severity: Value(screening.severity.name),
      clinicalSummary: Value(screening.clinicalSummary),
      actionRecommended: Value(screening.actionRecommended),
    );

    await _db
        .into(_db.epdsScreeningEntries)
        .insertOnConflictUpdate(companion);

    final payload = {
      'days_postpartum': screening.daysPostpartum,
      'responses': screening.responses,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'epds_screening',
      entityId: screening.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<EpdsScreening?> getLatestEpdsScreening(String userId) async {
    final query = _db.select(_db.epdsScreeningEntries)
      ..where((tbl) => tbl.userId.equals(userId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.screenedAt)])
      ..limit(1);

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final responsesMap =
        (jsonDecode(row.responsesJson) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int));

    return EpdsScreening(
      id: row.id,
      userId: row.userId,
      screenedAt: row.screenedAt,
      daysPostpartum: row.daysPostpartum,
      responses: responsesMap,
      totalScore: row.totalScore,
      item10Score: row.item10Score,
      selfHarmRisk: row.selfHarmRisk,
      severity: PostpartumAlertSeverity.fromString(row.severity),
      clinicalSummary: row.clinicalSummary,
      actionRecommended: row.actionRecommended,
    );
  }
}
