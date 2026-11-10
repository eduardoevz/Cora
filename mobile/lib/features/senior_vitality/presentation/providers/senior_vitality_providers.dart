import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/senior_vitality/data/senior_vitality_repository_impl.dart';
import 'package:mobile/features/senior_vitality/domain/models/dexa_bone_scan.dart';
import 'package:mobile/features/senior_vitality/domain/models/fall_risk_entry.dart';
import 'package:mobile/features/senior_vitality/domain/models/pelvic_floor_entry.dart';
import 'package:mobile/features/senior_vitality/domain/models/trusted_support_contact.dart';
import 'package:mobile/features/senior_vitality/domain/services/senior_vitality_offline_evaluator.dart';

final seniorVitalityRepositoryProvider =
    Provider<ISeniorVitalityRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncCoordinator = ref.watch(syncCoordinatorProvider);
  return SeniorVitalityRepositoryImpl(db, syncCoordinator);
});

final seniorVitalityOfflineEvaluatorProvider =
    Provider<SeniorVitalityOfflineEvaluator>((ref) {
  return const SeniorVitalityOfflineEvaluator();
});

final latestDexaScanProvider = FutureProvider<DexaBoneScan?>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  if (user == null) return null;
  final repo = ref.watch(seniorVitalityRepositoryProvider);
  return repo.getLatestDexaScan(user.id);
});

final latestFallRiskProvider = FutureProvider<FallRiskEntry?>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  if (user == null) return null;
  final repo = ref.watch(seniorVitalityRepositoryProvider);
  return repo.getLatestFallRiskAssessment(user.id);
});

final recentPelvicLogsProvider =
    FutureProvider<List<PelvicFloorEntry>>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  if (user == null) return [];
  final repo = ref.watch(seniorVitalityRepositoryProvider);
  return repo.getRecentPelvicLogs(user.id);
});

final primarySupportContactProvider =
    FutureProvider<TrustedSupportContact?>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  if (user == null) return null;
  final repo = ref.watch(seniorVitalityRepositoryProvider);
  return repo.getPrimarySupportContact(user.id);
});
