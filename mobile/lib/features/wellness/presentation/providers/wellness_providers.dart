import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/wellness/data/wellness_repository_impl.dart';
import 'package:mobile/features/wellness/domain/entities/daily_wellness_entity.dart';

final wellnessRepositoryProvider = Provider<WellnessRepositoryImpl>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncCoordinatorProvider);
  return WellnessRepositoryImpl(db, sync);
});

final dailyWellnessForDateProvider = FutureProvider.family<DailyWellnessEntity?,
    ({String userId, DateTime date})>((ref, args) async {
  final repo = ref.watch(wellnessRepositoryProvider);
  return repo.getDailyLog(userId: args.userId, date: args.date);
});
