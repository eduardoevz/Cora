import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/auth/auth_providers.dart';
import 'package:mobile/core/network/cora_api_client.dart';
import 'package:mobile/core/security/security_providers.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/assistant/presentation/cora_assistant_chat_page.dart';
import 'package:mobile/features/assistant/presentation/providers/assistant_providers.dart';
import 'package:mobile/features/cycle/domain/entities/cycle_entities.dart';
import 'package:mobile/features/cycle/domain/services/cycle_calendar_engine.dart';
import 'package:mobile/features/cycle/presentation/pages/menstrual_calendar_page.dart';
import 'package:mobile/features/cycle/presentation/providers/cycle_providers.dart';
import 'package:mobile/features/cycle/presentation/providers/menstrual_calendar_providers.dart';
import 'package:mobile/features/cycle/presentation/widgets/calendar_day_log_sheet.dart';
import 'package:mobile/features/dashboard/presentation/widgets/cora_navigation_drawer.dart';
import 'package:mobile/features/dashboard/presentation/widgets/home_cycle_hero_card.dart';
import 'package:mobile/features/dashboard/presentation/widgets/home_phase_education_card.dart';
import 'package:mobile/features/dashboard/presentation/widgets/home_week_calendar_strip.dart';
import 'package:mobile/features/dashboard/presentation/widgets/life_stage_switcher_sheet.dart';
import 'package:mobile/features/dashboard/presentation/widgets/module_preferences_page.dart';
import 'package:mobile/features/education/presentation/clinical_library_page.dart';
import 'package:mobile/features/education/presentation/providers/education_providers.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/partner/presentation/pages/partner_companion_view_page.dart';
import 'package:mobile/features/partner/presentation/pages/partner_sharing_settings_page.dart';
import 'package:mobile/features/partner/presentation/providers/partner_providers.dart';
import 'package:mobile/features/privacy/presentation/pages/privacy_and_data_sovereignty_page.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DynamicHomeDashboardPage extends ConsumerWidget {
  const DynamicHomeDashboardPage({super.key});

  CalendarMonthProjectionEntity _fallbackProjection(
    UserProfileEntity profile,
    DateTime refToday,
  ) {
    const engine = CycleCalendarEngine();
    final ctx = profile.onboardingContext;
    return engine.projectMonth(
      year: refToday.year,
      month: refToday.month,
      cycles: const [],
      symptomLogs: const [],
      lifeStage: profile.currentLifeStage,
      hormonalMethod: ctx.hormonalMethod,
      diagnosedConditions: ctx.diagnosedConditions,
      cycleRegularity: ctx.cycleRegularity,
      typicalCycleLengthDays: ctx.typicalCycleLengthDays,
      typicalBleedingDurationDays: ctx.typicalBleedingDurationDays,
      referenceDate: refToday,
    );
  }

  CycleStatusEntity _fallbackStatus(
    UserProfileEntity profile,
    DateTime refToday,
  ) {
    const engine = CycleCalendarEngine();
    final ctx = profile.onboardingContext;
    return engine.computeStatus(
      cycles: const [],
      lifeStage: profile.currentLifeStage,
      hormonalMethod: ctx.hormonalMethod,
      diagnosedConditions: ctx.diagnosedConditions,
      cycleRegularity: ctx.cycleRegularity,
      typicalCycleLengthDays: ctx.typicalCycleLengthDays,
      typicalBleedingDurationDays: ctx.typicalBleedingDurationDays,
      referenceDate: refToday,
    );
  }

  void _openTodayLogSheet(
    BuildContext context,
    DateTime refToday,
    CycleSymptomEntity? existingLog,
  ) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CoraTheme.tokensOf(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CalendarDayLogSheet(
        selectedDate: refToday,
        initialSymptomLog: existingLog,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeUserProfileProvider);

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cora')),
        body: const Center(
          child: Text('Cargando perfil...'),
        ),
      );
    }

    final refToday = ref.watch(calendarReferenceTodayProvider);
    final monthProjectionAsync =
        ref.watch(activeCalendarMonthProjectionProvider);
    final overviewAsync = ref.watch(
      cycleOverviewProvider((userId: profile.id, referenceDate: refToday)),
    );
    final symptomLogsMap =
        ref.watch(calendarSymptomLogsByDateProvider).valueOrNull;
    final todayLog = symptomLogsMap?[refToday];

    final projection = monthProjectionAsync.valueOrNull ??
        _fallbackProjection(profile, refToday);
    final overview = overviewAsync.valueOrNull;
    final status = overview?.status ?? _fallbackStatus(profile, refToday);
    final alerts = overview?.alerts ?? const <FigoAlertEntity>[];

    Widget scaffold = Scaffold(
      drawer: CoraNavigationDrawer(
        profile: profile,
        onOpenAssistant: () => _openAssistant(context, ref),
        onOpenLibrary: () => _openLibrary(
          context,
          ref,
          profile.currentLifeStage.value,
        ),
        onOpenPartnerSharing: () => _openPartnerSharing(context, ref),
        onOpenPrivacy: () => _openPrivacyPage(context, ref, profile),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            key: const Key('open_navigation_drawer_button'),
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Abrir menú lateral',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text('Hola, ${profile.firstName}'),
        actions: [
          IconButton(
            key: const Key('open_privacy_settings_button'),
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Privacidad y Soberanía',
            onPressed: () => _openPrivacyPage(context, ref, profile),
          ),
          IconButton(
            key: const Key('open_module_preferences_button'),
            icon: const Icon(Icons.tune),
            tooltip: 'Configurar módulos a la carta',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ModulePreferencesPage(profile: profile),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStageHeaderCard(context, profile),
              const SizedBox(height: 16),
              HomeCycleHeroCard(
                profile: profile,
                projection: projection,
                referenceToday: refToday,
                onRegisterToday: () => _openTodayLogSheet(
                  context,
                  refToday,
                  todayLog,
                ),
              ),
              const SizedBox(height: 16),
              HomeWeekCalendarStrip(
                projection: projection,
                referenceToday: refToday,
                onDayTapped: (date) {
                  ref
                      .read(menstrualCalendarControllerProvider)
                      .selectDate(date);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MenstrualCalendarPage(),
                    ),
                  );
                },
                onOpenFullCalendar: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MenstrualCalendarPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              HomePhaseEducationCard(
                profile: profile,
                status: status,
                alerts: alerts,
                onOpenLibrary: () => _openLibrary(
                  context,
                  ref,
                  profile.currentLifeStage.value,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (profile.currentLifeStage == LifeStage.seniorVitality) {
      scaffold = Theme(
        data: CoraTheme.highLegibility(),
        child: scaffold,
      );
    }

    return scaffold;
  }

  Widget _buildStageHeaderCard(
    BuildContext context,
    UserProfileEntity profile,
  ) {
    final tokens = CoraTheme.tokensOf(context);
    return CoraSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 18,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ETAPA BIOLÓGICA ACTIVA',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: tokens.accentPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                profile.currentLifeStage.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          ActionChip(
            key: const Key('switch_stage_chip_button'),
            avatar: Icon(
              Icons.sync_alt_rounded,
              size: 16,
              color: tokens.accentPrimary,
            ),
            label: const Text('Cambiar'),
            onPressed: () {
              LifeStageSwitcherSheet.show(context, profile);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openAssistant(BuildContext context, WidgetRef ref) async {
    final initialMessages = await ref.read(assistantMessagesProvider.future);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoraAssistantChatPage(
          initialMessages: initialMessages,
          onSendMessage: (query) =>
              ref.read(assistantServiceProvider).sendMessage(query),
        ),
      ),
    );
  }

  Future<void> _openLibrary(
    BuildContext context,
    WidgetRef ref,
    String lifeStage,
  ) async {
    final articles = await ref.read(educationArticlesProvider.future);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClinicalLibraryPage(
          articles: articles,
          initialLifeStage: null,
        ),
      ),
    );
  }

  Future<void> _openPartnerSharing(BuildContext context, WidgetRef ref) async {
    final service = ref.read(partnerServiceProvider);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => PartnerSharingSettingsPage(
          onGenerateCode: service.generateInvitationCode,
          onRedeemCode: service.redeemCode,
          onPermissionsChanged: (fertility, pregnancy, mood) {
            service.updatePermissions(
              fertility: fertility,
              pregnancy: pregnancy,
              mood: mood,
            );
          },
          onRevokeLink: service.revokeActiveLink,
          onOpenCompanionView: () async {
            final projection = await service.fetchSharedViewOrFallback();
            if (!pageContext.mounted) return;
            await Navigator.of(pageContext).push(
              MaterialPageRoute(
                builder: (_) => PartnerCompanionViewPage(
                  projection: projection,
                  onRefresh: () {},
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openPrivacyPage(
    BuildContext context,
    WidgetRef ref,
    UserProfileEntity profile,
  ) async {
    final biometricService = ref.read(biometricLockServiceProvider);
    final iconService = ref.read(discreetAppIconServiceProvider);
    final api = ref.read(coraApiClientProvider);
    final db = ref.read(appDatabaseProvider);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (privacyCtx) => PrivacyAndDataSovereigntyPage(
          biometricService: biometricService,
          iconService: iconService,
          onExportData: () async {
            try {
              final res =
                  await api.dio.post<List<int>>('/identity/me/data-export');
              if (res.data != null && res.data!.isNotEmpty) {
                final dir = await getApplicationDocumentsDirectory();
                final outFile =
                    File(p.join(dir.path, 'cora_export_${profile.id}.zip'));
                await outFile.writeAsBytes(res.data!, flush: true);
                return;
              }
            } catch (_) {
              // Offline fallback: write JSON export locally
            }
            final dir = await getApplicationDocumentsDirectory();
            final outFile =
                File(p.join(dir.path, 'cora_export_${profile.id}.json'));
            await outFile.writeAsString(
              '{"profile_id":"${profile.id}","first_name":"${profile.firstName}","life_stage":"${profile.currentLifeStage.value}"}',
              flush: true,
            );
          },
          onSignOut: () async {
            await ref.read(coraAuthServiceProvider).signOut();
            api.clearAuthToken();
            ref.read(activeUserProfileProvider.notifier).state = null;
            if (privacyCtx.mounted) {
              Navigator.of(privacyCtx).popUntil((route) => route.isFirst);
            }
          },
          onPurgeAccount: (phrase) async {
            try {
              await api.dio.delete(
                '/identity/me',
                data: {'confirm_phrase': phrase},
                options: Options(
                  sendTimeout: const Duration(seconds: 4),
                  receiveTimeout: const Duration(seconds: 4),
                ),
              );
            } catch (_) {
              // Proceed with local irreversible purge even if offline
            }
            await db.purgeAllLocalData();
            await ref.read(coraAuthServiceProvider).deleteCurrentUser();
            await ref.read(coraAuthServiceProvider).signOut();
            api.clearAuthToken();
            ref.read(activeUserProfileProvider.notifier).state = null;
            if (privacyCtx.mounted) {
              Navigator.of(privacyCtx).popUntil((route) => route.isFirst);
            }
          },
        ),
      ),
    );
  }
}
