enum AnatomicalSite {
  lumbarSpine('LUMBAR_SPINE'),
  femoralNeck('FEMORAL_NECK'),
  totalHip('TOTAL_HIP'),
  distalRadius('DISTAL_RADIUS');

  final String value;
  const AnatomicalSite(this.value);

  static AnatomicalSite fromValue(String val) {
    return AnatomicalSite.values.firstWhere(
      (e) => e.value == val,
      orElse: () => AnatomicalSite.lumbarSpine,
    );
  }
}

enum BoneDensityCategory {
  normal('NORMAL'),
  osteopenia('OSTEOPENIA'),
  osteoporosis('OSTEOPOROSIS'),
  severeOsteoporosis('SEVERE_OSTEOPOROSIS');

  final String value;
  const BoneDensityCategory(this.value);

  static BoneDensityCategory fromValue(String val) {
    return BoneDensityCategory.values.firstWhere(
      (e) => e.value == val,
      orElse: () => BoneDensityCategory.normal,
    );
  }
}

class DexaBoneScan {
  final String id;
  final String userId;
  final DateTime scanDate;
  final AnatomicalSite anatomicalSite;
  final double tScore;
  final double? zScore;
  final double? bmdGCm2;
  final bool previousFragilityFracture;
  final BoneDensityCategory category;
  final String? notes;

  const DexaBoneScan({
    required this.id,
    required this.userId,
    required this.scanDate,
    required this.anatomicalSite,
    required this.tScore,
    this.zScore,
    this.bmdGCm2,
    this.previousFragilityFracture = false,
    this.category = BoneDensityCategory.normal,
    this.notes,
  });
}
