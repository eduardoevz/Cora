import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/fertility/domain/entities/fertility_chart_entity.dart';
import 'package:uuid/uuid.dart';

abstract class IFertilityRepository {
  Future<void> saveDailyFertility(DailyFertilityEntity entry);
  Future<DailyFertilityEntity?> getDailyFertility(
      String userId, DateTime logDate);
  Future<List<DailyFertilityEntity>> listFertilityEntriesBetween(
      String userId, DateTime start, DateTime end);
  Future<PreconceptionChecklistEntity?> getPreconceptionChecklist(
      String userId);
  Future<void> savePreconceptionChecklist(
      PreconceptionChecklistEntity checklist);
}

class FertilityRepositoryImpl implements IFertilityRepository {
  final AppDatabase _db;
  final SyncCoordinator _syncCoordinator;
  final _uuid = const Uuid();

  FertilityRepositoryImpl(this._db, this._syncCoordinator);

  @override
  Future<void> saveDailyFertility(DailyFertilityEntity entry) async {
    final companion = DailyFertilityEntriesCompanion(
      id: Value(entry.id),
      userId: Value(entry.userId),
      logDate: Value(DateTime(
          entry.logDate.year, entry.logDate.month, entry.logDate.day)),
      bbtCelsius: Value(entry.bbtCelsius),
      isDisturbed: Value(entry.isDisturbed),
      disturbanceReason: Value(entry.disturbanceReason),
      measuredAtTime: Value(entry.measuredAtTime),
      cervicalMucus: Value(entry.cervicalMucus),
      lhResult: Value(entry.lhResult),
      intercourseHad: Value(entry.intercourseHad),
      intercourseType: Value(entry.intercourseType),
      notes: Value(entry.notes),
      updatedAt: Value(DateTime.now()),
    );

    await _db.into(_db.dailyFertilityEntries).insertOnConflictUpdate(companion);

    // Offline-First sync queue
    final payload = {
      'log_date':
          "${entry.logDate.year.toString().padLeft(4, '0')}-${entry.logDate.month.toString().padLeft(2, '0')}-${entry.logDate.day.toString().padLeft(2, '0')}",
      'bbt_celsius': entry.bbtCelsius,
      'is_disturbed': entry.isDisturbed,
      'disturbance_reason': entry.disturbanceReason,
      'measured_at_time': entry.measuredAtTime,
      'cervical_mucus': entry.cervicalMucus,
      'lh_result': entry.lhResult,
      'intercourse_had': entry.intercourseHad,
      'intercourse_type': entry.intercourseType,
      'notes': entry.notes,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'daily_fertility_log',
      entityId: entry.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<DailyFertilityEntity?> getDailyFertility(
      String userId, DateTime logDate) async {
    final targetDate = DateTime(logDate.year, logDate.month, logDate.day);
    final query = _db.select(_db.dailyFertilityEntries)
      ..where((t) => t.userId.equals(userId) & t.logDate.equals(targetDate));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return DailyFertilityEntity(
      id: row.id,
      userId: row.userId,
      logDate: row.logDate,
      bbtCelsius: row.bbtCelsius,
      isDisturbed: row.isDisturbed,
      disturbanceReason: row.disturbanceReason,
      measuredAtTime: row.measuredAtTime,
      cervicalMucus: row.cervicalMucus,
      lhResult: row.lhResult,
      intercourseHad: row.intercourseHad,
      intercourseType: row.intercourseType,
      notes: row.notes,
    );
  }

  @override
  Future<List<DailyFertilityEntity>> listFertilityEntriesBetween(
      String userId, DateTime start, DateTime end) async {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    final query = _db.select(_db.dailyFertilityEntries)
      ..where((t) =>
          t.userId.equals(userId) &
          t.logDate.isBiggerOrEqualValue(startDate) &
          t.logDate.isSmallerOrEqualValue(endDate))
      ..orderBy([(t) => OrderingTerm(expression: t.logDate, mode: OrderingMode.asc)]);

    final rows = await query.get();
    return rows
        .map((row) => DailyFertilityEntity(
              id: row.id,
              userId: row.userId,
              logDate: row.logDate,
              bbtCelsius: row.bbtCelsius,
              isDisturbed: row.isDisturbed,
              disturbanceReason: row.disturbanceReason,
              measuredAtTime: row.measuredAtTime,
              cervicalMucus: row.cervicalMucus,
              lhResult: row.lhResult,
              intercourseHad: row.intercourseHad,
              intercourseType: row.intercourseType,
              notes: row.notes,
            ))
        .toList();
  }

  @override
  Future<PreconceptionChecklistEntity?> getPreconceptionChecklist(
      String userId) async {
    final query = _db.select(_db.preconceptionChecklistEntries)
      ..where((t) => t.userId.equals(userId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return PreconceptionChecklistEntity(
      userId: row.userId,
      takingFolicAcid: row.takingFolicAcid,
      folicAcidDoseMcg: row.folicAcidDoseMcg,
      medicalCheckupDone: row.medicalCheckupDone,
      rubellaImmunityChecked: row.rubellaImmunityChecked,
      dentalCheckupDone: row.dentalCheckupDone,
      toxicHabitsStopped: row.toxicHabitsStopped,
      partnerEvaluationPlanned: row.partnerEvaluationPlanned,
      activeSeekingMonths: row.activeSeekingMonths,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> savePreconceptionChecklist(
      PreconceptionChecklistEntity checklist) async {
    final companion = PreconceptionChecklistEntriesCompanion(
      userId: Value(checklist.userId),
      takingFolicAcid: Value(checklist.takingFolicAcid),
      folicAcidDoseMcg: Value(checklist.folicAcidDoseMcg),
      medicalCheckupDone: Value(checklist.medicalCheckupDone),
      rubellaImmunityChecked: Value(checklist.rubellaImmunityChecked),
      dentalCheckupDone: Value(checklist.dentalCheckupDone),
      toxicHabitsStopped: Value(checklist.toxicHabitsStopped),
      partnerEvaluationPlanned: Value(checklist.partnerEvaluationPlanned),
      activeSeekingMonths: Value(checklist.activeSeekingMonths),
      updatedAt: Value(DateTime.now()),
    );

    await _db
        .into(_db.preconceptionChecklistEntries)
        .insertOnConflictUpdate(companion);

    // Sync queue
    final payload = {
      'taking_folic_acid': checklist.takingFolicAcid,
      'folic_acid_dose_mcg': checklist.folicAcidDoseMcg,
      'medical_checkup_done': checklist.medicalCheckupDone,
      'rubella_immunity_checked': checklist.rubellaImmunityChecked,
      'dental_checkup_done': checklist.dentalCheckupDone,
      'toxic_habits_stopped': checklist.toxicHabitsStopped,
      'partner_evaluation_planned': checklist.partnerEvaluationPlanned,
      'active_seeking_months': checklist.activeSeekingMonths,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'preconception_checklist',
      entityId: checklist.userId,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }
}
