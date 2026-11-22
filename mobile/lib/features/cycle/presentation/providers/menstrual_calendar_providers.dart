import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/domain/services/cycle_calendar_engine.dart';
import 'package:mobile/features/cycle/presentation/providers/cycle_providers.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

/// Normalized UTC midnight reference date for calendar projection and testing.
final calendarReferenceTodayProvider = StateProvider<DateTime>((ref) {
  return CycleCalendarEngine.normalizeDate(DateTime.now());
});

/// Currently visible year and month in the menstrual calendar.
final selectedCalendarMonthProvider =
    StateProvider<({int year, int month})>((ref) {
  final today = ref.watch(calendarReferenceTodayProvider);
  return (year: today.year, month: today.month);
});

/// Currently selected calendar day (UTC midnight).
final selectedCalendarDateProvider = StateProvider<DateTime>((ref) {
  return ref.watch(calendarReferenceTodayProvider);
});

/// Map of symptom logs indexed by normalized UTC date for the active user.
final calendarSymptomLogsByDateProvider =
    FutureProvider<Map<DateTime, CycleSymptomEntity>>((ref) async {
  final activeUser = ref.watch(activeUserProfileProvider);
  final dbUser =
      activeUser ?? await ref.read(profileDaoProvider).getActiveProfile();
  if (dbUser == null) return const {};

  final repo = ref.watch(cycleRepositoryProvider);
  final logs = await repo.getSymptomLogs(userId: dbUser.id);
  final byDate = <DateTime, CycleSymptomEntity>{};
  for (final log in logs) {
    byDate[CycleCalendarEngine.normalizeDate(log.logDate)] = log;
  }
  return byDate;
});

/// Reactive monthly projection combining active profile, local Drift cycles/symptoms,
/// and [CycleCalendarEngine].
final activeCalendarMonthProjectionProvider =
    FutureProvider<CalendarMonthProjectionEntity>((ref) async {
  final activeUser = ref.watch(activeUserProfileProvider);
  final dbUser = await ref.read(profileDaoProvider).getActiveProfile();
  final resolvedUser = activeUser ?? dbUser;
  final visibleMonth = ref.watch(selectedCalendarMonthProvider);
  final refToday = ref.watch(calendarReferenceTodayProvider);

  const engine = CycleCalendarEngine();

  if (resolvedUser == null) {
    return engine.projectMonth(
      year: visibleMonth.year,
      month: visibleMonth.month,
      cycles: const [],
      symptomLogs: const [],
      lifeStage: LifeStage.regularAdult,
      referenceDate: refToday,
    );
  }

  final repo = ref.watch(cycleRepositoryProvider);
  final cycles = await repo.getCycleHistory(userId: resolvedUser.id, limit: 24);
  final symptoms = await repo.getSymptomLogs(userId: resolvedUser.id);

  final activeCtx = resolvedUser.onboardingContext;
  final dbCtx = (dbUser != null && dbUser.id == resolvedUser.id)
      ? dbUser.onboardingContext
      : null;

  final hormonalMethod = activeCtx.hormonalMethod != HormonalMethod.none
      ? activeCtx.hormonalMethod
      : (dbCtx?.hormonalMethod ?? activeCtx.hormonalMethod);
  final conditions = activeCtx.diagnosedConditions.isNotEmpty
      ? activeCtx.diagnosedConditions
      : (dbCtx?.diagnosedConditions ?? const <DiagnosedCondition>[]);
  final regularity = activeCtx.cycleRegularity != CycleRegularity.unsure
      ? activeCtx.cycleRegularity
      : (dbCtx?.cycleRegularity ?? CycleRegularity.unsure);
  final typicalCycleLen =
      activeCtx.typicalCycleLengthDays ?? dbCtx?.typicalCycleLengthDays;
  final typicalBleedLen = activeCtx.typicalBleedingDurationDays ??
      dbCtx?.typicalBleedingDurationDays;

  return engine.projectMonth(
    year: visibleMonth.year,
    month: visibleMonth.month,
    cycles: cycles,
    symptomLogs: symptoms,
    lifeStage: resolvedUser.currentLifeStage,
    hormonalMethod: hormonalMethod,
    diagnosedConditions: conditions,
    cycleRegularity: regularity,
    typicalCycleLengthDays: typicalCycleLen,
    typicalBleedingDurationDays: typicalBleedLen,
    referenceDate: refToday,
  );
});

/// Derives the [CalendarDayProjectionEntity] for [selectedCalendarDateProvider].
final selectedCalendarDayProjectionProvider =
    Provider<AsyncValue<CalendarDayProjectionEntity?>>((ref) {
  final monthAsync = ref.watch(activeCalendarMonthProjectionProvider);
  final selectedDate = CycleCalendarEngine.normalizeDate(
      ref.watch(selectedCalendarDateProvider));

  return monthAsync.whenData((monthProj) {
    for (final day in monthProj.days) {
      final norm = CycleCalendarEngine.normalizeDate(day.date);
      if (norm.year == selectedDate.year &&
          norm.month == selectedDate.month &&
          norm.day == selectedDate.day) {
        return day;
      }
    }
    return monthProj.days.isNotEmpty ? monthProj.days.first : null;
  });
});

/// Returns the full [CycleSymptomEntity] recorded for [selectedCalendarDateProvider], if any.
final selectedDaySymptomLogProvider = Provider<CycleSymptomEntity?>((ref) {
  final logsAsync = ref.watch(calendarSymptomLogsByDateProvider);
  final selectedDate = CycleCalendarEngine.normalizeDate(
      ref.watch(selectedCalendarDateProvider));
  final map = logsAsync.valueOrNull;
  if (map == null) return null;
  return map[selectedDate];
});

class MenstrualCalendarController {
  final Ref _ref;

  const MenstrualCalendarController(this._ref);

  void selectDate(DateTime date) {
    final normalized = CycleCalendarEngine.normalizeDate(date);
    _ref.read(selectedCalendarDateProvider.notifier).state = normalized;
    final currentMonth = _ref.read(selectedCalendarMonthProvider);
    if (currentMonth.year != normalized.year ||
        currentMonth.month != normalized.month) {
      _ref.read(selectedCalendarMonthProvider.notifier).state = (
        year: normalized.year,
        month: normalized.month,
      );
    }
  }

  void goToMonth(int year, int month) {
    final target = DateTime.utc(year, month, 1);
    _ref.read(selectedCalendarMonthProvider.notifier).state = (
      year: target.year,
      month: target.month,
    );
    final today = _ref.read(calendarReferenceTodayProvider);
    if (today.year == target.year && today.month == target.month) {
      _ref.read(selectedCalendarDateProvider.notifier).state = today;
    } else {
      final prevSelected = _ref.read(selectedCalendarDateProvider);
      if (prevSelected.year != target.year ||
          prevSelected.month != target.month) {
        _ref.read(selectedCalendarDateProvider.notifier).state = target;
      }
    }
  }

  void nextMonth() {
    final current = _ref.read(selectedCalendarMonthProvider);
    goToMonth(current.year, current.month + 1);
  }

  void previousMonth() {
    final current = _ref.read(selectedCalendarMonthProvider);
    goToMonth(current.year, current.month - 1);
  }

  void goToToday() {
    final today = _ref.read(calendarReferenceTodayProvider);
    _ref.read(selectedCalendarMonthProvider.notifier).state = (
      year: today.year,
      month: today.month,
    );
    _ref.read(selectedCalendarDateProvider.notifier).state = today;
  }

  Future<CycleSymptomEntity> saveDayLog({
    required DateTime date,
    required String bleedingFlow,
    int? pelvicPain,
    int? dysmenorrhea,
    bool? dyspareunia,
    int? acneSeverity,
    bool? hirsutism,
    int? fatigueLevel,
    List<String> giSymptoms = const [],
    String? notes,
  }) async {
    final activeUser = _ref.read(activeUserProfileProvider);
    final dbUser =
        activeUser ?? await _ref.read(profileDaoProvider).getActiveProfile();
    if (dbUser == null) {
      throw StateError('No active user profile to log calendar day.');
    }

    final normalized = CycleCalendarEngine.normalizeDate(date);
    final existingMap =
        _ref.read(calendarSymptomLogsByDateProvider).valueOrNull;
    final existing = existingMap?[normalized];

    final repo = _ref.read(cycleRepositoryProvider);
    final saved = await repo.logBleedingAndSymptoms(
      CycleSymptomEntity(
        id: existing?.id ?? '',
        userId: dbUser.id,
        cycleId: existing?.cycleId,
        logDate: normalized,
        bleedingFlow: bleedingFlow,
        pelvicPain: pelvicPain,
        dysmenorrhea: dysmenorrhea,
        dyspareunia: dyspareunia,
        acneSeverity: acneSeverity,
        hirsutism: hirsutism,
        fatigueLevel: fatigueLevel,
        giSymptoms: giSymptoms,
        notes: notes,
      ),
    );

    _ref.read(selectedCalendarDateProvider.notifier).state = normalized;
    _ref.invalidate(calendarSymptomLogsByDateProvider);
    _ref.invalidate(activeCalendarMonthProjectionProvider);
    _ref.invalidate(cycleOverviewProvider);
    _ref.invalidate(cycleHistoryProvider);
    _ref.invalidate(cycleCalendarMonthProvider);

    return saved;
  }
}

final menstrualCalendarControllerProvider =
    Provider<MenstrualCalendarController>((ref) {
  return MenstrualCalendarController(ref);
});
