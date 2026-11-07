import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/onboarding/data/local/profile_dao.dart';
import 'package:mobile/features/onboarding/data/repositories/identity_repository_impl.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/domain/repositories/identity_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final profileDaoProvider = Provider<ProfileDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProfileDao(db);
});

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncCoordinator(db);
});

final identityRepositoryProvider = Provider<IdentityRepository>((ref) {
  return IdentityRepositoryImpl(
    profileDao: ref.watch(profileDaoProvider),
    syncCoordinator: ref.watch(syncCoordinatorProvider),
  );
});

/// Holds the currently active user profile.
final activeUserProfileProvider = StateProvider<UserProfileEntity?>((ref) {
  return null;
});

/// Derives the current life stage from the active profile.
final currentLifeStageProvider = Provider<LifeStage?>((ref) {
  final profile = ref.watch(activeUserProfileProvider);
  return profile?.currentLifeStage;
});

/// Derives enabled modules from the active profile.
final enabledModulesProvider = Provider<List<String>>((ref) {
  final profile = ref.watch(activeUserProfileProvider);
  return profile?.enabledModules ?? const [];
});
