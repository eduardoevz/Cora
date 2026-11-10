import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mobile/core/database/app_database.dart' hide FallRiskEntry;
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/senior_vitality/domain/models/dexa_bone_scan.dart';
import 'package:mobile/features/senior_vitality/domain/models/fall_risk_entry.dart';
import 'package:mobile/features/senior_vitality/domain/models/pelvic_floor_entry.dart';
import 'package:mobile/features/senior_vitality/domain/models/trusted_support_contact.dart';
import 'package:uuid/uuid.dart';

abstract class ISeniorVitalityRepository {
  Future<void> saveDexaScan(DexaBoneScan scan);
  Future<DexaBoneScan?> getLatestDexaScan(String userId);
  Future<void> saveFallRiskAssessment(FallRiskEntry entry);
  Future<FallRiskEntry?> getLatestFallRiskAssessment(String userId);
  Future<void> savePelvicLog(PelvicFloorEntry entry);
  Future<List<PelvicFloorEntry>> getRecentPelvicLogs(String userId,
      {int limit = 20});
  Future<void> saveSupportContact(TrustedSupportContact contact);
  Future<TrustedSupportContact?> getPrimarySupportContact(String userId);
}

class SeniorVitalityRepositoryImpl implements ISeniorVitalityRepository {
  final AppDatabase _db;
  final SyncCoordinator _syncCoordinator;
  final _uuid = const Uuid();

  SeniorVitalityRepositoryImpl(this._db, this._syncCoordinator);

  @override
  Future<void> saveDexaScan(DexaBoneScan scan) async {
    final companion = DexaBoneEntriesCompanion(
      id: Value(scan.id),
      userId: Value(scan.userId),
      scanDate: Value(scan.scanDate),
      anatomicalSite: Value(scan.anatomicalSite.value),
      tScore: Value(scan.tScore),
      zScore: Value(scan.zScore),
      bmdGCm2: Value(scan.bmdGCm2),
      previousFragilityFracture: Value(scan.previousFragilityFracture),
      category: Value(scan.category.value),
      notes: Value(scan.notes),
    );

    await _db.into(_db.dexaBoneEntries).insertOnConflictUpdate(companion);

    final payload = {
      'id': scan.id,
      'scan_date': scan.scanDate.toIso8601String().split('T')[0],
      'anatomical_site': scan.anatomicalSite.value,
      't_score': scan.tScore,
      'z_score': scan.zScore,
      'bmd_g_cm2': scan.bmdGCm2,
      'previous_fragility_fracture': scan.previousFragilityFracture,
      'notes': scan.notes,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'dexa_scan',
      entityId: scan.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<DexaBoneScan?> getLatestDexaScan(String userId) async {
    final query = _db.select(_db.dexaBoneEntries)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.scanDate, mode: OrderingMode.desc)
      ])
      ..limit(1);

    final r = await query.getSingleOrNull();
    if (r == null) return null;

    return DexaBoneScan(
      id: r.id,
      userId: r.userId,
      scanDate: r.scanDate,
      anatomicalSite: AnatomicalSite.fromValue(r.anatomicalSite),
      tScore: r.tScore,
      zScore: r.zScore,
      bmdGCm2: r.bmdGCm2,
      previousFragilityFracture: r.previousFragilityFracture,
      category: BoneDensityCategory.fromValue(r.category),
      notes: r.notes,
    );
  }

  @override
  Future<void> saveFallRiskAssessment(FallRiskEntry entry) async {
    final companion = FallRiskEntriesCompanion(
      id: Value(entry.id),
      userId: Value(entry.userId),
      assessmentDate: Value(entry.assessmentDate),
      fallsPastYear: Value(entry.fallsPastYear),
      hasGaitUnsteadiness: Value(entry.hasGaitUnsteadiness),
      usesWalkingAid: Value(entry.usesWalkingAid),
      timedUpAndGoSeconds: Value(entry.timedUpAndGoSeconds),
      riskLevel: Value(entry.riskLevel.value),
      compositeScore: Value(entry.compositeScore),
      environmentalHazardsJson:
          Value(jsonEncode(entry.environmentalHazards)),
      notes: Value(entry.notes),
    );

    await _db.into(_db.fallRiskEntries).insertOnConflictUpdate(companion);

    final payload = {
      'id': entry.id,
      'assessment_date':
          entry.assessmentDate.toIso8601String().split('T')[0],
      'falls_past_year': entry.fallsPastYear,
      'has_gait_unsteadiness': entry.hasGaitUnsteadiness,
      'uses_walking_aid': entry.usesWalkingAid,
      'timed_up_and_go_seconds': entry.timedUpAndGoSeconds,
      'environmental_hazards_identified': entry.environmentalHazards,
      'notes': entry.notes,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'fall_assessment',
      entityId: entry.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<FallRiskEntry?> getLatestFallRiskAssessment(String userId) async {
    final query = _db.select(_db.fallRiskEntries)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([
        (t) =>
            OrderingTerm(expression: t.assessmentDate, mode: OrderingMode.desc)
      ])
      ..limit(1);

    final r = await query.getSingleOrNull();
    if (r == null) return null;

    final List<dynamic> hazards =
        jsonDecode(r.environmentalHazardsJson) as List<dynamic>;

    return FallRiskEntry(
      id: r.id,
      userId: r.userId,
      assessmentDate: r.assessmentDate,
      fallsPastYear: r.fallsPastYear,
      hasGaitUnsteadiness: r.hasGaitUnsteadiness,
      usesWalkingAid: r.usesWalkingAid,
      timedUpAndGoSeconds: r.timedUpAndGoSeconds,
      riskLevel: FallRiskLevel.fromValue(r.riskLevel),
      compositeScore: r.compositeScore,
      environmentalHazards: hazards.map((e) => e.toString()).toList(),
      notes: r.notes,
    );
  }

  @override
  Future<void> savePelvicLog(PelvicFloorEntry entry) async {
    final companion = ContinenceEntriesCompanion(
      id: Value(entry.id),
      userId: Value(entry.userId),
      logDate: Value(entry.logDate),
      incontinenceType: Value(entry.incontinenceType.value),
      dailyPadCount: Value(entry.dailyPadCount),
      hasPelvicHeaviness: Value(entry.hasPelvicHeaviness),
      vaginalDrynessLevel: Value(entry.vaginalDrynessLevel),
      hasDyspareunia: Value(entry.hasDyspareunia),
      notes: Value(entry.notes),
    );

    await _db.into(_db.continenceEntries).insertOnConflictUpdate(companion);

    final payload = {
      'id': entry.id,
      'log_date': entry.logDate.toIso8601String().split('T')[0],
      'incontinence_type': entry.incontinenceType.value,
      'daily_pad_count': entry.dailyPadCount,
      'has_pelvic_heaviness': entry.hasPelvicHeaviness,
      'vaginal_dryness_level': entry.vaginalDrynessLevel,
      'has_dyspareunia': entry.hasDyspareunia,
      'notes': entry.notes,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'pelvic_log',
      entityId: entry.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<List<PelvicFloorEntry>> getRecentPelvicLogs(String userId,
      {int limit = 20}) async {
    final query = _db.select(_db.continenceEntries)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.logDate, mode: OrderingMode.desc)
      ])
      ..limit(limit);

    final rows = await query.get();
    return rows.map((r) {
      return PelvicFloorEntry(
        id: r.id,
        userId: r.userId,
        logDate: r.logDate,
        incontinenceType: IncontinenceType.fromValue(r.incontinenceType),
        dailyPadCount: r.dailyPadCount,
        hasPelvicHeaviness: r.hasPelvicHeaviness,
        vaginalDrynessLevel: r.vaginalDrynessLevel,
        hasDyspareunia: r.hasDyspareunia,
        notes: r.notes,
      );
    }).toList();
  }

  @override
  Future<void> saveSupportContact(TrustedSupportContact contact) async {
    final companion = TrustedContactEntriesCompanion(
      id: Value(contact.id),
      userId: Value(contact.userId),
      contactName: Value(contact.contactName),
      relationship: Value(contact.relationship),
      phoneNumber: Value(contact.phoneNumber),
      notes: Value(contact.notes),
      isPrimary: Value(contact.isPrimary),
    );

    await _db.into(_db.trustedContactEntries).insertOnConflictUpdate(companion);

    final payload = {
      'id': contact.id,
      'contact_name': contact.contactName,
      'relationship': contact.relationship,
      'phone_number': contact.phoneNumber,
      'notes': contact.notes,
      'is_primary': contact.isPrimary,
    };

    await _syncCoordinator.enqueueMutation(
      clientMutationId: _uuid.v4(),
      entityType: 'support_contact',
      entityId: contact.id,
      operation: 'upsert',
      payloadJson: jsonEncode(payload),
    );
  }

  @override
  Future<TrustedSupportContact?> getPrimarySupportContact(String userId) async {
    final query = _db.select(_db.trustedContactEntries)
      ..where((t) => t.userId.equals(userId) & t.isPrimary.equals(true))
      ..limit(1);

    final r = await query.getSingleOrNull();
    if (r == null) return null;

    return TrustedSupportContact(
      id: r.id,
      userId: r.userId,
      contactName: r.contactName,
      relationship: r.relationship,
      phoneNumber: r.phoneNumber,
      notes: r.notes,
      isPrimary: r.isPrimary,
    );
  }
}
