import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart' hide SpecialistEntry;
import 'package:mobile/core/security/biometric_lock_service.dart';
import 'package:mobile/core/security/discreet_app_icon_service.dart';
import 'package:mobile/core/sync/sync_coordinator.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/education/domain/models/clinical_article.dart';
import 'package:mobile/features/education/presentation/clinical_library_page.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/partner/presentation/pages/partner_sharing_settings_page.dart';
import 'package:mobile/features/privacy/presentation/pages/privacy_and_data_sovereignty_page.dart';
import 'package:mobile/features/records/data/medical_records_repository_impl.dart';
import 'package:mobile/features/records/domain/models/medical_exam_record.dart';
import 'package:mobile/features/records/domain/models/preventive_screening_item.dart';
import 'package:mobile/features/records/domain/models/specialist_entry.dart';
import 'package:mobile/features/records/domain/models/vaccination_record.dart';
import 'package:mobile/features/records/presentation/pages/doctor_report_export_page.dart';
import 'package:mobile/features/records/presentation/providers/medical_records_providers.dart';
import 'package:mobile/features/wellness/data/wellness_repository_impl.dart';
import 'package:mobile/features/wellness/presentation/pages/wellness_tracker_page.dart';
import 'package:mobile/features/wellness/presentation/providers/wellness_providers.dart';

class _StubMedicalRecordsRepository implements IMedicalRecordsRepository {
  @override
  Future<void> deleteMedicalExam(String examId, String userId) async {}

  @override
  Future<void> deleteSpecialist(String specialistId, String userId) async {}

  @override
  Future<List<int>> generateDoctorReportPdf({
    required int reportingWindowMonths,
    String? specialistNotes,
  }) async =>
      const [];

  @override
  Future<List<MedicalExamRecord>> getMedicalExams(
    String userId, {
    ExamType? examType,
  }) async =>
      const [];

  @override
  Future<List<PreventiveScreeningItem>> getPreventiveCalendar(
    String userId,
  ) async =>
      const [];

  @override
  Future<List<SpecialistEntry>> getSpecialists(String userId) async => const [];

  @override
  Future<List<VaccinationRecord>> getVaccinations(String userId) async =>
      const [];

  @override
  Future<void> saveMedicalExam(MedicalExamRecord exam) async {}

  @override
  Future<void> saveSpecialist(SpecialistEntry specialist) async {}

  @override
  Future<void> saveVaccination(VaccinationRecord vaccination) async {}
}

void main() {
  group('Cora v2.0 30-Screen Design System Consistency Audit', () {
    test('all 30 feature *_page.dart screens use Cora v2 tokens and 0 emojis',
        () {
      final featuresDir = Directory('lib/features');
      expect(featuresDir.existsSync(), isTrue);

      final pageFiles = featuresDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('_page.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      expect(
        pageFiles.length,
        30,
        reason: 'Expected exactly 30 *_page.dart screens under lib/features/',
      );

      final legacyColorsRegex = RegExp(
        r'Colors\.(pink|purple|indigo|teal|blue|orange|amber|deepPurple|red|green|brown|grey)\b',
      );
      final emojiRegex = RegExp(
        r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
        unicode: true,
      );

      for (final file in pageFiles) {
        final content = file.readAsStringSync();
        final relativePath = file.path.replaceAll('\\', '/');

        expect(
          content.contains('cora_theme.dart') ||
              content.contains('cora_design_components.dart'),
          isTrue,
          reason: '$relativePath must import Cora v2 theme/design components',
        );

        expect(
          content.contains('CoraTheme.tokensOf(') ||
              content.contains('CoraTheme.highLegibility('),
          isTrue,
          reason: '$relativePath must use CoraTheme tokens or highLegibility()',
        );

        expect(
          legacyColorsRegex.hasMatch(content),
          isFalse,
          reason: '$relativePath contains forbidden legacy Material Colors.*',
        );

        expect(
          emojiRegex.hasMatch(content),
          isFalse,
          reason: '$relativePath contains forbidden emoji characters',
        );
      }
    });
  });

  group('Cora v2.0 Representative Screens WCAG 2.0x TextScaler Audit', () {
    final testProfile = UserProfileEntity(
      id: 'audit-user-1',
      firebaseUid: 'fb-audit-1',
      firstName: 'Sofía',
      lastName: 'Botánica',
      currentLifeStage: LifeStage.regularAdult,
      onboardingCompleted: true,
      onboardingContext: const OnboardingContextEntity(
        birthYear: 1994,
        primaryIntents: [PrimaryIntent.cycleAndSymptoms],
        clinicalContextCompleted: true,
      ),
      enabledModules: const ['cycle_tracker', 'wellness'],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    testWidgets(
        'WellnessTrackerPage renders at TextScaler 2.0x without overflow',
        (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final syncCoordinator = SyncCoordinator(db);
      final wellnessRepo = WellnessRepositoryImpl(db, syncCoordinator);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            syncCoordinatorProvider.overrideWithValue(syncCoordinator),
            wellnessRepositoryProvider.overrideWithValue(wellnessRepo),
            activeUserProfileProvider.overrideWith((ref) => testProfile),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2.0),
            ),
            child: MaterialApp(
              theme: CoraTheme.standard(),
              home: const WellnessTrackerPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bienestar y Hábitos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'DoctorReportExportPage renders at TextScaler 2.0x without overflow',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testProfile),
            medicalRecordsRepositoryProvider
                .overrideWithValue(_StubMedicalRecordsRepository()),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2.0),
            ),
            child: MaterialApp(
              theme: CoraTheme.standard(),
              home: const DoctorReportExportPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reporte Doctor-Ready PDF'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'ClinicalLibraryPage renders at TextScaler 2.0x without overflow',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(2.0),
          ),
          child: MaterialApp(
            theme: CoraTheme.standard(),
            home: ClinicalLibraryPage(
              articles: [
                ClinicalArticle(
                  id: 'art-1',
                  slug: 'guia-ciclo-figo',
                  title: 'Guía Clínica del Ciclo Menstrual',
                  summary: 'Criterios FIGO para variabilidad y flujo.',
                  bodyMarkdown: 'Contenido educativo basado en evidencia.',
                  clinicalTags: const ['ciclo', 'figo'],
                  scientificSource: 'FIGO',
                  sourceUrl: 'https://www.figo.org',
                  reviewedBy: 'Comité Clínico Cora',
                  readingTimeMinutes: 4,
                  targetLifeStages: const ['regular_adult'],
                  publishedAt: DateTime(2026, 1, 1),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Biblioteca Clínica Cora'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'PartnerSharingSettingsPage & PrivacyAndDataSovereigntyPage render at TextScaler 2.0x without overflow',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(2.0),
          ),
          child: MaterialApp(
            theme: CoraTheme.standard(),
            home: const PartnerSharingSettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Modo Acompañante / Pareja'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(2.0),
          ),
          child: MaterialApp(
            theme: CoraTheme.standard(),
            home: PrivacyAndDataSovereigntyPage(
              biometricService: BiometricLockService(),
              iconService: DiscreetAppIconService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Privacidad y Soberanía'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
