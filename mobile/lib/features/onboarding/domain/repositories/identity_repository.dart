import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';

abstract class IdentityRepository {
  Future<UserProfileEntity?> getActiveProfile();
  Stream<UserProfileEntity?> watchActiveProfile();
  Future<UserProfileEntity> completeOnboarding(UserProfileEntity profile);
  Future<UserProfileEntity> switchLifeStage({
    required String profileId,
    required LifeStage newStage,
    required TransitionReason reason,
    String? notes,
  });
  Future<UserProfileEntity> updateModulePreferences({
    required String profileId,
    required List<String> modules,
  });

  List<String> getDefaultModulesForStage(LifeStage stage);
}
