import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/pregnancy/data/pregnancy_repository_impl.dart';
import 'package:mobile/features/pregnancy/domain/entities/pregnancy_entities.dart';

final pregnancyRepositoryProvider = Provider<IPregnancyRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncCoordinator = ref.watch(syncCoordinatorProvider);
  return PregnancyRepositoryImpl(db, syncCoordinator);
});

final activePregnancyEpisodeProvider =
    FutureProvider<PregnancyEpisodeEntity?>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  if (user == null) return null;
  final repo = ref.watch(pregnancyRepositoryProvider);
  return repo.getActiveEpisode(user.id);
});

class PregnancySummaryData {
  final PregnancyEpisodeEntity episode;
  final int gestationalWeeks;
  final int gestationalDays;
  final int trimester;
  final int daysToEdd;

  const PregnancySummaryData({
    required this.episode,
    required this.gestationalWeeks,
    required this.gestationalDays,
    required this.trimester,
    required this.daysToEdd,
  });
}

final pregnancySummaryProvider =
    Provider<AsyncValue<PregnancySummaryData?>>((ref) {
  final episodeAsync = ref.watch(activePregnancyEpisodeProvider);

  return episodeAsync.whenData((episode) {
    if (episode == null) return null;
    final now = DateTime.now();
    DateTime anchor;
    if (episode.ultrasoundEdd != null) {
      anchor = episode.ultrasoundEdd!.subtract(const Duration(days: 280));
    } else if (episode.lastMenstrualPeriod != null) {
      anchor = episode.lastMenstrualPeriod!;
    } else {
      anchor = episode.clinicalEdd.subtract(const Duration(days: 280));
    }

    final diffDays = now.difference(anchor).inDays;
    final weeks = (diffDays / 7).floor().clamp(3, 44);
    final days = (diffDays % 7).clamp(0, 6);

    int trimester = 1;
    if (weeks > 13 && weeks <= 27) {
      trimester = 2;
    } else if (weeks > 27) {
      trimester = 3;
    }

    final daysToEdd = episode.clinicalEdd.difference(now).inDays.clamp(0, 280);

    return PregnancySummaryData(
      episode: episode,
      gestationalWeeks: weeks,
      gestationalDays: days,
      trimester: trimester,
      daysToEdd: daysToEdd,
    );
  });
});

final recentMaternalVitalsProvider =
    FutureProvider<List<MaternalVitalsEntity>>((ref) async {
  final episode = ref.watch(activePregnancyEpisodeProvider).valueOrNull;
  if (episode == null) return [];
  final repo = ref.watch(pregnancyRepositoryProvider);
  return repo.getRecentVitals(episode.id);
});

final contractionSessionsProvider =
    FutureProvider<List<ContractionSessionEntity>>((ref) async {
  final episode = ref.watch(activePregnancyEpisodeProvider).valueOrNull;
  if (episode == null) return [];
  final repo = ref.watch(pregnancyRepositoryProvider);
  return repo.getContractionSessions(episode.id);
});

final kickSessionsProvider =
    FutureProvider<List<KickSessionEntity>>((ref) async {
  final episode = ref.watch(activePregnancyEpisodeProvider).valueOrNull;
  if (episode == null) return [];
  final repo = ref.watch(pregnancyRepositoryProvider);
  return repo.getKickSessions(episode.id);
});

final birthPlanProvider = FutureProvider<BirthPlanEntity?>((ref) async {
  final episode = ref.watch(activePregnancyEpisodeProvider).valueOrNull;
  if (episode == null) return null;
  final repo = ref.watch(pregnancyRepositoryProvider);
  return repo.getBirthPlan(episode.id);
});

final prenatalAppointmentsProvider =
    FutureProvider<List<PrenatalAppointmentEntity>>((ref) async {
  final episode = ref.watch(activePregnancyEpisodeProvider).valueOrNull;
  if (episode == null) return [];
  final repo = ref.watch(pregnancyRepositoryProvider);
  return repo.getAppointments(episode.id);
});
