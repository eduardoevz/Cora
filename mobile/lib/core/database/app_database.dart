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

@DriftDatabase(tables: [
  SyncOutboxEntries,
  UserProfileEntries,
  LifeStageTransitionEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

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
