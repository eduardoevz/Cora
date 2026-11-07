import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/treatments/domain/entities/treatment_entities.dart';
import 'package:uuid/uuid.dart';

class TreatmentsRepositoryImpl {
  final AppDatabase _db;
  final SyncCoordinator _sync;
  final _uuid = const Uuid();

  TreatmentsRepositoryImpl(this._db, this._sync);

  Future<void> saveRegimen(TreatmentRegimenEntity regimen) async {
    final now = DateTime.now().toUtc();
    final companion = TreatmentRegimenEntriesCompanion(
      id: Value(regimen.id),
      userId: Value(regimen.userId),
      name: Value(regimen.name),
      category: Value(regimen.category),
      dosage: Value(regimen.dosage),
      scheduleType: Value(regimen.scheduleType),
      scheduledTime: Value(regimen.scheduledTime),
      activeDays: Value(regimen.activeDays),
      breakDays: Value(regimen.breakDays),
      intervalDays: Value(regimen.intervalDays),
      replacementDate: Value(regimen.replacementDate),
      instructions: Value(regimen.instructions),
      startDate: Value(regimen.startDate),
      endDate: Value(regimen.endDate),
      reminderEnabled: Value(regimen.reminderEnabled),
      discreetNotification: Value(regimen.discreetNotification),
      isActive: Value(regimen.isActive),
      createdAt: Value(regimen.createdAt ?? now),
      updatedAt: Value(now),
    );

    await _db
        .into(_db.treatmentRegimenEntries)
        .insertOnConflictUpdate(companion);

    await _sync.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'treatment_regimen',
      entityId: regimen.id,
      operation: 'upsert',
      payloadJson: jsonEncode(regimen.toJson()),
    );
  }

  Future<List<TreatmentRegimenEntity>> getRegimens({
    required String userId,
    bool? isActive,
  }) async {
    final query = _db.select(_db.treatmentRegimenEntries)
      ..where((tbl) {
        var predicate = tbl.userId.equals(userId);
        if (isActive != null) {
          predicate = predicate & tbl.isActive.equals(isActive);
        }
        return predicate;
      })
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);

    final rows = await query.get();

    return rows
        .map((r) => TreatmentRegimenEntity(
              id: r.id,
              userId: r.userId,
              name: r.name,
              category: r.category,
              dosage: r.dosage,
              scheduleType: r.scheduleType,
              scheduledTime: r.scheduledTime,
              activeDays: r.activeDays,
              breakDays: r.breakDays,
              intervalDays: r.intervalDays,
              replacementDate: r.replacementDate,
              instructions: r.instructions,
              startDate: r.startDate,
              endDate: r.endDate,
              reminderEnabled: r.reminderEnabled,
              discreetNotification: r.discreetNotification,
              isActive: r.isActive,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
            ))
        .toList();
  }

  Future<DoseIntakeEntity> recordIntake({
    required String regimenId,
    required DateTime scheduledFor,
    DateTime? takenAt,
    required String status,
    String? notes,
  }) async {
    final intakeId = _uuid.v4();
    final mutationId = _uuid.v4();
    final now = DateTime.now().toUtc();

    final companion = DoseIntakeEntriesCompanion(
      id: Value(intakeId),
      regimenId: Value(regimenId),
      scheduledFor: Value(scheduledFor),
      takenAt: Value(takenAt),
      status: Value(status),
      notes: Value(notes),
      clientMutationId: Value(mutationId),
      createdAt: Value(now),
    );

    await _db.into(_db.doseIntakeEntries).insert(companion);

    final entity = DoseIntakeEntity(
      id: intakeId,
      regimenId: regimenId,
      scheduledFor: scheduledFor,
      takenAt: takenAt,
      status: status,
      notes: notes,
      clientMutationId: mutationId,
      createdAt: now,
    );

    await _sync.enqueueMutation(
      clientMutationId: mutationId,
      entityType: 'treatment_intake',
      entityId: intakeId,
      operation: 'upsert',
      payloadJson: jsonEncode(entity.toJson()),
    );

    return entity;
  }

  Future<List<DoseIntakeEntity>> getIntakes({
    required String regimenId,
    required DateTime from,
    required DateTime to,
  }) async {
    final query = _db.select(_db.doseIntakeEntries)
      ..where((tbl) =>
          tbl.regimenId.equals(regimenId) &
          tbl.scheduledFor.isBiggerOrEqualValue(from) &
          tbl.scheduledFor.isSmallerOrEqualValue(to))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.scheduledFor)]);

    final rows = await query.get();

    return rows
        .map((r) => DoseIntakeEntity(
              id: r.id,
              regimenId: r.regimenId,
              scheduledFor: r.scheduledFor,
              takenAt: r.takenAt,
              status: r.status,
              notes: r.notes,
              clientMutationId: r.clientMutationId,
              createdAt: r.createdAt,
            ))
        .toList();
  }
}
