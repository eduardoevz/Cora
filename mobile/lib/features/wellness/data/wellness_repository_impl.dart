import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/wellness/domain/entities/daily_wellness_entity.dart';
import 'package:uuid/uuid.dart';

class WellnessRepositoryImpl {
  final AppDatabase _db;
  final SyncCoordinator _sync;
  final _uuid = const Uuid();

  WellnessRepositoryImpl(this._db, this._sync);

  DateTime _normalizeDate(DateTime dt) {
    return DateTime.utc(dt.year, dt.month, dt.day);
  }

  Future<DailyWellnessEntity?> getDailyLog({
    required String userId,
    required DateTime date,
  }) async {
    final normalized = _normalizeDate(date);
    final row = await (_db.select(_db.dailyWellnessEntries)
          ..where((tbl) =>
              tbl.userId.equals(userId) & tbl.logDate.equals(normalized)))
        .getSingleOrNull();

    if (row == null) return null;

    final moodTags = (jsonDecode(row.moodTagsJson) as List<dynamic>)
        .map((e) => e.toString())
        .toList();

    return DailyWellnessEntity(
      id: row.id,
      userId: row.userId,
      logDate: row.logDate,
      sleepHours: row.sleepHours,
      sleepQuality: row.sleepQuality,
      energyLevel: row.energyLevel,
      hydrationMl: row.hydrationMl,
      exerciseMinutes: row.exerciseMinutes,
      moodTags: moodTags,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<DailyWellnessEntity> saveDailyLog(DailyWellnessEntity log) async {
    final normalized = _normalizeDate(log.logDate);
    final existing = await getDailyLog(userId: log.userId, date: normalized);

    // Merge-patch: keep previous non-null values if incoming is null
    final merged = DailyWellnessEntity(
      id: existing?.id ?? log.id ?? _uuid.v4(),
      userId: log.userId,
      logDate: normalized,
      sleepHours: log.sleepHours ?? existing?.sleepHours,
      sleepQuality: log.sleepQuality ?? existing?.sleepQuality,
      energyLevel: log.energyLevel ?? existing?.energyLevel,
      hydrationMl: log.hydrationMl ?? existing?.hydrationMl,
      exerciseMinutes: log.exerciseMinutes ?? existing?.exerciseMinutes,
      moodTags: log.moodTags.isNotEmpty
          ? log.moodTags
          : (existing?.moodTags ?? const []),
      notes: log.notes ?? existing?.notes,
      createdAt: existing?.createdAt ?? DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final companion = DailyWellnessEntriesCompanion(
      id: Value(merged.id!),
      userId: Value(merged.userId),
      logDate: Value(merged.logDate),
      sleepHours: Value(merged.sleepHours),
      sleepQuality: Value(merged.sleepQuality),
      energyLevel: Value(merged.energyLevel),
      hydrationMl: Value(merged.hydrationMl),
      exerciseMinutes: Value(merged.exerciseMinutes),
      moodTagsJson: Value(jsonEncode(merged.moodTags)),
      notes: Value(merged.notes),
      createdAt: Value(merged.createdAt!),
      updatedAt: Value(merged.updatedAt!),
    );

    await _db
        .into(_db.dailyWellnessEntries)
        .insertOnConflictUpdate(companion);

    // Enqueue outbox mutation for remote sync
    final mutationId = _uuid.v4();
    final payload = {
      'log_date':
          '${normalized.year.toString().padLeft(4, '0')}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}',
      ...merged.toJson(),
    };

    await _sync.enqueueMutation(
      clientMutationId: mutationId,
      entityType: 'daily_wellness',
      entityId: merged.id!,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );

    return merged;
  }
}
