enum LifeStage {
  adolescence('adolescence', 'Adolescencia / Primeros ciclos'),
  regularAdult('regular_adult', 'Juventud y vida adulta regular'),
  conceptionSearch('conception_search', 'Búsqueda de embarazo / Fertilidad'),
  pregnancy('pregnancy', 'Embarazo Actual'),
  postpartum('postpartum', 'Posparto / Lactancia'),
  perimenopause('perimenopause', 'Perimenopausia / Menopausia'),
  seniorVitality('senior_vitality', 'Plenitud / Adulta Mayor');

  final String value;
  final String label;
  const LifeStage(this.value, this.label);

  static LifeStage fromValue(String val) => LifeStage.values
      .firstWhere((e) => e.value == val, orElse: () => LifeStage.regularAdult);
}

enum PrimaryIntent {
  cycleAndSymptoms(
      'cycle_and_symptoms', 'Seguir y predecir mi ciclo menstrual y síntomas'),
  familyPlanning(
      'family_planning', 'Planificación familiar (quedar o evitar embarazo)'),
  pregnancyTracking(
      'pregnancy_tracking', 'Acompañamiento en mi embarazo semana a semana'),
  hormonalAndClimacteric('hormonal_and_climacteric',
      'Manejar cambios hormonales, sofocos o sueño'),
  preventiveHealth(
      'preventive_health', 'Monitoreo de salud preventiva y chequeos'),
  generalWellness(
      'general_wellness', 'Bienestar general (nutrición, energía, ejercicio)');

  final String value;
  final String label;
  const PrimaryIntent(this.value, this.label);

  static PrimaryIntent fromValue(String val) =>
      PrimaryIntent.values.firstWhere((e) => e.value == val,
          orElse: () => PrimaryIntent.generalWellness);
}

enum HormonalMethod {
  none('none', 'Ninguno'),
  combinedOralPill('combined_oral_pill', 'Pastillas combinadas'),
  progestinOnlyPill('progestin_only_pill', 'Pastillas de solo progestina'),
  hormonalIud('hormonal_iud', 'DIU hormonal'),
  copperIud('copper_iud', 'DIU de cobre'),
  subdermalImplant('subdermal_implant', 'Implante subdérmico'),
  transdermalPatch('transdermal_patch', 'Parche transdérmico'),
  injectable('injectable', 'Inyectable'),
  hormoneReplacementTherapy(
      'hormone_replacement_therapy', 'Terapia de Reemplazo Hormonal (TRH)'),
  other('other', 'Otro');

  final String value;
  final String label;
  const HormonalMethod(this.value, this.label);

  static HormonalMethod fromValue(String val) => HormonalMethod.values
      .firstWhere((e) => e.value == val, orElse: () => HormonalMethod.none);
}

enum DiagnosedCondition {
  pcos('pcos', 'Síndrome de Ovario Poliquístico (SOP)'),
  endometriosis('endometriosis', 'Endometriosis'),
  thyroidDisorder('thyroid_disorder', 'Alteraciones tiroideas'),
  insulinResistanceOrDiabetes(
      'insulin_resistance_or_diabetes', 'Resistencia a la insulina / Diabetes'),
  none('none', 'Ninguna');

  final String value;
  final String label;
  const DiagnosedCondition(this.value, this.label);

  static DiagnosedCondition fromValue(String val) => DiagnosedCondition.values
      .firstWhere((e) => e.value == val, orElse: () => DiagnosedCondition.none);
}

enum TransitionReason {
  naturalProgression('natural_progression', 'Evolución biológica natural'),
  conceptionConfirmed('conception_confirmed', 'Embarazo confirmado'),
  childbirth('childbirth', 'Parto / Nacimiento'),
  pregnancyLoss('pregnancy_loss', 'Pérdida gestacional'),
  userManualSelection('user_manual_selection', 'Selección manual');

  final String value;
  final String label;
  const TransitionReason(this.value, this.label);

  static TransitionReason fromValue(String val) =>
      TransitionReason.values.firstWhere((e) => e.value == val,
          orElse: () => TransitionReason.userManualSelection);
}

class LifeStageTransitionEntity {
  final String id;
  final LifeStage fromStage;
  final LifeStage toStage;
  final TransitionReason reason;
  final String? notes;
  final DateTime occurredAt;

  const LifeStageTransitionEntity({
    required this.id,
    required this.fromStage,
    required this.toStage,
    required this.reason,
    this.notes,
    required this.occurredAt,
  });
}

class OnboardingContextEntity {
  final int birthYear;
  final List<PrimaryIntent> primaryIntents;
  final HormonalMethod? hormonalMethod;
  final List<DiagnosedCondition> diagnosedConditions;
  final bool clinicalContextCompleted;

  const OnboardingContextEntity({
    required this.birthYear,
    required this.primaryIntents,
    this.hormonalMethod,
    this.diagnosedConditions = const [],
    this.clinicalContextCompleted = false,
  });
}

class UserProfileEntity {
  final String id;
  final String firebaseUid;
  final String firstName;
  final String lastName;
  final LifeStage currentLifeStage;
  final bool onboardingCompleted;
  final OnboardingContextEntity onboardingContext;
  final List<String> enabledModules;
  final List<LifeStageTransitionEntity> transitionHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfileEntity({
    required this.id,
    required this.firebaseUid,
    required this.firstName,
    required this.lastName,
    required this.currentLifeStage,
    required this.onboardingCompleted,
    required this.onboardingContext,
    required this.enabledModules,
    this.transitionHistory = const [],
    required this.createdAt,
    required this.updatedAt,
  });
}
