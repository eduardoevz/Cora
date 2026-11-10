import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/menopause/domain/models/cardiometabolic_panel.dart';
import 'package:mobile/features/menopause/domain/models/hot_flash_episode.dart';
import 'package:mobile/features/menopause/domain/models/vaginal_bleeding_record.dart';
import 'package:uuid/uuid.dart';

abstract class IMenopauseRepository {
  Future<void> saveHotFlash(HotFlashEpisode episode);
  Future<List<HotFlashEpisode>> getRecentHotFlashes(String userId,
      {int limit = 50});
  Future<void> saveCardiometabolicPanel(CardiometabolicPanel panel);
  Future<CardiometabolicPanel?> getLatestCardiometabolicPanel(String userId);
  Future<void> saveVaginalBleeding(VaginalBleedingRecord record);
  Future<List<VaginalBleedingRecord>> getRecentBleedingRecords(String userId,
      {int limit = 50});
}

class MenopauseRepositoryImpl implements IMenopauseRepository {
  final AppDatabase _db;
  final SyncCoordinator _syncCoordinator;
  final _uuid = const Uuid();

  MenopauseRepositoryImpl(this._db, this._syncCoordinator);

  @override
  Future<void> saveHotFlash(HotFlashEpisode episode) async {
    final companion = HotFlashEntriesCompanion(
      id: Value(episode.id),
      userId: Value(episode.userId),
      occurredAt: Value(episode.occurredAt),
      severity: Value(episode.severity.value),
      flashType: Value(episode.flashType.value),
      durationMinutes: Value(episode.durationMinutes),
      triggersJson: Value(jsonEncode(episode.triggers)),
      sleepDisruptionLevel: Value(episode.sleepDisruptionLevel),
      associatedWithHrt: Value(episode.associatedWithHrt),
      notes: Value(episode.notes),
    );

    await _db.into(_db.hotFlashEntries).insertOnConflictUpdate(companion);

    final payload = {
      'id': episode.id,
      'occurred_at': episode.occurredAt.toUtc().toIso8601String(),
      'severity': episode.severity.value,
      'flash_type': episode.flashType.value,
      'duration_minutes': episode.durationMinutes,
      'triggers': episode.triggers,
      'sleep_disruption_level': episode.sleepDisruptionLevel,
      'associated_with_hrt': episode.associatedWithHrt,
      'notes': episode.notes,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'hot_flash',
      entityId: episode.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<List<HotFlashEpisode>> getRecentHotFlashes(String userId,
      {int limit = 50}) async {
    final query = _db.select(_db.hotFlashEntries)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([
        (t) =>
            OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc)
      ])
      ..limit(limit);

    final rows = await query.get();
    return rows.map((r) {
      final List<dynamic> rawTriggers =
          jsonDecode(r.triggersJson) as List<dynamic>;
      return HotFlashEpisode(
        id: r.id,
        userId: r.userId,
        occurredAt: r.occurredAt,
        severity: HotFlashSeverity.fromValue(r.severity),
        flashType: HotFlashType.fromValue(r.flashType),
        durationMinutes: r.durationMinutes,
        triggers: rawTriggers.map((e) => e.toString()).toList(),
        sleepDisruptionLevel: r.sleepDisruptionLevel,
        associatedWithHrt: r.associatedWithHrt,
        notes: r.notes,
      );
    }).toList();
  }

  @override
  Future<void> saveCardiometabolicPanel(CardiometabolicPanel panel) async {
    final companion = CardiometabolicEntriesCompanion(
      id: Value(panel.id),
      userId: Value(panel.userId),
      measurementDate: Value(panel.measurementDate),
      systolicBp: Value(panel.systolicBp),
      diastolicBp: Value(panel.diastolicBp),
      totalCholesterol: Value(panel.totalCholesterol),
      ldlCholesterol: Value(panel.ldlCholesterol),
      hdlCholesterol: Value(panel.hdlCholesterol),
      triglycerides: Value(panel.triglycerides),
      fastingGlucose: Value(panel.fastingGlucose),
      riskLevel: Value(panel.riskLevel.value),
      flaggedParamsJson: Value(jsonEncode(panel.flaggedParameters)),
      notes: Value(panel.notes),
    );

    await _db
        .into(_db.cardiometabolicEntries)
        .insertOnConflictUpdate(companion);

    final payload = {
      'id': panel.id,
      'measurement_date': panel.measurementDate.toIso8601String().split('T')[0],
      'systolic_bp': panel.systolicBp,
      'diastolic_bp': panel.diastolicBp,
      'total_cholesterol_mg_dl': panel.totalCholesterol,
      'ldl_cholesterol_mg_dl': panel.ldlCholesterol,
      'hdl_cholesterol_mg_dl': panel.hdlCholesterol,
      'triglycerides_mg_dl': panel.triglycerides,
      'fasting_glucose_mg_dl': panel.fastingGlucose,
      'notes': panel.notes,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'cardiometabolic_panel',
      entityId: panel.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<CardiometabolicPanel?> getLatestCardiometabolicPanel(
      String userId) async {
    final query = _db.select(_db.cardiometabolicEntries)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([
        (t) =>
            OrderingTerm(expression: t.measurementDate, mode: OrderingMode.desc)
      ])
      ..limit(1);

    final r = await query.getSingleOrNull();
    if (r == null) return null;

    final List<dynamic> rawFlagged =
        jsonDecode(r.flaggedParamsJson) as List<dynamic>;
    return CardiometabolicPanel(
      id: r.id,
      userId: r.userId,
      measurementDate: r.measurementDate,
      systolicBp: r.systolicBp,
      diastolicBp: r.diastolicBp,
      totalCholesterol: r.totalCholesterol,
      ldlCholesterol: r.ldlCholesterol,
      hdlCholesterol: r.hdlCholesterol,
      triglycerides: r.triglycerides,
      fastingGlucose: r.fastingGlucose,
      riskLevel: CardiometabolicRiskLevel.fromValue(r.riskLevel),
      flaggedParameters: rawFlagged.map((e) => e.toString()).toList(),
      notes: r.notes,
    );
  }

  @override
  Future<void> saveVaginalBleeding(VaginalBleedingRecord record) async {
    final companion = VaginalBleedingEntriesCompanion(
      id: Value(record.id),
      userId: Value(record.userId),
      observationDate: Value(record.observationDate),
      daysPriorAmenorrhea: Value(record.daysPriorAmenorrhea),
      flowIntensity: Value(record.flowIntensity),
      hasCramping: Value(record.hasCramping),
      isAlertTriggered: Value(record.isAlertTriggered),
      notes: Value(record.notes),
    );

    await _db
        .into(_db.vaginalBleedingEntries)
        .insertOnConflictUpdate(companion);

    final payload = {
      'id': record.id,
      'observation_date':
          record.observationDate.toIso8601String().split('T')[0],
      'days_of_prior_amenorrhea': record.daysPriorAmenorrhea,
      'flow_intensity': record.flowIntensity,
      'has_cramping': record.hasCramping,
      'notes': record.notes,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'vaginal_bleeding',
      entityId: record.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<List<VaginalBleedingRecord>> getRecentBleedingRecords(String userId,
      {int limit = 50}) async {
    final query = _db.select(_db.vaginalBleedingEntries)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([
        (t) =>
            OrderingTerm(expression: t.observationDate, mode: OrderingMode.desc)
      ])
      ..limit(limit);

    final rows = await query.get();
    return rows.map((r) {
      return VaginalBleedingRecord(
        id: r.id,
        userId: r.userId,
        observationDate: r.observationDate,
        daysPriorAmenorrhea: r.daysPriorAmenorrhea,
        flowIntensity: r.flowIntensity,
        hasCramping: r.hasCramping,
        isAlertTriggered: r.isAlertTriggered,
        notes: r.notes,
      );
    }).toList();
  }
}
