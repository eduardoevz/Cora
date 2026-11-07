import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/notifications/discreet_notification_service.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/treatments/data/treatments_repository_impl.dart';
import 'package:mobile/features/treatments/domain/entities/treatment_entities.dart';

void main() {
  late AppDatabase db;
  late SyncCoordinator syncCoordinator;
  late TreatmentsRepositoryImpl repository;
  late DiscreetNotificationService notificationService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncCoordinator = SyncCoordinator(db);
    repository = TreatmentsRepositoryImpl(db, syncCoordinator);
    notificationService = DiscreetNotificationService();
  });

  tearDown(() async {
    await db.close();
  });

  group('DiscreetNotificationService privacy tests', () {
    test('default masked mode masks clinical details for privacy', () {
      final content = notificationService.formatReminder(
        type: NotificationType.treatmentIntake,
        detailedTitle: 'Tomar Microgynon 21',
        detailedBody: 'Dosis programada de anticonceptivo a las 21:00',
        isDiscreet: true,
      );

      expect(content.title, equals('Cora'));
      expect(
          content.body, equals('Tienes un recordatorio de bienestar en Cora'));
    });

    test('explicitly disabling discreet mode displays detailed medication text',
        () {
      final content = notificationService.formatReminder(
        type: NotificationType.treatmentIntake,
        detailedTitle: 'Tomar Microgynon 21',
        detailedBody: 'Dosis programada de anticonceptivo a las 21:00',
        isDiscreet: false,
      );

      expect(content.title, equals('Tomar Microgynon 21'));
      expect(content.body,
          equals('Dosis programada de anticonceptivo a las 21:00'));
    });
  });

  group('Offline Pillbox Intake logging', () {
    test(
        'logging dose intake offline persists to Drift and enqueues sync outbox mutation',
        () async {
      const userId = 'user-val-1';
      final regimen = TreatmentRegimenEntity(
        id: 'regimen-microgynon-1',
        userId: userId,
        name: 'Microgynon 21',
        category: 'contraceptive_oral_combined',
        dosage: '1 comprimido',
        scheduleType: 'cyclic_active_break',
        scheduledTime: '21:00',
        activeDays: 21,
        breakDays: 7,
        startDate: DateTime.utc(2026, 11, 1),
        isActive: true,
      );

      await repository.saveRegimen(regimen);

      // Verify regimen persisted
      final storedRegimens = await repository.getRegimens(userId: userId);
      expect(storedRegimens.length, equals(1));
      expect(storedRegimens.first.name, equals('Microgynon 21'));

      // Log intake offline
      final scheduledFor = DateTime.utc(2026, 11, 7, 21, 0);
      final takenAt = DateTime.utc(2026, 11, 7, 21, 5);

      final loggedIntake = await repository.recordIntake(
        regimenId: regimen.id,
        scheduledFor: scheduledFor,
        takenAt: takenAt,
        status: 'taken',
        notes: 'Tomada puntual con agua',
      );

      expect(loggedIntake.status, equals('taken'));
      expect(loggedIntake.clientMutationId, isNotNull);

      // Verify intake stored in Drift
      final intakes = await repository.getIntakes(
        regimenId: regimen.id,
        from: DateTime.utc(2026, 11, 1),
        to: DateTime.utc(2026, 11, 8),
      );
      expect(intakes.length, equals(1));
      expect(intakes.first.status, equals('taken'));

      // Verify queued in outbox
      final pending = await syncCoordinator.getPendingMutations();
      expect(pending.any((m) => m.entityType == 'treatment_intake'), isTrue);

      final mutation =
          pending.firstWhere((m) => m.entityType == 'treatment_intake');
      final payload =
          jsonDecode(mutation.payloadJson) as Map<String, dynamic>;
      expect(payload['regimen_id'], equals(regimen.id));
      expect(payload['status'], equals('taken'));
    });
  });
}
