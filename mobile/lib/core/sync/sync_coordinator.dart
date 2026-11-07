import 'package:drift/drift.dart';
import 'package:mobile/core/database/app_database.dart';

class SyncCoordinator {
  final AppDatabase _db;

  SyncCoordinator(this._db);

  /// Enqueue an idempotent mutation to be pushed to the remote server.
  Future<void> enqueueMutation({
    required String clientMutationId,
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
  }) async {
    final entry = SyncOutboxEntriesCompanion.insert(
      clientMutationId: clientMutationId,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payloadJson: payloadJson,
      status: const Value('pending'),
      attemptCount: const Value(0),
      createdAt: Value(DateTime.now().toUtc()),
      updatedAt: Value(DateTime.now().toUtc()),
    );

    await _db.into(_db.syncOutboxEntries).insert(
          entry,
          mode: InsertMode.insertOrReplace,
        );
  }

  /// Get all pending mutations ordered FIFO by creation time.
  Future<List<SyncOutboxEntry>> getPendingMutations() {
    return (_db.select(_db.syncOutboxEntries)
          ..where((tbl) => tbl.status.equals('pending'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  /// Stream of pending mutation count for reactive UI indicators.
  Stream<int> watchPendingCount() {
    return (_db.selectOnly(_db.syncOutboxEntries)
          ..addColumns([_db.syncOutboxEntries.id.count()])
          ..where(_db.syncOutboxEntries.status.equals('pending')))
        .map((row) => row.read(_db.syncOutboxEntries.id.count()) ?? 0)
        .watchSingle();
  }

  /// Mark mutation as successfully synced with the server.
  Future<void> markAsSynced(String clientMutationId) async {
    await (_db.update(_db.syncOutboxEntries)
          ..where((tbl) => tbl.clientMutationId.equals(clientMutationId)))
        .write(
      SyncOutboxEntriesCompanion(
        status: const Value('synced'),
        errorMessage: const Value(null),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Record a sync failure, incrementing attempt count.
  Future<void> recordFailure(
    String clientMutationId, {
    required String errorMessage,
  }) async {
    final current = await (_db.select(_db.syncOutboxEntries)
          ..where((tbl) => tbl.clientMutationId.equals(clientMutationId)))
        .getSingleOrNull();

    final attempts = (current?.attemptCount ?? 0) + 1;

    await (_db.update(_db.syncOutboxEntries)
          ..where((tbl) => tbl.clientMutationId.equals(clientMutationId)))
        .write(
      SyncOutboxEntriesCompanion(
        status: const Value('failed'),
        attemptCount: Value(attempts),
        errorMessage: Value(errorMessage),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
