import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';

abstract class CycleRepository {
  Future<CycleOverviewEntity> getCycleOverview({
    required String userId,
    DateTime? referenceDate,
  });

  Future<CycleSymptomEntity> logBleedingAndSymptoms(CycleSymptomEntity symptom);

  Future<List<MenstrualCycleEntity>> seedInitialPeriods({
    required String userId,
    required List<InitialPeriodRangeEntity> periods,
    CycleRegularity? cycleRegularity,
    int? typicalCycleLengthDays,
    int? typicalBleedingDurationDays,
    bool syncRemote = true,
  });

  Future<CalendarMonthProjectionEntity> getCalendarMonth({
    required String userId,
    required int year,
    required int month,
    DateTime? referenceDate,
  });

  Future<List<MenstrualCycleEntity>> getCycleHistory({
    required String userId,
    int limit = 12,
  });

  Future<List<CycleSymptomEntity>> getSymptomLogs({
    required String userId,
  });
}
