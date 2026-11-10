import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class SyncOutboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientMutationId => text().unique()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // upsert, delete
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(
      const Constant('pending'))(); // pending, syncing, synced, failed
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class UserProfileEntries extends Table {
  TextColumn get id => text()();
  TextColumn get firebaseUid => text()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get currentLifeStage => text()();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();
  IntColumn get birthYear => integer()();
  TextColumn get primaryIntentsJson => text()();
  TextColumn get hormonalMethod => text().nullable()();
  TextColumn get diagnosedConditionsJson => text()();
  BoolColumn get clinicalContextCompleted =>
      boolean().withDefault(const Constant(false))();
  TextColumn get enabledModulesJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class LifeStageTransitionEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userProfileId => text()();
  TextColumn get fromStage => text()();
  TextColumn get toStage => text()();
  TextColumn get reason => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class DailyWellnessEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get logDate => dateTime()();
  RealColumn get sleepHours => real().nullable()();
  IntColumn get sleepQuality => integer().nullable()();
  IntColumn get energyLevel => integer().nullable()();
  IntColumn get hydrationMl => integer().nullable()();
  IntColumn get exerciseMinutes => integer().nullable()();
  TextColumn get moodTagsJson => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, logDate},
      ];
}

class TreatmentRegimenEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get dosage => text()();
  TextColumn get scheduleType => text()();
  TextColumn get scheduledTime => text()();
  IntColumn get activeDays => integer().nullable()();
  IntColumn get breakDays => integer().nullable()();
  IntColumn get intervalDays => integer().nullable()();
  DateTimeColumn get replacementDate => dateTime().nullable()();
  TextColumn get instructions => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get discreetNotification =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class DoseIntakeEntries extends Table {
  TextColumn get id => text()();
  TextColumn get regimenId => text()();
  DateTimeColumn get scheduledFor => dateTime()();
  DateTimeColumn get takenAt => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get clientMutationId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class MenstrualCycleEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get cycleLengthDays => integer().nullable()();
  IntColumn get bleedingDurationDays => integer().nullable()();
  BoolColumn get isCurrent => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class CycleSymptomEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get cycleId => text().nullable()();
  DateTimeColumn get logDate => dateTime()();
  TextColumn get bleedingFlow =>
      text().withDefault(const Constant('none'))();
  IntColumn get pelvicPain => integer().nullable()();
  IntColumn get dysmenorrhea => integer().nullable()();
  BoolColumn get dyspareunia => boolean().nullable()();
  IntColumn get acneSeverity => integer().nullable()();
  BoolColumn get hirsutism => boolean().nullable()();
  IntColumn get fatigueLevel => integer().nullable()();
  TextColumn get giSymptomsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, logDate},
      ];
}

class DailyFertilityEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get logDate => dateTime()();
  RealColumn get bbtCelsius => real().nullable()();
  BoolColumn get isDisturbed =>
      boolean().withDefault(const Constant(false))();
  TextColumn get disturbanceReason => text().nullable()();
  TextColumn get measuredAtTime => text().nullable()();
  TextColumn get cervicalMucus => text().nullable()();
  TextColumn get lhResult => text().nullable()();
  BoolColumn get intercourseHad =>
      boolean().withDefault(const Constant(false))();
  TextColumn get intercourseType =>
      text().withDefault(const Constant('none'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, logDate},
      ];
}

class PreconceptionChecklistEntries extends Table {
  TextColumn get userId => text()();
  BoolColumn get takingFolicAcid =>
      boolean().withDefault(const Constant(false))();
  IntColumn get folicAcidDoseMcg =>
      integer().nullable().withDefault(const Constant(400))();
  BoolColumn get medicalCheckupDone =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get rubellaImmunityChecked =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get dentalCheckupDone =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get toxicHabitsStopped =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get partnerEvaluationPlanned =>
      boolean().withDefault(const Constant(false))();
  IntColumn get activeSeekingMonths =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}

class PregnancyEpisodeEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get clinicalEdd => dateTime()();
  DateTimeColumn get lastMenstrualPeriod => dateTime().nullable()();
  DateTimeColumn get ultrasoundEdd => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get recalibrationHistoryJson =>
      text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class MaternalVitalsEntries extends Table {
  TextColumn get id => text()();
  TextColumn get pregnancyEpisodeId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get measuredAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get gestationalWeeks => integer()();
  IntColumn get systolicMmhg => integer().nullable()();
  IntColumn get diastolicMmhg => integer().nullable()();
  RealColumn get glucoseMgDl => real().nullable()();
  TextColumn get glucoseTiming => text().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get symptomsJson => text().withDefault(const Constant('[]'))();
  TextColumn get alertsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class ContractionSessionEntries extends Table {
  TextColumn get id => text()();
  TextColumn get pregnancyEpisodeId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get gestationalWeeks => integer()();
  TextColumn get pattern => text()();
  IntColumn get totalContractions => integer()();
  RealColumn get avgIntervalSeconds => real().nullable()();
  RealColumn get avgDurationSeconds => real().nullable()();
  TextColumn get eventsJson => text().withDefault(const Constant('[]'))();
  TextColumn get alertJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class KickSessionEntries extends Table {
  TextColumn get id => text()();
  TextColumn get pregnancyEpisodeId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get durationMinutes => integer()();
  IntColumn get gestationalWeeks => integer()();
  IntColumn get kicksCount => integer()();
  BoolColumn get targetReached => boolean()();
  IntColumn get targetReachedAtMinutes => integer().nullable()();
  BoolColumn get isReassuring => boolean()();
  TextColumn get alertJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class BirthPlanEntries extends Table {
  TextColumn get pregnancyEpisodeId => text()();
  TextColumn get userId => text()();
  TextColumn get companionPreferencesJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get painManagementJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get deliveryEnvironmentJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get immediatePostpartumJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get specialRequests => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {pregnancyEpisodeId};
}

class PrenatalAppointmentEntries extends Table {
  TextColumn get id => text()();
  TextColumn get pregnancyEpisodeId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get doctorOrClinic => text()();
  IntColumn get gestationalWeek => integer()();
  TextColumn get topicsToDiscussJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class PostpartumRecoveryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get loggedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get daysPostpartum => integer()();
  TextColumn get lochiaStage => text()();
  TextColumn get lochiaFlow => text()();
  BoolColumn get foulOdor => boolean().withDefault(const Constant(false))();
  RealColumn get maternalTemperatureC => real().nullable()();
  TextColumn get perinealWoundStatus => text().nullable()();
  TextColumn get cesareanWoundStatus => text().nullable()();
  TextColumn get pelvicFloorSymptomsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  TextColumn get alertsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

class LactationSessionEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get leftDurationSeconds =>
      integer().withDefault(const Constant(0))();
  IntColumn get rightDurationSeconds =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalDurationSeconds =>
      integer().withDefault(const Constant(0))();
  TextColumn get lastOfferedBreast => text()();
  TextColumn get suggestedNextBreast => text()();
  RealColumn get bottleVolumeMl => real().nullable()();
  TextColumn get feedingType => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class MilkStashEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get pumpedAt => dateTime()();
  RealColumn get volumeMl => real()();
  TextColumn get storageLocation => text()();
  DateTimeColumn get expiresAt => dateTime()();
  BoolColumn get isConsumed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get consumedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class EpdsScreeningEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get screenedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get daysPostpartum => integer()();
  TextColumn get responsesJson => text()();
  IntColumn get totalScore => integer()();
  IntColumn get item10Score => integer()();
  BoolColumn get selfHarmRisk => boolean()();
  TextColumn get severity => text()();
  TextColumn get clinicalSummary => text()();
  TextColumn get actionRecommended => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  SyncOutboxEntries,
  UserProfileEntries,
  LifeStageTransitionEntries,
  DailyWellnessEntries,
  TreatmentRegimenEntries,
  DoseIntakeEntries,
  MenstrualCycleEntries,
  CycleSymptomEntries,
  DailyFertilityEntries,
  PreconceptionChecklistEntries,
  PregnancyEpisodeEntries,
  MaternalVitalsEntries,
  ContractionSessionEntries,
  KickSessionEntries,
  BirthPlanEntries,
  PrenatalAppointmentEntries,
  PostpartumRecoveryEntries,
  LactationSessionEntries,
  MilkStashEntries,
  EpdsScreeningEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(userProfileEntries);
            await m.createTable(lifeStageTransitionEntries);
          }
          if (from < 3) {
            await m.createTable(dailyWellnessEntries);
            await m.createTable(treatmentRegimenEntries);
            await m.createTable(doseIntakeEntries);
          }
          if (from < 4) {
            await m.createTable(menstrualCycleEntries);
            await m.createTable(cycleSymptomEntries);
          }
          if (from < 5) {
            await m.createTable(dailyFertilityEntries);
            await m.createTable(preconceptionChecklistEntries);
          }
          if (from < 6) {
            await m.createTable(pregnancyEpisodeEntries);
            await m.createTable(maternalVitalsEntries);
            await m.createTable(contractionSessionEntries);
            await m.createTable(kickSessionEntries);
            await m.createTable(birthPlanEntries);
            await m.createTable(prenatalAppointmentEntries);
          }
          if (from < 7) {
            await m.createTable(postpartumRecoveryEntries);
            await m.createTable(lactationSessionEntries);
            await m.createTable(milkStashEntries);
            await m.createTable(epdsScreeningEntries);
          }
        },
      );

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'cora_offline.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
