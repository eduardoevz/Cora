import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/network/cora_api_client.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:uuid/uuid.dart';

class CycleRepositoryImpl implements CycleRepository {
  final AppDatabase _db;
  final SyncCoordinator _sync;
  final CoraApiClient? _api;
  final _uuid = const Uuid();

  CycleRepositoryImpl(this._db, this._sync, [this._api]);

  DateTime _normalizeDate(DateTime dt) {
    return DateTime.utc(dt.year, dt.month, dt.day);
  }

  @override
  Future<CycleSymptomEntity> logBleedingAndSymptoms(
      CycleSymptomEntity symptom) async {
    final normalized = _normalizeDate(symptom.logDate);
    final symptomId = symptom.id.isEmpty ? _uuid.v4() : symptom.id;

    // 1. Cycle delimitation for menstrual bleeding
    final isMenstrual =
        ['light', 'medium', 'heavy'].contains(symptom.bleedingFlow.toLowerCase());

    String? activeCycleId = symptom.cycleId;

    if (isMenstrual) {
      final currentCycles = await (_db.select(_db.menstrualCycleEntries)
            ..where((tbl) =>
                tbl.userId.equals(symptom.userId) & tbl.isCurrent.equals(true))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.startDate)])
            ..limit(1))
          .get();

      if (currentCycles.isEmpty) {
        final newCycleId = _uuid.v4();
        await _db.into(_db.menstrualCycleEntries).insert(
              MenstrualCycleEntriesCompanion.insert(
                id: newCycleId,
                userId: symptom.userId,
                startDate: normalized,
                bleedingDurationDays: const Value(null),
                isCurrent: const Value(true),
              ),
            );
        activeCycleId = newCycleId;
      } else {
        final current = currentCycles.first;
        final delta = normalized.difference(current.startDate).inDays;
        if (delta > 14) {
          // Close previous cycle
          final closingEnd = normalized.subtract(const Duration(days: 1));
          final length = closingEnd.difference(current.startDate).inDays + 1;
          await (_db.update(_db.menstrualCycleEntries)
                ..where((tbl) => tbl.id.equals(current.id)))
              .write(
            MenstrualCycleEntriesCompanion(
              endDate: Value(closingEnd),
              cycleLengthDays: Value(length),
              isCurrent: const Value(false),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );

          final newCycleId = _uuid.v4();
          await _db.into(_db.menstrualCycleEntries).insert(
                MenstrualCycleEntriesCompanion.insert(
                  id: newCycleId,
                  userId: symptom.userId,
                  startDate: normalized,
                  bleedingDurationDays: const Value(null),
                  isCurrent: const Value(true),
                ),
              );
          activeCycleId = newCycleId;
        } else if (delta >= 0) {
          activeCycleId = current.id;
          final duration = delta + 1;
          if (duration > (current.bleedingDurationDays ?? 5)) {
            await (_db.update(_db.menstrualCycleEntries)
                  ..where((tbl) => tbl.id.equals(current.id)))
                .write(
              MenstrualCycleEntriesCompanion(
                bleedingDurationDays: Value(duration),
                updatedAt: Value(DateTime.now().toUtc()),
              ),
            );
          }
        }
      }
    }

    // 2. Persist daily symptom record locally
    final entity = CycleSymptomEntity(
      id: symptomId,
      userId: symptom.userId,
      cycleId: activeCycleId,
      logDate: normalized,
      bleedingFlow: symptom.bleedingFlow,
      pelvicPain: symptom.pelvicPain,
      dysmenorrhea: symptom.dysmenorrhea,
      dyspareunia: symptom.dyspareunia,
      acneSeverity: symptom.acneSeverity,
      hirsutism: symptom.hirsutism,
      fatigueLevel: symptom.fatigueLevel,
      giSymptoms: symptom.giSymptoms,
      notes: symptom.notes,
    );

    await _db.into(_db.cycleSymptomEntries).insertOnConflictUpdate(
          CycleSymptomEntriesCompanion.insert(
            id: entity.id,
            userId: entity.userId,
            cycleId: Value(entity.cycleId),
            logDate: entity.logDate,
            bleedingFlow: Value(entity.bleedingFlow),
            pelvicPain: Value(entity.pelvicPain),
            dysmenorrhea: Value(entity.dysmenorrhea),
            dyspareunia: Value(entity.dyspareunia),
            acneSeverity: Value(entity.acneSeverity),
            hirsutism: Value(entity.hirsutism),
            fatigueLevel: Value(entity.fatigueLevel),
            giSymptomsJson: Value(jsonEncode(entity.giSymptoms)),
            notes: Value(entity.notes),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );

    // 3. Enqueue mutation in offline outbox
    final mutationId = _uuid.v4();
    await _sync.enqueueMutation(
      clientMutationId: mutationId,
      entityType: 'cycle_symptoms',
      entityId: entity.id,
      operation: 'upsert',
      payloadJson: jsonEncode(entity.toJson()),
    );

    // 4. Opportunistic remote sync
    final api = _api;
    if (api != null) {
      try {
        await api.dio.post(
          '/cycles/symptoms',
          data: entity.toJson(),
        );
        await _sync.markAsSynced(mutationId);
      } catch (_) {
        // Will sync on next background pass
      }
    }

    return entity;
  }

  @override
  Future<CycleOverviewEntity> getCycleOverview({
    required String userId,
    DateTime? referenceDate,
  }) async {
    final refDate = _normalizeDate(referenceDate ?? DateTime.now());

    // Opportunistic fetch from remote if connected
    final api = _api;
    if (api != null) {
      try {
        final queryDate = refDate.toIso8601String().split('T').first;
        final res = await api.dio.get('/cycles/overview?reference_date=$queryDate');
        if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
          return CycleOverviewEntity.fromJson(res.data as Map<String, dynamic>);
        }
      } catch (_) {
        // Fall back to offline computation below
      }
    }

    // Offline computation from local SQLite database
    final cycles = await getCycleHistory(userId: userId, limit: 12);
    final symptoms = await getSymptomLogs(userId: userId);

    final currentCycle = cycles.isNotEmpty && cycles.first.isCurrent ? cycles.first : null;

    final int dayInCycle = currentCycle != null
        ? refDate.difference(currentCycle.startDate).inDays + 1
        : 1;

    final duration = currentCycle?.bleedingDurationDays ?? 5;
    const cycleLen = 28;

    String phase = 'follicular';
    if (currentCycle != null) {
      if (dayInCycle <= duration) {
        phase = 'menstrual';
      } else if (dayInCycle < 13) {
        phase = 'follicular';
      } else if (dayInCycle <= 15) {
        phase = 'ovulatory';
      } else {
        phase = 'luteal';
      }
    }

    final nextPeriod =
        currentCycle?.startDate.add(const Duration(days: cycleLen));
    final ovulation =
        currentCycle?.startDate.add(const Duration(days: cycleLen - 14));

    // Check offline FIGO alerts
    final List<FigoAlertEntity> alerts = [];
    final severePainCount = symptoms
        .where((s) => (s.pelvicPain != null && s.pelvicPain! >= 7) ||
                      (s.dysmenorrhea != null && s.dysmenorrhea! >= 7))
        .map((s) => s.cycleId)
        .where((id) => id != null)
        .toSet()
        .length;

    if (severePainCount >= 2) {
      alerts.add(
        const FigoAlertEntity(
          alertType: 'severe_pelvic_pain_endometriosis_risk',
          severity: 'clinical_recommendation',
          titleEs: 'Dolor pélvico persistente de intensidad elevada',
          descriptionEs:
              'Has reportado dolor pélvico o cólicos menstruales severos (7/10 o superior) durante al menos dos ciclos distintos.',
          recommendationEs:
              'Agenda una consulta ginecológica integral orientada a salud pélvica.',
        ),
      );
    }

    return CycleOverviewEntity(
      currentCycle: currentCycle,
      status: CycleStatusEntity(
        currentCycleId: currentCycle?.id,
        dayInCycle: dayInCycle,
        currentPhase: phase,
        predictedNextPeriod: nextPeriod,
        fertileWindowStart: ovulation?.subtract(const Duration(days: 5)),
        fertileWindowEnd: ovulation?.add(const Duration(days: 1)),
        ovulationDate: ovulation,
        isHormonallyManaged: false,
        hasExtendedUncertainty: false,
        phaseDescriptionEs: phase == 'menstrual'
            ? 'Fase menstrual activa. Tu cuerpo renueva el endometrio.'
            : 'Fase folicular. Estrógenos en ascenso.',
        dailyTipEs: 'Prioriza descanso e hidratación balanceada.',
      ),
      alerts: alerts,
      recentCycles: cycles,
    );
  }

  @override
  Future<List<MenstrualCycleEntity>> getCycleHistory({
    required String userId,
    int limit = 12,
  }) async {
    final rows = await (_db.select(_db.menstrualCycleEntries)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.startDate)])
          ..limit(limit))
        .get();

    return rows
        .map((r) => MenstrualCycleEntity(
              id: r.id,
              userId: r.userId,
              startDate: r.startDate,
              endDate: r.endDate,
              cycleLengthDays: r.cycleLengthDays,
              bleedingDurationDays: r.bleedingDurationDays,
              isCurrent: r.isCurrent,
            ))
        .toList();
  }

  @override
  Future<List<CycleSymptomEntity>> getSymptomLogs({
    required String userId,
  }) async {
    final rows = await (_db.select(_db.cycleSymptomEntries)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.logDate)]))
        .get();

    return rows.map((r) {
      final giList = (jsonDecode(r.giSymptomsJson) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      return CycleSymptomEntity(
        id: r.id,
        userId: r.userId,
        cycleId: r.cycleId,
        logDate: r.logDate,
        bleedingFlow: r.bleedingFlow,
        pelvicPain: r.pelvicPain,
        dysmenorrhea: r.dysmenorrhea,
        dyspareunia: r.dyspareunia,
        acneSeverity: r.acneSeverity,
        hirsutism: r.hirsutism,
        fatigueLevel: r.fatigueLevel,
        giSymptoms: giList,
        notes: r.notes,
      );
    }).toList();
  }
}
