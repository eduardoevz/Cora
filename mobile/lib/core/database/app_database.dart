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

@DriftDatabase(tables: [
  SyncOutboxEntries,
  UserProfileEntries,
  LifeStageTransitionEntries,
  DailyWellnessEntries,
  TreatmentRegimenEntries,
  DoseIntakeEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

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
