import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/cora_api_client.dart';
import 'package:mobile/features/cycle/data/cycle_repository_impl.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncCoordinatorProvider);
  final api = ref.watch(coraApiClientProvider);
  return CycleRepositoryImpl(db, sync, api);
});

final cycleOverviewProvider = FutureProvider.family<CycleOverviewEntity,
    ({String userId, DateTime? referenceDate})>((ref, args) async {
  final repo = ref.watch(cycleRepositoryProvider);
  return repo.getCycleOverview(
    userId: args.userId,
    referenceDate: args.referenceDate,
  );
});

final cycleHistoryProvider =
    FutureProvider.family<List<MenstrualCycleEntity>, String>((ref, userId) async {
  final repo = ref.watch(cycleRepositoryProvider);
  return repo.getCycleHistory(userId: userId);
});
