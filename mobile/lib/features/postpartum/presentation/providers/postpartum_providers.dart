import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/postpartum/data/postpartum_repository_impl.dart';
import 'package:mobile/features/postpartum/domain/entities/postpartum_entities.dart';

final postpartumRepositoryProvider = Provider<IPostpartumRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncCoordinator = ref.watch(syncCoordinatorProvider);
  return PostpartumRepositoryImpl(db, syncCoordinator);
});

final recentRecoveryLogsProvider =
    FutureProvider<List<PostpartumRecoveryLog>>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  if (user == null) return [];
  final repo = ref.watch(postpartumRepositoryProvider);
  return repo.getRecentRecoveryLogs(user.id);
});

final recentLactationSessionsProvider =
    FutureProvider<List<LactationSession>>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  if (user == null) return [];
  final repo = ref.watch(postpartumRepositoryProvider);
  return repo.getRecentLactationSessions(user.id);
});

final suggestedNextBreastProvider = Provider<OfferedBreast>((ref) {
  final sessionsAsync = ref.watch(recentLactationSessionsProvider);
  return sessionsAsync.maybeWhen(
    data: (sessions) {
      if (sessions.isEmpty) return OfferedBreast.left;
      final last = sessions.first.lastOfferedBreast;
      return LactationSession.calculateNextBreast(last);
    },
    orElse: () => OfferedBreast.left,
  );
});

final activeMilkStashProvider =
    FutureProvider<List<MilkStashEntry>>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  if (user == null) return [];
  final repo = ref.watch(postpartumRepositoryProvider);
  return repo.getActiveMilkStash(user.id);
});

final latestEpdsScreeningProvider =
    FutureProvider<EpdsScreening?>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  if (user == null) return null;
  final repo = ref.watch(postpartumRepositoryProvider);
  return repo.getLatestEpdsScreening(user.id);
});
