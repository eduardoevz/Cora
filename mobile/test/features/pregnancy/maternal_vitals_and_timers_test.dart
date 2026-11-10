import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/pregnancy/data/pregnancy_repository_impl.dart';
import 'package:mobile/features/pregnancy/domain/entities/pregnancy_entities.dart';
import 'package:mobile/features/pregnancy/presentation/pages/birth_plan_and_appointments_page.dart';
import 'package:mobile/features/pregnancy/presentation/pages/contraction_and_kick_timers_page.dart';
import 'package:mobile/features/pregnancy/presentation/pages/maternal_vitals_page.dart';
import 'package:mobile/features/pregnancy/presentation/pages/pregnancy_weekly_hub_page.dart';
import 'package:mobile/features/pregnancy/presentation/providers/pregnancy_providers.dart';

class _FakePregnancyRepository implements IPregnancyRepository {
  PregnancyEpisodeEntity? episode;
  final List<MaternalVitalsEntity> vitals = [];
  final List<ContractionSessionEntity> contractions = [];
  final List<KickSessionEntity> kicks = [];
  BirthPlanEntity? birthPlan;
  final List<PrenatalAppointmentEntity> appointments = [];

  _FakePregnancyRepository(this.episode);

  @override
  Future<PregnancyEpisodeEntity?> getActiveEpisode(String userId) async =>
      episode;

  @override
  Future<void> saveEpisode(PregnancyEpisodeEntity episode) async {
    this.episode = episode;
  }

  @override
  Future<void> saveVitals(MaternalVitalsEntity vitals) async {
    this.vitals.add(vitals);
  }

  @override
  Future<List<MaternalVitalsEntity>> getRecentVitals(String episodeId,
          {int limit = 20}) async =>
      vitals;

  @override
  Future<void> saveContractionSession(ContractionSessionEntity session) async {
    contractions.add(session);
  }

  @override
  Future<List<ContractionSessionEntity>> getContractionSessions(
          String episodeId) async =>
      contractions;

  @override
  Future<void> saveKickSession(KickSessionEntity session) async {
    kicks.add(session);
  }

  @override
  Future<List<KickSessionEntity>> getKickSessions(String episodeId) async =>
      kicks;

  @override
  Future<BirthPlanEntity?> getBirthPlan(String episodeId) async => birthPlan;

  @override
  Future<void> saveBirthPlan(
      String episodeId, String userId, BirthPlanEntity plan) async {
    birthPlan = plan;
  }

  @override
  Future<void> saveAppointment(
      PrenatalAppointmentEntity appointment, String userId) async {
    appointments.add(appointment);
  }

  @override
  Future<List<PrenatalAppointmentEntity>> getAppointments(
          String episodeId) async =>
      appointments;

  @override
  Future<void> toggleAppointmentCompletion(
      String appointmentId, bool isCompleted) async {
    final index = appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      final old = appointments[index];
      appointments[index] = PrenatalAppointmentEntity(
        id: old.id,
        pregnancyEpisodeId: old.pregnancyEpisodeId,
        scheduledAt: old.scheduledAt,
        doctorOrClinic: old.doctorOrClinic,
        gestationalWeek: old.gestationalWeek,
        topicsToDiscuss: old.topicsToDiscuss,
        notes: old.notes,
        isCompleted: isCompleted,
      );
    }
  }
}

void main() {
  group('MaternalOfflineEvaluator Clinical Unit Tests', () {
    test('Severe preeclampsia systolic >= 160 triggers urgent_emergency', () {
      final alerts = MaternalOfflineEvaluator.evaluateOffline(
        systolic: 165,
        diastolic: 95,
      );
      expect(alerts.length, 1);
      expect(alerts.first.severity, 'urgent_emergency');
      expect(alerts.first.category, 'preeclampsia_risk');
    });

    test('Severe preeclampsia diastolic >= 110 triggers urgent_emergency', () {
      final alerts = MaternalOfflineEvaluator.evaluateOffline(
        systolic: 135,
        diastolic: 112,
      );
      expect(alerts.length, 1);
      expect(alerts.first.severity, 'urgent_emergency');
    });

    test(
        'Stage 1 gestational hypertension without severe symptoms triggers priority_consult',
        () {
      final alerts = MaternalOfflineEvaluator.evaluateOffline(
        systolic: 145,
        diastolic: 92,
        symptoms: ['mild_fatigue'],
      );
      expect(alerts.length, 1);
      expect(alerts.first.severity, 'priority_consult');
    });

    test('Gestational hypertension WITH scotomas triggers urgent_emergency',
        () {
      final alerts = MaternalOfflineEvaluator.evaluateOffline(
        systolic: 145,
        diastolic: 92,
        symptoms: ['scotomas_visual_blur'],
      );
      expect(alerts.length, 1);
      expect(alerts.first.severity, 'urgent_emergency');
    });

    test('Gestational diabetes fasting >= 95 triggers priority_consult', () {
      final alerts = MaternalOfflineEvaluator.evaluateOffline(
        glucose: 98.0,
        timing: 'fasting',
      );
      expect(alerts.length, 1);
      expect(alerts.first.severity, 'priority_consult');
      expect(alerts.first.category, 'gestational_diabetes_risk');
    });

    test('Gestational diabetes postprandial 1h >= 140 triggers priority_consult',
        () {
      final alerts = MaternalOfflineEvaluator.evaluateOffline(
        glucose: 145.0,
        timing: 'postprandial_1h',
      );
      expect(alerts.length, 1);
      expect(alerts.first.severity, 'priority_consult');
    });

    test('Completely normal vitals returns 0 alerts', () {
      final alerts = MaternalOfflineEvaluator.evaluateOffline(
        systolic: 115,
        diastolic: 75,
        glucose: 82.0,
        timing: 'fasting',
      );
      expect(alerts, isEmpty);
    });

    test('Contractions preterm risk (< 37 weeks, 4 contractions in 20 min)', () {
      final now = DateTime.now();
      final events = [
        {'started_at': now.toIso8601String(), 'duration_seconds': 45},
        {
          'started_at': now.add(const Duration(minutes: 4)).toIso8601String(),
          'duration_seconds': 45
        },
        {
          'started_at': now.add(const Duration(minutes: 8)).toIso8601String(),
          'duration_seconds': 45
        },
        {
          'started_at': now.add(const Duration(minutes: 12)).toIso8601String(),
          'duration_seconds': 45
        },
      ];

      final result = MaternalOfflineEvaluator.evaluateContractions(
        events: events,
        gestationalWeeks: 32,
      );

      expect(result.pattern, 'preterm_labor_risk');
      expect(result.alert, isNotNull);
      expect(result.alert!.severity, 'urgent_emergency');
    });

    test('Contractions Rule 5-1-1 active labor at term (>= 37 weeks)', () {
      final now = DateTime.now();
      final events = List.generate(8, (i) {
        return {
          'started_at': now.add(Duration(minutes: i * 4)).toIso8601String(),
          'duration_seconds': 65,
        };
      });

      final result = MaternalOfflineEvaluator.evaluateContractions(
        events: events,
        gestationalWeeks: 39,
      );

      expect(result.pattern, 'active_labor_511');
      expect(result.alert, isNotNull);
      expect(result.alert!.severity, 'priority_consult');
    });

    test('Cardiff 10 kicks reached within 45 min is reassuring', () {
      final result = MaternalOfflineEvaluator.evaluateKicks(
        kicksCount: 10,
        durationMinutes: 45,
      );
      expect(result.isReassuring, isTrue);
      expect(result.targetReached, isTrue);
      expect(result.alert, isNull);
    });

    test('Cardiff < 10 kicks in 125 min triggers urgent_emergency', () {
      final result = MaternalOfflineEvaluator.evaluateKicks(
        kicksCount: 4,
        durationMinutes: 125,
      );
      expect(result.isReassuring, isFalse);
      expect(result.targetReached, isFalse);
      expect(result.alert, isNotNull);
      expect(result.alert!.severity, 'urgent_emergency');
    });
  });

  group('Pregnancy Mobile Widget Tests', () {
    late PregnancyEpisodeEntity testEpisode;
    late UserProfileEntity testUser;
    late _FakePregnancyRepository fakeRepo;

    setUp(() {
      final now = DateTime.now();
      testEpisode = PregnancyEpisodeEntity(
        id: 'episode_123',
        userId: 'usr_abc',
        clinicalEdd: now.add(const Duration(days: 100)),
        lastMenstrualPeriod: now.subtract(const Duration(days: 180)),
        startedAt: now.subtract(const Duration(days: 180)),
        isActive: true,
      );

      testUser = UserProfileEntity(
        id: 'usr_abc',
        firebaseUid: 'fb_123',
        firstName: 'Elena',
        lastName: 'Gómez',
        currentLifeStage: LifeStage.pregnancy,
        onboardingCompleted: true,
        onboardingContext: const OnboardingContextEntity(
          birthYear: 1995,
          primaryIntents: [PrimaryIntent.pregnancyTracking],
        ),
        enabledModules: const ['pregnancy_tracking'],
        createdAt: now,
        updatedAt: now,
      );

      fakeRepo = _FakePregnancyRepository(testEpisode);
    });

    testWidgets(
        'PregnancyWeeklyHubPage displays gestational progress and options',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testUser),
            pregnancyRepositoryProvider.overrideWithValue(fakeRepo),
            activePregnancyEpisodeProvider
                .overrideWith((ref) => Future.value(testEpisode)),
          ],
          child: const MaterialApp(
            home: PregnancyWeeklyHubPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mi Embarazo Semana a Semana'), findsOneWidget);
      expect(find.textContaining('Semana'), findsWidgets);
      expect(find.text('Signos Vitales y Alertas ACOG'), findsOneWidget);
      expect(find.text('Cronómetro de Contracciones y Patadas'), findsOneWidget);
      await tester.scrollUntilVisible(
          find.text('Plan de Parto y Citas Prenatales'), 100);
      expect(find.text('Plan de Parto y Citas Prenatales'), findsOneWidget);
    });

    testWidgets(
        'MaternalVitalsPage renders inputs and shows alert on high blood pressure',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testUser),
            pregnancyRepositoryProvider.overrideWithValue(fakeRepo),
            activePregnancyEpisodeProvider
                .overrideWith((ref) => Future.value(testEpisode)),
          ],
          child: MaterialApp(
            home: MaternalVitalsPage(episode: testEpisode),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Monitor Materno & Alertas ACOG'), findsOneWidget);
      expect(find.text('Registro de Signos Vitales'), findsOneWidget);
      expect(find.text('Sistólica (mmHg)'), findsOneWidget);

      // Enter 165/112 mmHg
      await tester.enterText(find.byType(TextField).at(0), '165');
      await tester.enterText(find.byType(TextField).at(1), '112');
      await tester.pumpAndSettle();

      // Urgent emergency alert should render in real time
      expect(find.textContaining('Crisis Hipertensiva'), findsOneWidget);
    });

    testWidgets('ContractionAndKickTimersPage renders both tabs',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testUser),
            pregnancyRepositoryProvider.overrideWithValue(fakeRepo),
            activePregnancyEpisodeProvider
                .overrideWith((ref) => Future.value(testEpisode)),
          ],
          child: MaterialApp(
            home: ContractionAndKickTimersPage(
              episode: testEpisode,
              gestationalWeeks: 38,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Contracciones (5-1-1)'), findsOneWidget);
      expect(find.text('Contador Cardiff (10)'), findsOneWidget);
      expect(find.text('Iniciar Contracción'), findsOneWidget);

      // Tap on Cardiff tab
      await tester.tap(find.text('Contador Cardiff (10)'));
      await tester.pumpAndSettle();

      expect(find.text('+1 Patada Fetal'), findsOneWidget);
      expect(find.text('0 / 10'), findsOneWidget);

      // Tap +1 Patada Fetal
      await tester.tap(find.text('+1 Patada Fetal'));
      await tester.pumpAndSettle();

      expect(find.text('1 / 10'), findsOneWidget);
    });

    testWidgets(
        'BirthPlanAndAppointmentsPage renders checkboxes and allows save',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserProfileProvider.overrideWith((ref) => testUser),
            pregnancyRepositoryProvider.overrideWithValue(fakeRepo),
            activePregnancyEpisodeProvider
                .overrideWith((ref) => Future.value(testEpisode)),
          ],
          child: MaterialApp(
            home: BirthPlanAndAppointmentsPage(episode: testEpisode),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Plan de Parto'), findsOneWidget);
      expect(find.text('Citas Prenatales'), findsOneWidget);
      expect(find.text('Tus Preferencias para el Nacimiento'), findsOneWidget);
      expect(find.text('Presencia continua de mi pareja / familiar'),
          findsOneWidget);

      // Tap on partner presence checkbox
      await tester.tap(find.text('Presencia continua de mi pareja / familiar'));
      await tester.pumpAndSettle();

      expect(find.text('Guardar Mi Plan de Parto'), findsOneWidget);

      // Tap Save
      await tester.tap(find.text('Guardar Mi Plan de Parto'));
      await tester.pumpAndSettle();

      expect(fakeRepo.birthPlan, isNotNull);
      expect(fakeRepo.birthPlan!.companionPreferences,
          contains('partner_presence'));
    });
  });
}
