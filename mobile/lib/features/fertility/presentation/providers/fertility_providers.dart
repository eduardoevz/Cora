import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/cycle/presentation/providers/cycle_providers.dart';
import 'package:mobile/features/fertility/data/fertility_repository_impl.dart';
import 'package:mobile/features/fertility/domain/entities/fertility_chart_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

final fertilityRepositoryProvider = Provider<IFertilityRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncCoordinatorProvider);
  return FertilityRepositoryImpl(db, sync);
});

final fertilityChartDataProvider = FutureProvider.autoDispose
    .family<FertilityCycleChartData, String>((ref, userId) async {
  final fertilityRepo = ref.watch(fertilityRepositoryProvider);
  final cycleRepo = ref.watch(cycleRepositoryProvider);

  // Get active cycle
  final cycles = await cycleRepo.getCycleHistory(userId: userId);
  final currentCycle = cycles.isNotEmpty ? cycles.first : null;

  final now = DateTime.now();
  final cycleStart =
      currentCycle?.startDate ?? DateTime(now.year, now.month, 1);
  final cycleEnd =
      currentCycle?.endDate ?? cycleStart.add(const Duration(days: 45));

  final logs = await fertilityRepo.listFertilityEntriesBetween(
    userId,
    cycleStart,
    cycleEnd,
  );

  final checklist = await fertilityRepo.getPreconceptionChecklist(userId);

  // 3-over-6 symptothermal calculation locally
  final validBbts = logs
      .where((l) => l.bbtCelsius != null && !l.isDisturbed && !l.isFever)
      .toList();

  bool shiftDetected = false;
  double? coverline;
  DateTime? ovulationDate;

  if (validBbts.length >= 9) {
    for (int i = 6; i < validBbts.length - 2; i++) {
      final base6 = validBbts.sublist(i - 6, i);
      final candCoverline = base6.map((b) => b.bbtCelsius!).reduce(max);
      final t1 = validBbts[i].bbtCelsius!;
      final t2 = validBbts[i + 1].bbtCelsius!;
      final t3 = validBbts[i + 2].bbtCelsius!;

      if (t1 > candCoverline &&
          t2 > candCoverline &&
          t3 > candCoverline &&
          (t3 - candCoverline) >= 0.20) {
        shiftDetected = true;
        coverline = double.parse(candCoverline.toStringAsFixed(2));
        ovulationDate = validBbts[i - 1].logDate;
        break;
      }
    }
  }

  // Fertile window estimation
  final cycleLen = currentCycle?.cycleLengthDays ?? 28;
  final estOvulationOffset = max(10, cycleLen - 14);
  final prospectiveOvulation =
      cycleStart.add(Duration(days: estOvulationOffset - 1));
  final fertileStart = prospectiveOvulation.subtract(const Duration(days: 5));
  final fertileEnd = prospectiveOvulation.add(const Duration(days: 1));

  // Recent signs (last 2 days)
  final recentLogs = logs.where((l) {
    final diff = now.difference(l.logDate).inDays;
    return diff >= 0 && diff <= 2;
  }).toList();

  final hasPeakLh = recentLogs.any((l) => l.lhResult == 'peak');
  final hasEggWhite = recentLogs.any((l) => l.cervicalMucus == 'egg_white');
  final hasHighLh = recentLogs.any((l) => l.lhResult == 'high');
  final hasWatery = recentLogs.any((l) => l.cervicalMucus == 'watery');

  String status;
  String notes;

  if (shiftDetected) {
    status = 'ovulation_confirmed';
    notes =
        'Salto térmico bifásico confirmado (Línea base: $coverline °C). Ovulación confirmada alrededor del ${ovulationDate?.day}/${ovulationDate?.month}.';
  } else if (hasPeakLh || hasEggWhite) {
    status = 'peak_fertility';
    notes =
        'Ventana de fertilidad óptima detectada por biomarcadores (LH pico o moco elástico).';
  } else if (hasHighLh || hasWatery) {
    status = 'high';
    notes = 'Fertilidad alta. Incremento de LH o moco lubricante.';
  } else if (now.isAfter(fertileStart.subtract(const Duration(days: 1))) &&
      now.isBefore(fertileEnd.add(const Duration(days: 1)))) {
    status = 'high';
    notes = 'Ventana fértil calculada según longitud de ciclo.';
  } else {
    status = 'low';
    notes = 'Probabilidad de concepción baja en este momento.';
  }

  // Age based guidance
  String? guidance;
  final seekingMonths = checklist?.activeSeekingMonths ?? 0;
  final profile = ref.read(activeUserProfileProvider);
  final age =
      profile != null ? now.year - profile.onboardingContext.birthYear : 28;
  if (age < 35 && seekingMonths >= 12) {
    guidance =
        'Has registrado 12 meses o más de búsqueda activa. Las guías clínicas recomiendan consultar con un especialista en fertilidad para una valoración preventiva.';
  } else if (age >= 35 && seekingMonths >= 6) {
    guidance =
        'Has registrado 6 meses o más de búsqueda activa. A partir de los 35 años, las guías clínicas aconsejan solicitar una valoración especializada para optimizar tiempos.';
  }

  final dailyPoints = logs.map((l) {
    final cDay = l.logDate.difference(cycleStart).inDays + 1;
    return FertilityChartPoint(
      logDate: l.logDate,
      cycleDay: cDay,
      bbtCelsius: l.bbtCelsius,
      bbtFahrenheit: l.bbtFahrenheit,
      isDisturbed: l.isDisturbed,
      disturbanceReason: l.disturbanceReason,
      cervicalMucus: l.cervicalMucus,
      lhResult: l.lhResult,
      intercourseHad: l.intercourseHad,
      intercourseType: l.intercourseType,
    );
  }).toList();

  return FertilityCycleChartData(
    cycleId: currentCycle?.id,
    cycleStartDate: cycleStart,
    cycleDay: now.difference(cycleStart).inDays + 1,
    status: status,
    coverlineCelsius: coverline,
    coverlineFahrenheit: coverline != null
        ? double.parse(((coverline * 9 / 5) + 32).toStringAsFixed(2))
        : null,
    ovulationConfirmedDate: ovulationDate,
    fertileWindowStart: fertileStart,
    fertileWindowEnd: fertileEnd,
    isBiphasicShiftDetected: shiftDetected,
    evaluationNotesEs: notes,
    activeSeekingGuidanceEs: guidance,
    dailyEntries: dailyPoints,
  );
});

final preconceptionChecklistProvider = FutureProvider.autoDispose
    .family<PreconceptionChecklistEntity, String>((ref, userId) async {
  final repo = ref.watch(fertilityRepositoryProvider);
  final existing = await repo.getPreconceptionChecklist(userId);
  return existing ??
      PreconceptionChecklistEntity(
        userId: userId,
        updatedAt: DateTime.now(),
      );
});
