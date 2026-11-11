import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/cora_api_client.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/records/data/medical_records_repository_impl.dart';
import 'package:mobile/features/records/domain/models/medical_exam_record.dart';
import 'package:mobile/features/records/domain/models/preventive_screening_item.dart';
import 'package:mobile/features/records/domain/models/specialist_entry.dart';
import 'package:mobile/features/records/domain/models/vaccination_record.dart';

final medicalRecordsRepositoryProvider =
    Provider<IMedicalRecordsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncCoordinator = ref.watch(syncCoordinatorProvider);
  final apiClient = ref.watch(coraApiClientProvider);
  return MedicalRecordsRepositoryImpl(db, syncCoordinator, apiClient);
});

final selectedExamTypeFilterProvider = StateProvider<ExamType?>((ref) => null);

final medicalExamsProvider =
    FutureProvider<List<MedicalExamRecord>>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  final userId = user?.id ?? 'default-user';
  final filter = ref.watch(selectedExamTypeFilterProvider);
  final repo = ref.watch(medicalRecordsRepositoryProvider);
  return repo.getMedicalExams(userId, examType: filter);
});

final vaccinationsProvider =
    FutureProvider<List<VaccinationRecord>>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  final userId = user?.id ?? 'default-user';
  final repo = ref.watch(medicalRecordsRepositoryProvider);
  return repo.getVaccinations(userId);
});

final specialistsProvider =
    FutureProvider<List<SpecialistEntry>>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  final userId = user?.id ?? 'default-user';
  final repo = ref.watch(medicalRecordsRepositoryProvider);
  return repo.getSpecialists(userId);
});

final preventiveCalendarProvider =
    FutureProvider<List<PreventiveScreeningItem>>((ref) async {
  final user = ref.watch(activeUserProfileProvider);
  final userId = user?.id ?? 'default-user';
  final repo = ref.watch(medicalRecordsRepositoryProvider);
  return repo.getPreventiveCalendar(userId);
});

enum ExportPdfState { initial, generating, completed, error }

class DoctorReportExportNotifier extends StateNotifier<ExportPdfState> {
  final IMedicalRecordsRepository _repo;

  DoctorReportExportNotifier(this._repo) : super(ExportPdfState.initial);

  List<int>? lastGeneratedPdfBytes;

  Future<bool> generateReport({
    required int reportingWindowMonths,
    String? specialistNotes,
  }) async {
    state = ExportPdfState.generating;
    try {
      final bytes = await _repo.generateDoctorReportPdf(
        reportingWindowMonths: reportingWindowMonths,
        specialistNotes: specialistNotes,
      );
      lastGeneratedPdfBytes = bytes;
      state = ExportPdfState.completed;
      return true;
    } catch (_) {
      state = ExportPdfState.error;
      return false;
    }
  }

  void reset() {
    state = ExportPdfState.initial;
    lastGeneratedPdfBytes = null;
  }
}

final doctorReportExportProvider =
    StateNotifierProvider<DoctorReportExportNotifier, ExportPdfState>((ref) {
  final repo = ref.watch(medicalRecordsRepositoryProvider);
  return DoctorReportExportNotifier(repo);
});
