import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/cora_api_client.dart';
import 'package:mobile/features/assistant/data/offline_first_assistant_repository.dart';
import 'package:mobile/features/assistant/domain/models/assistant_models.dart';
import 'package:mobile/features/education/presentation/providers/education_providers.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:uuid/uuid.dart';

const String defaultAssistantConversationId = 'cora-local-thread';

final assistantRepositoryProvider =
    Provider<OfflineFirstAssistantRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return OfflineFirstAssistantRepository(database: db);
});

final assistantMessagesProvider =
    FutureProvider<List<AssistantMessage>>((ref) async {
  final repo = ref.watch(assistantRepositoryProvider);
  return repo.listMessages(defaultAssistantConversationId);
});

final assistantServiceProvider = Provider<CoraAssistantService>((ref) {
  return CoraAssistantService(ref);
});

class CoraAssistantService {
  CoraAssistantService(this._ref);

  final Ref _ref;
  final _uuid = const Uuid();
  String? _remoteConversationId;

  Future<AssistantMessage> sendMessage(String query) async {
    final repo = _ref.read(assistantRepositoryProvider);
    final profile = _ref.read(activeUserProfileProvider);

    final userMsg = AssistantMessage(
      id: _uuid.v4(),
      conversationId: defaultAssistantConversationId,
      role: 'user',
      contentMarkdown: query,
      citations: const [],
      safetyTriageCategory: 'NONE',
      isEmergencyIntercepted: false,
      disclaimerLevel: 'STANDARD',
      suggestedFollowUps: const [],
      createdAt: DateTime.now(),
    );
    await repo.saveMessage(userMsg);

    // Stage 1: Local Deterministic Safety Triage (works online & offline in < 2ms)
    final localEmergency =
        _checkLocalRedFlags(query, profile?.currentLifeStage);
    if (localEmergency != null) {
      await repo.saveMessage(localEmergency);
      _ref.invalidate(assistantMessagesProvider);
      return localEmergency;
    }

    // Stage 2: Try live backend RAG pipeline (/assistant)
    final api = _ref.read(coraApiClientProvider);
    try {
      if (_remoteConversationId == null) {
        try {
          final convRes = await api.dio.post(
            '/assistant/conversations',
            data: {'title': 'Consulta con Cora'},
          );
          if (convRes.statusCode == 201 &&
              convRes.data is Map<String, dynamic>) {
            _remoteConversationId = convRes.data['id']?.toString();
          }
        } catch (_) {
          // Ensure profile exists remotely if not yet synced
          if (profile != null) {
            await api.dio.put(
              '/identity/onboarding',
              data: {
                'first_name': profile.firstName,
                'last_name': profile.lastName,
                'current_life_stage': profile.currentLifeStage.value,
                'birth_year': profile.onboardingContext.birthYear,
                'primary_intents': profile.onboardingContext.primaryIntents
                    .map((i) => i.value)
                    .toList(),
                'hormonal_method':
                    profile.onboardingContext.hormonalMethod?.value,
                'diagnosed_conditions': profile
                    .onboardingContext.diagnosedConditions
                    .map((c) => c.value)
                    .toList(),
                'clinical_context_completed':
                    profile.onboardingContext.clinicalContextCompleted,
              },
            );
            final convRes = await api.dio.post(
              '/assistant/conversations',
              data: {'title': 'Consulta con Cora'},
            );
            if (convRes.statusCode == 201 &&
                convRes.data is Map<String, dynamic>) {
              _remoteConversationId = convRes.data['id']?.toString();
            }
          }
        }
      }

      if (_remoteConversationId != null) {
        final msgRes = await api.dio.post(
          '/assistant/conversations/$_remoteConversationId/messages',
          data: {'query': query},
        );
        if (msgRes.statusCode == 201 && msgRes.data is Map<String, dynamic>) {
          final data = msgRes.data as Map<String, dynamic>;
          final citations = (data['citations'] as List<dynamic>? ?? const [])
              .map((e) => ClinicalCitation.fromJson(e as Map<String, dynamic>))
              .toList();
          final reply = AssistantMessage(
            id: data['id']?.toString() ?? _uuid.v4(),
            conversationId: defaultAssistantConversationId,
            role: 'assistant',
            contentMarkdown: data['content_markdown']?.toString() ?? '',
            citations: citations,
            safetyTriageCategory:
                data['safety_triage_category']?.toString() ?? 'NONE',
            isEmergencyIntercepted:
                data['is_emergency_intercepted'] as bool? ?? false,
            disclaimerLevel: data['disclaimer_level']?.toString() ?? 'STANDARD',
            suggestedFollowUps:
                (data['suggested_follow_ups'] as List<dynamic>? ?? const [])
                    .map((e) => e.toString())
                    .toList(),
            createdAt: DateTime.now(),
          );
          await repo.saveMessage(reply);
          _ref.invalidate(assistantMessagesProvider);
          return reply;
        }
      }
    } catch (_) {
      // Fall back to grounded local educational synthesis below
    }

    // Stage 3: Offline Grounded Fallback using cached clinical library
    final articles = await _ref.read(educationArticlesProvider.future);
    final qLower = query.toLowerCase();
    final matched = articles
        .where((a) {
          return a.title.toLowerCase().contains(qLower) ||
              a.summary.toLowerCase().contains(qLower) ||
              a.clinicalTags
                  .any((t) => qLower.contains(t.replaceAll('_', ' '))) ||
              (profile != null &&
                  a.targetLifeStages.contains(profile.currentLifeStage.value));
        })
        .take(2)
        .toList();

    final citations = matched
        .map(
          (a) => ClinicalCitation(
            articleId: a.id,
            articleSlug: a.slug,
            articleTitle: a.title,
            sectionHeading: 'Resumen Clínico',
            scientificSource: a.scientificSource,
            sourceUrl: a.sourceUrl,
          ),
        )
        .toList();

    final stageLabel = profile?.currentLifeStage.label ?? 'Salud Integral';
    final evidenceNote = matched.isNotEmpty
        ? matched
            .map(
                (a) => '• **${a.title}** (${a.scientificSource}): ${a.summary}')
            .join('\n\n')
        : 'Puedes explorar las guías clínicas en la Biblioteca Clínica Cora para revisar criterios FIGO, ACOG, STRAW+10 y EPDS.';

    final offlineReply = AssistantMessage(
      id: _uuid.v4(),
      conversationId: defaultAssistantConversationId,
      role: 'assistant',
      contentMarkdown: '### Orientación Educativa Cora ($stageLabel)\n\n'
          '$evidenceNote\n\n'
          '*Nota: Esta orientación educativa se basa en guías clínicas guardadas localmente y no sustituye la valoración de tu profesional de salud.*',
      citations: citations,
      safetyTriageCategory: 'NONE',
      isEmergencyIntercepted: false,
      disclaimerLevel: 'STANDARD',
      suggestedFollowUps: const [
        '¿Qué señales indican que debo acudir a consulta médica?',
        '¿Cómo exporto mi reporte Doctor-Ready PDF?',
      ],
      createdAt: DateTime.now(),
    );
    await repo.saveMessage(offlineReply);
    _ref.invalidate(assistantMessagesProvider);
    return offlineReply;
  }

  AssistantMessage? _checkLocalRedFlags(String query, LifeStage? stage) {
    final q = query.toLowerCase();

    if (q.contains('hacerme daño') ||
        q.contains('suicid') ||
        q.contains('no quiero vivir') ||
        q.contains('quitarme la vida')) {
      return AssistantMessage(
        id: _uuid.v4(),
        conversationId: defaultAssistantConversationId,
        role: 'assistant',
        contentMarkdown: '### Contención y Apoyo Inmediato\n\n'
            'No estás sola. Por tu seguridad, comunícate de inmediato con los **servicios de urgencias (911)** '
            'o con la **Línea de la Vida / ayuda emocional local**, o acude acompañada al servicio de urgencias más cercano.',
        citations: const [],
        safetyTriageCategory: 'MENTAL_HEALTH_CRISIS',
        isEmergencyIntercepted: true,
        disclaimerLevel: 'EMERGENCY_URGENT',
        suggestedFollowUps: const [],
        createdAt: DateTime.now(),
      );
    }

    if (q.contains('toalla por hora') ||
        q.contains('hemorragia') ||
        q.contains('sangrado abundante')) {
      return AssistantMessage(
        id: _uuid.v4(),
        conversationId: defaultAssistantConversationId,
        role: 'assistant',
        contentMarkdown: '### Atención Médica Urgente Recomendada\n\n'
            'Un sangrado agudo que empapa una o más toallas por hora durante 2 horas seguidas requiere **evaluación médica de urgencias** de inmediato.',
        citations: const [],
        safetyTriageCategory: 'HEMORRHAGE_EMERGENCY',
        isEmergencyIntercepted: true,
        disclaimerLevel: 'EMERGENCY_URGENT',
        suggestedFollowUps: const [],
        createdAt: DateTime.now(),
      );
    }

    if (q.contains('preeclampsia') ||
        q.contains('160/110') ||
        q.contains('lucecitas') ||
        q.contains('visión borrosa') ||
        q.contains('vision borrosa') ||
        (stage == LifeStage.pregnancy && q.contains('no se mueve'))) {
      return AssistantMessage(
        id: _uuid.v4(),
        conversationId: defaultAssistantConversationId,
        role: 'assistant',
        contentMarkdown: '### Señal de Alarma Obstétrica (ACOG)\n\n'
            'Los síntomas descritos (cifras de presión severas, alteraciones visuales, cefalea intensa o disminución de movimientos fetales) requieren **atención obstétrica urgente hoy mismo**.',
        citations: const [],
        safetyTriageCategory: 'OBSTETRIC_PREECLAMPSIA_EMERGENCY',
        isEmergencyIntercepted: true,
        disclaimerLevel: 'EMERGENCY_URGENT',
        suggestedFollowUps: const [],
        createdAt: DateTime.now(),
      );
    }

    return null;
  }
}
