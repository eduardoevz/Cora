import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/menopause/data/menopause_repository_impl.dart';
import 'package:mobile/features/menopause/domain/models/cardiometabolic_panel.dart';
import 'package:mobile/features/menopause/domain/models/hot_flash_episode.dart';
import 'package:mobile/features/menopause/domain/models/vaginal_bleeding_record.dart';
import 'package:mobile/features/menopause/domain/services/menopause_offline_evaluator.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

final menopauseRepositoryProvider = Provider<IMenopauseRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncCoordinator = ref.watch(syncCoordinatorProvider);
  return MenopauseRepositoryImpl(db, syncCoordinator);
});

final menopauseOfflineEvaluatorProvider = Provider<MenopauseOfflineEvaluator>((ref) {
  return const MenopauseOfflineEvaluator();
});

final recentHotFlashesProvider =
    FutureProvider<List<HotFlashEpisode>>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  if (user == null) return [];
  final repo = ref.watch(menopauseRepositoryProvider);
  return repo.getRecentHotFlashes(user.id);
});

final latestCardiometabolicProvider =
    FutureProvider<CardiometabolicPanel?>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  if (user == null) return null;
  final repo = ref.watch(menopauseRepositoryProvider);
  return repo.getLatestCardiometabolicPanel(user.id);
});

final recentBleedingRecordsProvider =
    FutureProvider<List<VaginalBleedingRecord>>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  if (user == null) return [];
  final repo = ref.watch(menopauseRepositoryProvider);
  return repo.getRecentBleedingRecords(user.id);
});
