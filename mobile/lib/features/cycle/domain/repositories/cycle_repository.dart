import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';

abstract class CycleRepository {
  Future<CycleOverviewEntity> getCycleOverview({
    required String userId,
    DateTime? referenceDate,
  });

  Future<CycleSymptomEntity> logBleedingAndSymptoms(CycleSymptomEntity symptom);

  Future<List<MenstrualCycleEntity>> getCycleHistory({
    required String userId,
    int limit = 12,
  });

  Future<List<CycleSymptomEntity>> getSymptomLogs({
    required String userId,
  });
}
