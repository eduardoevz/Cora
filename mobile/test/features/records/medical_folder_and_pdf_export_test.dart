import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/records/data/medical_records_repository_impl.dart';
import 'package:mobile/features/records/domain/models/medical_exam_record.dart';
import 'package:mobile/features/records/domain/models/preventive_screening_item.dart';
import 'package:mobile/features/records/domain/models/specialist_entry.dart';
import 'package:mobile/features/records/domain/models/vaccination_record.dart';
import 'package:mobile/features/records/presentation/pages/doctor_report_export_page.dart';
import 'package:mobile/features/records/presentation/pages/medical_folder_hub_page.dart';
import 'package:mobile/features/records/presentation/pages/vaccinations_and_specialists_page.dart';
import 'package:mobile/features/records/presentation/providers/medical_records_providers.dart';

class _FakeMedicalRecordsRepository implements IMedicalRecordsRepository {
  final List<MedicalExamRecord> exams = [];
  final List<VaccinationRecord> vaccinations = [];
  final List<SpecialistEntry> specialists = [];

  @override
  Future<void> saveMedicalExam(MedicalExamRecord exam) async {
    exams.insert(0, exam);
  }

  @override
  Future<List<MedicalExamRecord>> getMedicalExams(String userId,
      {ExamType? examType}) async {
    if (examType == null) return List.unmodifiable(exams);
    return exams.where((e) => e.examType == examType).toList();
  }

  @override
  Future<void> deleteMedicalExam(String examId, String userId) async {
    exams.removeWhere((e) => e.id == examId && e.userId == userId);
  }

  @override
  Future<void> saveVaccination(VaccinationRecord vaccination) async {
    vaccinations.insert(0, vaccination);
  }

  @override
  Future<List<VaccinationRecord>> getVaccinations(String userId) async {
    return List.unmodifiable(vaccinations);
  }

  @override
  Future<void> saveSpecialist(SpecialistEntry specialist) async {
    specialists.insert(0, specialist);
  }

  @override
  Future<List<SpecialistEntry>> getSpecialists(String userId) async {
    return List.unmodifiable(specialists);
  }

  @override
  Future<void> deleteSpecialist(String specialistId, String userId) async {
    specialists.removeWhere((s) => s.id == specialistId && s.userId == userId);
  }

  @override
  Future<List<PreventiveScreeningItem>> getPreventiveCalendar(
      String userId) async {
    return const [
      PreventiveScreeningItem(
        screeningCode: 'PAP_SMEAR',
        title: 'Citología Cervicovaginal (Papanicolau)',
        description: 'Detección temprana de cáncer cervicouterino.',
        recommendedAgeRange: '21–65 años',
        frequencyGuideline: 'Cada 1 a 3 años',
        urgency: ScreeningUrgency.dueNow,
      ),
      PreventiveScreeningItem(
        screeningCode: 'MAMMOGRAM',
        title: 'Mamografía Bilateral',
        description: 'Tamizaje mamario preventivo.',
        recommendedAgeRange: '40–74 años',
        frequencyGuideline: 'Cada 1 a 2 años',
        urgency: ScreeningUrgency.upcoming,
      ),
    ];
  }

  @override
  Future<List<int>> generateDoctorReportPdf({
    required int reportingWindowMonths,
    String? specialistNotes,
  }) async {
    return '%PDF-1.4\nDoctor-Ready Mock\n%%EOF'.codeUnits;
  }
}

void main() {
  final testUser = UserProfileEntity(
    id: 'user_records_test_1',
    firebaseUid: 'fb_rec_1',
    firstName: 'Valeria',
    lastName: 'Ríos',
    currentLifeStage: LifeStage.regularAdult,
    onboardingCompleted: true,
    onboardingContext: const OnboardingContextEntity(
      birthYear: 1998,
      primaryIntents: [PrimaryIntent.preventiveHealth],
      diagnosedConditions: [DiagnosedCondition.none],
      clinicalContextCompleted: true,
    ),
    enabledModules: const ['preventive_checkups'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('Medical Records Domain Models', () {
    test('MedicalExamRecord serialization and deserialization', () {
      final exam = MedicalExamRecord(
        id: 'exam_1',
        userId: 'user_1',
        examType: ExamType.papSmear,
        title: 'Citología Anual',
        performedAt: DateTime(2026, 5, 10),
        clinicOrLab: 'Laboratorio Central',
        notes: 'Normal sin alteraciones',
        attachment: const AttachmentMetadata(
          fileName: 'citologia.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 2048,
          storageKey: 'users/user_1/records/exam_1/citologia.pdf',
        ),
        createdAt: DateTime(2026, 5, 10),
        updatedAt: DateTime(2026, 5, 10),
      );

      final json = exam.toJson();
      expect(json['exam_type'], 'pap_smear');
      expect(json['title'], 'Citología Anual');

      final parsed = MedicalExamRecord.fromJson(json);
      expect(parsed.id, 'exam_1');
      expect(parsed.examType, ExamType.papSmear);
      expect(parsed.attachment?.fileName, 'citologia.pdf');
    });

    test('VaccinationRecord and SpecialistEntry serialization', () {
      final vax = VaccinationRecord(
        id: 'vax_1',
        userId: 'user_1',
        vaccineType: VaccineType.influenza,
        doseNumber: 1,
        administeredAt: DateTime(2026, 10, 1),
        lotNumber: 'INF-2026',
        createdAt: DateTime(2026, 10, 1),
      );

      final vaxJson = vax.toJson();
      expect(vaxJson['vaccine_type'], 'influenza');
      expect(VaccinationRecord.fromJson(vaxJson).vaccineType, VaccineType.influenza);

      final spec = SpecialistEntry(
        id: 'spec_1',
        userId: 'user_1',
        fullName: 'Dra. Gabriela Soto',
        specialty: SpecialtyType.gynecology,
        phoneNumber: '+525511223344',
        isFavorite: true,
        createdAt: DateTime(2026, 1, 1),
      );

      final specJson = spec.toJson();
      expect(specJson['specialty'], 'gynecology');
      expect(SpecialistEntry.fromJson(specJson).fullName, 'Dra. Gabriela Soto');
    });
  });

  group('MedicalFolderHubPage Widget Tests', () {
    testWidgets('renders calendar and registers exam flow', (tester) async {
      final fakeRepo = _FakeMedicalRecordsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testUser),
            medicalRecordsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: MedicalFolderHubPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Carpeta Clínica Digital'), findsOneWidget);
      expect(find.text('Calendario Preventivo Clínico'), findsOneWidget);
      expect(find.text('Citología Cervicovaginal (Papanicolau)'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.byKey(const Key('register_exam_fab')), findsOneWidget);

      // Open bottom sheet
      await tester.tap(find.byKey(const Key('register_exam_fab')));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Nuevo Estudio Médico'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('exam_title_field')), 'Ecografía Mamaria');
      await tester.tap(find.byKey(const Key('exam_attachment_toggle')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_exam_button')));
      await tester.pumpAndSettle();

      expect(fakeRepo.exams.length, 1);
      expect(fakeRepo.exams.first.title, 'Ecografía Mamaria');
      expect(fakeRepo.exams.first.attachment, isNotNull);
    });
  });

  group('DoctorReportExportPage Widget Tests', () {
    testWidgets('configures window and generates Doctor-Ready PDF', (tester) async {
      final fakeRepo = _FakeMedicalRecordsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testUser),
            medicalRecordsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: DoctorReportExportPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reporte Doctor-Ready PDF'), findsOneWidget);
      expect(find.byKey(const Key('doctor_report_window_selector')), findsOneWidget);

      // Select 12 months
      await tester.tap(find.text('12 Meses'));
      await tester.pumpAndSettle();

      // Enter notes
      await tester.enterText(
        find.byKey(const Key('doctor_report_notes_input')),
        'Control preventivo de rutina.',
      );
      await tester.pumpAndSettle();

      // Tap generate button
      await tester.tap(find.byKey(const Key('doctor_report_generate_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('doctor_report_completed_card')), findsOneWidget);
      expect(find.text('¡Reporte generado con éxito!'), findsOneWidget);
    });
  });

  group('VaccinationsAndSpecialistsPage Widget Tests', () {
    testWidgets('switches between tabs and shows empty state and actions',
        (tester) async {
      final fakeRepo = _FakeMedicalRecordsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testUser),
            medicalRecordsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: VaccinationsAndSpecialistsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cartilla de Vacunación'), findsOneWidget);
      expect(find.text('No hay vacunas registradas aún.'), findsOneWidget);

      // Switch to Specialists Tab
      await tester.tap(find.byKey(const Key('specialists_tab')));
      await tester.pumpAndSettle();

      expect(find.text('Directorio de especialistas vacío.'), findsOneWidget);
    });
  });
}
