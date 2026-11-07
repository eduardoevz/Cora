import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';

void main() {
  late AppDatabase db;
  late SyncCoordinator coordinator;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    coordinator = SyncCoordinator(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('SyncCoordinator enqueues mutation into Drift outbox in pending status',
      () async {
    const mutationId = 'mutation-uuid-001';
    await coordinator.enqueueMutation(
      clientMutationId: mutationId,
      entityType: 'wellness_log',
      entityId: 'log-date-2026-11-07',
      operation: 'upsert',
      payloadJson: '{"water_ml": 2500, "sleep_hours": 7.5}',
    );

    final pending = await coordinator.getPendingMutations();
    expect(pending.length, 1);
    expect(pending.first.clientMutationId, mutationId);
    expect(pending.first.entityType, 'wellness_log');
    expect(pending.first.status, 'pending');
  });

  test('SyncCoordinator marks mutation as synced upon successful push',
      () async {
    const mutationId = 'mutation-uuid-002';
    await coordinator.enqueueMutation(
      clientMutationId: mutationId,
      entityType: 'cycle_log',
      entityId: 'cycle-uuid-1',
      operation: 'upsert',
      payloadJson: '{"flow": "medium"}',
    );

    await coordinator.markAsSynced(mutationId);

    final pending = await coordinator.getPendingMutations();
    expect(pending, isEmpty);

    final all = await db.select(db.syncOutboxEntries).get();
    expect(all.first.status, 'synced');
  });

  test('SyncCoordinator increments attempt count and marks failed on error',
      () async {
    const mutationId = 'mutation-uuid-003';
    await coordinator.enqueueMutation(
      clientMutationId: mutationId,
      entityType: 'vital_sign',
      entityId: 'bp-1',
      operation: 'upsert',
      payloadJson: '{"systolic": 120, "diastolic": 80}',
    );

    await coordinator.recordFailure(
      mutationId,
      errorMessage: 'Connection timeout',
    );

    final all = await db.select(db.syncOutboxEntries).get();
    expect(all.first.status, 'failed');
    expect(all.first.attemptCount, 1);
    expect(all.first.errorMessage, 'Connection timeout');
  });
}
