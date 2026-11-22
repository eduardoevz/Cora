import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/network/cora_api_client.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:mobile/features/cycle/domain/services/cycle_calendar_engine.dart';
import 'package:mobile/features/onboarding/data/local/profile_dao.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:uuid/uuid.dart';

class CycleRepositoryImpl implements CycleRepository {
  final AppDatabase _db;
  final SyncCoordinator _sync;
  final CoraApiClient? _api;
  final _uuid = const Uuid();
  final _engine = const CycleCalendarEngine();

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
    final isMenstrual = ['light', 'medium', 'heavy']
        .contains(symptom.bleedingFlow.toLowerCase());

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
        final currentStart = _normalizeDate(current.startDate.toUtc());
        final delta = normalized.difference(currentStart).inDays;
        if (delta > 14) {
          // Close previous cycle
          final closingEnd = normalized.subtract(const Duration(days: 1));
          final length = closingEnd.difference(currentStart).inDays + 1;
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

    // 2. Persist daily symptom record locally (merge with existing row for the same day)
    final existingRow = await (_db.select(_db.cycleSymptomEntries)
          ..where((tbl) =>
              tbl.userId.equals(symptom.userId) &
              tbl.logDate.equals(normalized)))
        .getSingleOrNull();

    final resolvedId =
        existingRow?.id ?? (symptom.id.isEmpty ? symptomId : symptom.id);
    final existingGi = existingRow != null
        ? ((jsonDecode(existingRow.giSymptomsJson) as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[])
        : <String>[];
    final resolvedFlow = (symptom.id.isEmpty &&
            symptom.bleedingFlow == 'none' &&
            existingRow != null &&
            existingRow.bleedingFlow != 'none')
        ? existingRow.bleedingFlow
        : symptom.bleedingFlow;

    final entity = CycleSymptomEntity(
      id: resolvedId,
      userId: symptom.userId,
      cycleId: activeCycleId ?? existingRow?.cycleId,
      logDate: normalized,
      bleedingFlow: resolvedFlow,
      pelvicPain: symptom.pelvicPain ?? existingRow?.pelvicPain,
      dysmenorrhea: symptom.dysmenorrhea ?? existingRow?.dysmenorrhea,
      dyspareunia: symptom.dyspareunia ?? existingRow?.dyspareunia,
      acneSeverity: symptom.acneSeverity ?? existingRow?.acneSeverity,
      hirsutism: symptom.hirsutism ?? existingRow?.hirsutism,
      fatigueLevel: symptom.fatigueLevel ?? existingRow?.fatigueLevel,
      giSymptoms:
          symptom.giSymptoms.isNotEmpty ? symptom.giSymptoms : existingGi,
      notes: symptom.notes ?? existingRow?.notes,
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

    // 4. Non-blocking opportunistic remote sync (true Offline-First)
    final api = _api;
    if (api != null) {
      unawaited(() async {
        try {
          await api.dio.post(
            '/cycles/symptoms',
            data: entity.toJson(),
          );
          await _sync.markAsSynced(mutationId);
        } catch (_) {
          // Will sync on next background pass
        }
      }());
    }

    return entity;
  }

  @override
  Future<List<MenstrualCycleEntity>> seedInitialPeriods({
    required String userId,
    required List<InitialPeriodRangeEntity> periods,
    CycleRegularity? cycleRegularity,
    int? typicalCycleLengthDays,
    int? typicalBleedingDurationDays,
    bool syncRemote = true,
  }) async {
    if (periods.isEmpty || periods.length > 2) {
      throw ArgumentError('periods must contain 1 or 2 historical ranges.');
    }

    final ordered = [...periods]..sort((a, b) =>
        _normalizeDate(a.startDate).compareTo(_normalizeDate(b.startDate)));

    if (ordered.length == 2) {
      final p1Start = _normalizeDate(ordered[0].startDate);
      final p1End = _normalizeDate(ordered[0].endDate);
      final p2Start = _normalizeDate(ordered[1].startDate);
      if (!p1Start.isBefore(p2Start) || !p1End.isBefore(p2Start)) {
        throw ArgumentError('Initial periods cannot overlap.');
      }
    }

    final firstStart = _normalizeDate(ordered.first.startDate);
    final activeExisting = await (_db.select(_db.menstrualCycleEntries)
          ..where(
              (tbl) => tbl.userId.equals(userId) & tbl.isCurrent.equals(true)))
        .get();
    for (final current in activeExisting) {
      final currentStart = _normalizeDate(current.startDate.toUtc());
      if (currentStart.isBefore(firstStart)) {
        final closingEnd = firstStart.subtract(const Duration(days: 1));
        final length = closingEnd.difference(currentStart).inDays + 1;
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
      } else {
        await (_db.update(_db.menstrualCycleEntries)
              ..where((tbl) => tbl.id.equals(current.id)))
            .write(
          MenstrualCycleEntriesCompanion(
            isCurrent: const Value(false),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      }
    }

    final createdCycles = <MenstrualCycleEntity>[];
    final cycleRanges = <(MenstrualCycleEntity, InitialPeriodRangeEntity)>[];

    if (ordered.length == 2) {
      final p1 = ordered[0];
      final p2 = ordered[1];
      final p1Start = _normalizeDate(p1.startDate);
      final p2Start = _normalizeDate(p2.startDate);
      final inferredLen = p2Start.difference(p1Start).inDays;

      final c1 = MenstrualCycleEntity(
        id: _uuid.v4(),
        userId: userId,
        startDate: p1Start,
        endDate: p2Start.subtract(const Duration(days: 1)),
        cycleLengthDays: inferredLen,
        bleedingDurationDays: p1.bleedingDurationDays,
        isCurrent: false,
      );
      final c2 = MenstrualCycleEntity(
        id: _uuid.v4(),
        userId: userId,
        startDate: p2Start,
        bleedingDurationDays: p2.bleedingDurationDays,
        isCurrent: true,
      );
      createdCycles.addAll([c1, c2]);
      cycleRanges.addAll([(c1, p1), (c2, p2)]);
    } else {
      final p1 = ordered[0];
      final p1Start = _normalizeDate(p1.startDate);
      final c1 = MenstrualCycleEntity(
        id: _uuid.v4(),
        userId: userId,
        startDate: p1Start,
        bleedingDurationDays: p1.bleedingDurationDays,
        isCurrent: true,
      );
      createdCycles.add(c1);
      cycleRanges.add((c1, p1));
    }

    for (final pair in cycleRanges) {
      final cycle = pair.$1;
      final range = pair.$2;
      await _db.into(_db.menstrualCycleEntries).insertOnConflictUpdate(
            MenstrualCycleEntriesCompanion.insert(
              id: cycle.id,
              userId: cycle.userId,
              startDate: cycle.startDate,
              endDate: Value(cycle.endDate),
              cycleLengthDays: Value(cycle.cycleLengthDays),
              bleedingDurationDays: Value(cycle.bleedingDurationDays),
              isCurrent: Value(cycle.isCurrent),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );

      final rangeStart = _normalizeDate(range.startDate);
      for (var offset = 0; offset < range.bleedingDurationDays; offset++) {
        final day = rangeStart.add(Duration(days: offset));
        final existingRow = await (_db.select(_db.cycleSymptomEntries)
              ..where(
                  (tbl) => tbl.userId.equals(userId) & tbl.logDate.equals(day)))
            .getSingleOrNull();
        final resolvedId = existingRow?.id ?? _uuid.v4();
        final resolvedFlow =
            (existingRow != null && existingRow.bleedingFlow != 'none')
                ? existingRow.bleedingFlow
                : 'medium';

        await _db.into(_db.cycleSymptomEntries).insertOnConflictUpdate(
              CycleSymptomEntriesCompanion.insert(
                id: resolvedId,
                userId: userId,
                cycleId: Value(cycle.id),
                logDate: day,
                bleedingFlow: Value(resolvedFlow),
                pelvicPain: Value(existingRow?.pelvicPain),
                dysmenorrhea: Value(existingRow?.dysmenorrhea),
                dyspareunia: Value(existingRow?.dyspareunia),
                acneSeverity: Value(existingRow?.acneSeverity),
                hirsutism: Value(existingRow?.hirsutism),
                fatigueLevel: Value(existingRow?.fatigueLevel),
                giSymptomsJson:
                    Value(existingRow?.giSymptomsJson ?? jsonEncode([])),
                notes: Value(existingRow?.notes),
                updatedAt: Value(DateTime.now().toUtc()),
              ),
            );
      }
    }

    final profileDao = ProfileDao(_db);
    final profile = await profileDao.getActiveProfile();
    if (profile != null) {
      final inferredLen = ordered.length == 2
          ? _normalizeDate(ordered[1].startDate)
              .difference(_normalizeDate(ordered[0].startDate))
              .inDays
          : null;
      final inferredBleed =
          (ordered.map((e) => e.bleedingDurationDays).reduce((a, b) => a + b) /
                  ordered.length)
              .round();
      await profileDao.updateMenstrualBaseline(
        profile.id,
        regularity: cycleRegularity,
        typicalCycleLengthDays: typicalCycleLengthDays ?? inferredLen,
        typicalBleedingDurationDays:
            typicalBleedingDurationDays ?? inferredBleed,
      );
    }

    if (syncRemote) {
      final payload = <String, dynamic>{
        'periods': ordered.map((p) => p.toJson()).toList(),
        if (cycleRegularity != null) 'cycle_regularity': cycleRegularity.value,
        if (typicalCycleLengthDays != null)
          'typical_cycle_length_days': typicalCycleLengthDays,
        if (typicalBleedingDurationDays != null)
          'typical_bleeding_duration_days': typicalBleedingDurationDays,
      };
      final mutationId = _uuid.v4();
      await _sync.enqueueMutation(
        clientMutationId: mutationId,
        entityType: 'menstrual_cycles_seed',
        entityId: createdCycles.last.id,
        operation: 'seed_initial_periods',
        payloadJson: jsonEncode(payload),
      );

      final api = _api;
      if (api != null) {
        unawaited(() async {
          try {
            await api.dio.post('/cycles/initial-periods', data: payload);
            await _sync.markAsSynced(mutationId);
          } catch (_) {
            // Offline-First: remains queued in sync_outbox
          }
        }());
      }
    }

    return createdCycles;
  }

  @override
  Future<CalendarMonthProjectionEntity> getCalendarMonth({
    required String userId,
    required int year,
    required int month,
    DateTime? referenceDate,
  }) async {
    final cycles = await getCycleHistory(userId: userId, limit: 24);
    final symptoms = await getSymptomLogs(userId: userId);
    final profile = await ProfileDao(_db).getActiveProfile();
    final ctx = profile?.onboardingContext;

    return _engine.projectMonth(
      year: year,
      month: month,
      cycles: cycles,
      symptomLogs: symptoms,
      lifeStage: profile?.currentLifeStage ?? LifeStage.regularAdult,
      hormonalMethod: ctx?.hormonalMethod,
      diagnosedConditions: ctx?.diagnosedConditions ?? const [],
      cycleRegularity: ctx?.cycleRegularity ?? CycleRegularity.unsure,
      typicalCycleLengthDays: ctx?.typicalCycleLengthDays,
      typicalBleedingDurationDays: ctx?.typicalBleedingDurationDays,
      referenceDate: referenceDate,
    );
  }

  @override
  Future<CycleOverviewEntity> getCycleOverview({
    required String userId,
    DateTime? referenceDate,
  }) async {
    final refDate = _normalizeDate(referenceDate ?? DateTime.now());

    // Offline-First: always compute immediately from local Drift SQLite database
    final cycles = await getCycleHistory(userId: userId, limit: 12);
    final symptoms = await getSymptomLogs(userId: userId);
    final profile = await ProfileDao(_db).getActiveProfile();
    final ctx = profile?.onboardingContext;

    final currentCycle =
        cycles.isNotEmpty && cycles.first.isCurrent ? cycles.first : null;

    final status = _engine.computeStatus(
      cycles: cycles,
      lifeStage: profile?.currentLifeStage ?? LifeStage.regularAdult,
      hormonalMethod: ctx?.hormonalMethod,
      diagnosedConditions: ctx?.diagnosedConditions ?? const [],
      cycleRegularity: ctx?.cycleRegularity ?? CycleRegularity.unsure,
      typicalCycleLengthDays: ctx?.typicalCycleLengthDays,
      typicalBleedingDurationDays: ctx?.typicalBleedingDurationDays,
      referenceDate: refDate,
    );

    // Check offline FIGO alerts
    final List<FigoAlertEntity> alerts = [];
    final severePainCount = symptoms
        .where((s) =>
            (s.pelvicPain != null && s.pelvicPain! >= 7) ||
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
      status: status,
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
              startDate: r.startDate.toUtc(),
              endDate: r.endDate?.toUtc(),
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
        logDate: r.logDate.toUtc(),
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
