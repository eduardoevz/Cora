import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/notifications/discreet_notification_service.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/treatments/data/treatments_repository_impl.dart';
import 'package:mobile/features/treatments/domain/entities/treatment_entities.dart';

final treatmentsRepositoryProvider = Provider<TreatmentsRepositoryImpl>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncCoordinatorProvider);
  return TreatmentsRepositoryImpl(db, sync);
});

final discreetNotificationServiceProvider =
    Provider<DiscreetNotificationService>((ref) {
  return DiscreetNotificationService();
});

final userRegimensProvider =
    FutureProvider.family<List<TreatmentRegimenEntity>, String>(
        (ref, userId) async {
  final repo = ref.watch(treatmentsRepositoryProvider);
  return repo.getRegimens(userId: userId, isActive: true);
});
