import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';

class ProfileDao {
  final AppDatabase _db;

  ProfileDao(this._db);

  UserProfileEntity _toEntity(
    UserProfileEntry row,
    List<LifeStageTransitionEntry> transitions,
  ) {
    final intentsList = (jsonDecode(row.primaryIntentsJson) as List<dynamic>)
        .map((e) => PrimaryIntent.fromValue(e as String))
        .toList();

    final conditionsList =
        (jsonDecode(row.diagnosedConditionsJson) as List<dynamic>)
            .map((e) => DiagnosedCondition.fromValue(e as String))
            .toList();

    final enabledModules = (jsonDecode(row.enabledModulesJson) as List<dynamic>)
        .map((e) => e as String)
        .toList();

    final mappedTransitions = transitions
        .map((t) => LifeStageTransitionEntity(
              id: t.id,
              fromStage: LifeStage.fromValue(t.fromStage),
              toStage: LifeStage.fromValue(t.toStage),
              reason: TransitionReason.fromValue(t.reason),
              notes: t.notes,
              occurredAt: t.occurredAt,
            ))
        .toList();

    return UserProfileEntity(
      id: row.id,
      firebaseUid: row.firebaseUid,
      firstName: row.firstName,
      lastName: row.lastName,
      currentLifeStage: LifeStage.fromValue(row.currentLifeStage),
      onboardingCompleted: row.onboardingCompleted,
      onboardingContext: OnboardingContextEntity(
        birthYear: row.birthYear,
        primaryIntents: intentsList,
        hormonalMethod: row.hormonalMethod != null
            ? HormonalMethod.fromValue(row.hormonalMethod!)
            : null,
        diagnosedConditions: conditionsList,
        clinicalContextCompleted: row.clinicalContextCompleted,
      ),
      enabledModules: enabledModules,
      transitionHistory: mappedTransitions,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<UserProfileEntity?> getActiveProfile() async {
    final profileRow =
        await (_db.select(_db.userProfileEntries)..limit(1)).getSingleOrNull();

    if (profileRow == null) return null;

    final transitions = await (_db.select(_db.lifeStageTransitionEntries)
          ..where((t) => t.userProfileId.equals(profileRow.id))
          ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
        .get();

    return _toEntity(profileRow, transitions);
  }

  Stream<UserProfileEntity?> watchActiveProfile() {
    return (_db.select(_db.userProfileEntries)..limit(1))
        .watchSingleOrNull()
        .asyncMap((row) async {
      if (row == null) return null;
      final transitions = await (_db.select(_db.lifeStageTransitionEntries)
            ..where((t) => t.userProfileId.equals(row.id))
            ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
          .get();
      return _toEntity(row, transitions);
    });
  }

  Future<void> saveProfile(UserProfileEntity profile) async {
    final entry = UserProfileEntriesCompanion.insert(
      id: profile.id,
      firebaseUid: profile.firebaseUid,
      firstName: profile.firstName,
      lastName: profile.lastName,
      currentLifeStage: profile.currentLifeStage.value,
      onboardingCompleted: Value(profile.onboardingCompleted),
      birthYear: profile.onboardingContext.birthYear,
      primaryIntentsJson: jsonEncode(
        profile.onboardingContext.primaryIntents.map((i) => i.value).toList(),
      ),
      hormonalMethod: Value(profile.onboardingContext.hormonalMethod?.value),
      diagnosedConditionsJson: jsonEncode(
        profile.onboardingContext.diagnosedConditions
            .map((c) => c.value)
            .toList(),
      ),
      clinicalContextCompleted:
          Value(profile.onboardingContext.clinicalContextCompleted),
      enabledModulesJson: jsonEncode(profile.enabledModules),
      createdAt: Value(profile.createdAt),
      updatedAt: Value(profile.updatedAt),
    );

    await _db.into(_db.userProfileEntries).insertOnConflictUpdate(entry);

    // Persist transition history
    for (final tr in profile.transitionHistory) {
      final trEntry = LifeStageTransitionEntriesCompanion.insert(
        id: tr.id,
        userProfileId: profile.id,
        fromStage: tr.fromStage.value,
        toStage: tr.toStage.value,
        reason: tr.reason.value,
        notes: Value(tr.notes),
        occurredAt: tr.occurredAt,
      );
      await _db
          .into(_db.lifeStageTransitionEntries)
          .insertOnConflictUpdate(trEntry);
    }
  }

  Future<void> updateStage(
    String profileId,
    LifeStage newStage,
    LifeStageTransitionEntity transition,
    List<String> updatedModules,
  ) async {
    await (_db.update(_db.userProfileEntries)
          ..where((tbl) => tbl.id.equals(profileId)))
        .write(
      UserProfileEntriesCompanion(
        currentLifeStage: Value(newStage.value),
        enabledModulesJson: Value(jsonEncode(updatedModules)),
        updatedAt: Value(DateTime.now()),
      ),
    );

    final trEntry = LifeStageTransitionEntriesCompanion.insert(
      id: transition.id,
      userProfileId: profileId,
      fromStage: transition.fromStage.value,
      toStage: transition.toStage.value,
      reason: transition.reason.value,
      notes: Value(transition.notes),
      occurredAt: transition.occurredAt,
    );
    await _db
        .into(_db.lifeStageTransitionEntries)
        .insertOnConflictUpdate(trEntry);
  }

  Future<void> updateEnabledModules(
    String profileId,
    List<String> modules,
  ) async {
    await (_db.update(_db.userProfileEntries)
          ..where((tbl) => tbl.id.equals(profileId)))
        .write(
      UserProfileEntriesCompanion(
        enabledModulesJson: Value(jsonEncode(modules)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
