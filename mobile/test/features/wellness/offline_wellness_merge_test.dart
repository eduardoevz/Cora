import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/wellness/data/wellness_repository_impl.dart';
import 'package:mobile/features/wellness/domain/entities/daily_wellness_entity.dart';

void main() {
  late AppDatabase db;
  late SyncCoordinator syncCoordinator;
  late WellnessRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncCoordinator = SyncCoordinator(db);
    repository = WellnessRepositoryImpl(db, syncCoordinator);
  });

  tearDown(() async {
    await db.close();
  });

  test(
      'offline partial merge consolidates morning and evening check-ins without data loss',
      () async {
    const userId = 'user-val-1';
    final targetDate = DateTime.utc(2026, 11, 7);

    // 1. Morning Check-in: Sleep + Mood
    final morningLog = DailyWellnessEntity(
      userId: userId,
      logDate: targetDate,
      sleepHours: 7.5,
      sleepQuality: 4,
      energyLevel: 4,
      moodTags: const ['energetic', 'calm'],
    );

    await repository.saveDailyLog(morningLog);

    // Verify morning check-in stored in Drift
    final fetchedMorning =
        await repository.getDailyLog(userId: userId, date: targetDate);
    expect(fetchedMorning, isNotNull);
    expect(fetchedMorning!.sleepHours, equals(7.5));
    expect(fetchedMorning.sleepQuality, equals(4));
    expect(fetchedMorning.hydrationMl, isNull);
    expect(fetchedMorning.moodTags, contains('energetic'));

    // 2. Evening Check-in: Hydration + Exercise (partial update)
    final eveningLog = DailyWellnessEntity(
      userId: userId,
      logDate: targetDate,
      hydrationMl: 2200,
      exerciseMinutes: 45,
      notes: 'Caminata y buena hidratación',
    );

    await repository.saveDailyLog(eveningLog);

    // Verify consolidated record retains morning sleep and mood
    final consolidated =
        await repository.getDailyLog(userId: userId, date: targetDate);
    expect(consolidated, isNotNull);
    expect(consolidated!.sleepHours, equals(7.5));
    expect(consolidated.sleepQuality, equals(4));
    expect(consolidated.energyLevel, equals(4));
    expect(consolidated.hydrationMl, equals(2200));
    expect(consolidated.exerciseMinutes, equals(45));
    expect(consolidated.moodTags, contains('energetic'));
    expect(consolidated.notes, equals('Caminata y buena hidratación'));

    // Verify outbox queued mutations for sync
    final pendingMutations = await syncCoordinator.getPendingMutations();
    expect(pendingMutations.length, equals(2));
    expect(pendingMutations.first.entityType, equals('daily_wellness'));

    final payload = jsonDecode(pendingMutations.last.payloadJson)
        as Map<String, dynamic>;
    expect(payload['hydration_ml'], equals(2200));
  });
}
