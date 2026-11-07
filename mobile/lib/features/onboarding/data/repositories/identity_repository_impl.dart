import 'dart:convert';

import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/features/onboarding/data/local/profile_dao.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/domain/repositories/identity_repository.dart';
import 'package:uuid/uuid.dart';

class IdentityRepositoryImpl implements IdentityRepository {
  final ProfileDao _profileDao;
  final SyncCoordinator? _syncCoordinator;
  final Uuid _uuid;

  IdentityRepositoryImpl({
    required ProfileDao profileDao,
    SyncCoordinator? syncCoordinator,
    Uuid? uuid,
  })  : _profileDao = profileDao,
        _syncCoordinator = syncCoordinator,
        _uuid = uuid ?? const Uuid();

  @override
  List<String> getDefaultModulesForStage(LifeStage stage) {
    switch (stage) {
      case LifeStage.adolescence:
        return const [
          'cycle_tracking',
          'symptom_diary',
          'education_body_basics'
        ];
      case LifeStage.regularAdult:
        return const [
          'cycle_tracking',
          'ovulation_prediction',
          'symptom_diary',
          'contraceptive_management'
        ];
      case LifeStage.conceptionSearch:
        return const [
          'fertility_bbt',
          'lh_surge_prediction',
          'cervical_mucus',
          'partner_sharing'
        ];
      case LifeStage.pregnancy:
        return const [
          'fetal_development',
          'maternal_vitals',
          'kick_counter',
          'birth_plan',
          'partner_sharing'
        ];
      case LifeStage.postpartum:
        return const [
          'postpartum_lochia',
          'pelvic_floor',
          'epds_screening',
          'breastfeeding_tracker',
          'partner_sharing'
        ];
      case LifeStage.perimenopause:
        return const [
          'vasomotor_hot_flashes',
          'cycle_variability',
          'sleep_and_mood',
          'hormone_therapy'
        ];
      case LifeStage.seniorVitality:
        return const [
          'bone_muscle_health',
          'urogynecology',
          'cardiovascular_prevention',
          'preventive_checkups'
        ];
    }
  }

  @override
  Future<UserProfileEntity?> getActiveProfile() {
    return _profileDao.getActiveProfile();
  }

  @override
  Stream<UserProfileEntity?> watchActiveProfile() {
    return _profileDao.watchActiveProfile();
  }

  @override
  Future<UserProfileEntity> completeOnboarding(
      UserProfileEntity profile) async {
    final modules = profile.enabledModules.isNotEmpty
        ? profile.enabledModules
        : getDefaultModulesForStage(profile.currentLifeStage);

    final finalProfile = UserProfileEntity(
      id: profile.id,
      firebaseUid: profile.firebaseUid,
      firstName: profile.firstName,
      lastName: profile.lastName,
      currentLifeStage: profile.currentLifeStage,
      onboardingCompleted: true,
      onboardingContext: profile.onboardingContext,
      enabledModules: modules,
      transitionHistory: profile.transitionHistory,
      createdAt: profile.createdAt,
      updatedAt: DateTime.now(),
    );

    await _profileDao.saveProfile(finalProfile);

    // Enqueue idempotent offline-first sync mutation
    final coordinator = _syncCoordinator;
    if (coordinator != null) {
      final payload = {
        'first_name': finalProfile.firstName,
        'last_name': finalProfile.lastName,
        'current_life_stage': finalProfile.currentLifeStage.value,
        'birth_year': finalProfile.onboardingContext.birthYear,
        'primary_intents': finalProfile.onboardingContext.primaryIntents
            .map((i) => i.value)
            .toList(),
        'hormonal_method': finalProfile.onboardingContext.hormonalMethod?.value,
        'diagnosed_conditions': finalProfile
            .onboardingContext.diagnosedConditions
            .map((c) => c.value)
            .toList(),
        'clinical_context_completed':
            finalProfile.onboardingContext.clinicalContextCompleted,
      };

      await coordinator.enqueueMutation(
        clientMutationId: _uuid.v4(),
        entityType: 'user_profile',
        entityId: finalProfile.id,
        operation: 'complete_onboarding',
        payloadJson: jsonEncode(payload),
      );
    }

    return finalProfile;
  }

  @override
  Future<UserProfileEntity> switchLifeStage({
    required String profileId,
    required LifeStage newStage,
    required TransitionReason reason,
    String? notes,
  }) async {
    final current = await _profileDao.getActiveProfile();
    if (current == null) {
      throw StateError(
          'Cannot switch life stage: no active user profile found.');
    }

    final newModules = getDefaultModulesForStage(newStage);
    final transition = LifeStageTransitionEntity(
      id: _uuid.v4(),
      fromStage: current.currentLifeStage,
      toStage: newStage,
      reason: reason,
      notes: notes,
      occurredAt: DateTime.now(),
    );

    await _profileDao.updateStage(
      profileId,
      newStage,
      transition,
      newModules,
    );

    final coordinator = _syncCoordinator;
    if (coordinator != null) {
      final payload = {
        'target_stage': newStage.value,
        'reason': reason.value,
        'notes': notes,
      };

      await coordinator.enqueueMutation(
        clientMutationId: _uuid.v4(),
        entityType: 'life_stage_transition',
        entityId: transition.id,
        operation: 'switch_life_stage',
        payloadJson: jsonEncode(payload),
      );
    }

    final updated = await _profileDao.getActiveProfile();
    return updated!;
  }

  @override
  Future<UserProfileEntity> updateModulePreferences({
    required String profileId,
    required List<String> modules,
  }) async {
    await _profileDao.updateEnabledModules(profileId, modules);

    final coordinator = _syncCoordinator;
    if (coordinator != null) {
      final payload = {'enabled_modules': modules};

      await coordinator.enqueueMutation(
        clientMutationId: _uuid.v4(),
        entityType: 'module_preferences',
        entityId: profileId,
        operation: 'update_module_preferences',
        payloadJson: jsonEncode(payload),
      );
    }

    final updated = await _profileDao.getActiveProfile();
    return updated!;
  }
}
