import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/assistant/data/offline_first_assistant_repository.dart';
import 'package:mobile/features/assistant/domain/models/assistant_models.dart';
import 'package:mobile/features/assistant/presentation/cora_assistant_chat_page.dart';
import 'package:mobile/features/education/data/offline_first_education_repository.dart';
import 'package:mobile/features/education/domain/models/clinical_article.dart';

void main() {
  testWidgets(
    'CoraAssistantChatPage renders CitationChips and EmergencyDirectiveBanner',
    (tester) async {
      ClinicalCitation? tappedCitation;

      final groundedMsg = AssistantMessage(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: 'assistant',
        contentMarkdown:
            'Durante la fase lútea tardía desciende la progesterona [1].',
        citations: const [
          ClinicalCitation(
            articleId: '10000000-0000-4000-8000-000000000003',
            articleSlug: 'criterios-figo-sangrado-uterino-anormal-fase-lutea',
            articleTitle: 'Fisiología del Ciclo Menstrual Adulto y FIGO',
            sectionHeading: 'Fase Lútea Tardía',
            scientificSource: 'FIGO',
            sourceUrl: 'https://www.figo.org/',
          ),
        ],
        safetyTriageCategory: 'NONE',
        isEmergencyIntercepted: false,
        disclaimerLevel: 'STANDARD',
        suggestedFollowUps: const ['¿Cómo aliviar la cefalea premenstrual?'],
        createdAt: DateTime(2026, 11, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CoraAssistantChatPage(
            initialMessages: [groundedMsg],
            onCitationSelected: (cit) {
              tappedCitation = cit;
            },
            onSendMessage: (query) async {
              return AssistantMessage(
                id: 'msg-2',
                conversationId: 'conv-1',
                role: 'assistant',
                contentMarkdown:
                    'Acude de inmediato al servicio de urgencias obstétricas.',
                citations: const [],
                safetyTriageCategory: 'OBSTETRIC_PREECLAMPSIA_EMERGENCY',
                isEmergencyIntercepted: true,
                disclaimerLevel: 'EMERGENCY_URGENT',
                suggestedFollowUps: const [],
                createdAt: DateTime(2026, 11, 10),
              );
            },
          ),
        ),
      );

      // 1. Verify grounded message and CitationChip
      expect(
        find.textContaining('Durante la fase lútea tardía'),
        findsOneWidget,
      );
      final chipFinder = find.byKey(
        const Key(
          'citation_chip_criterios-figo-sangrado-uterino-anormal-fase-lutea',
        ),
      );
      expect(chipFinder, findsOneWidget);
      await tester.tap(chipFinder);
      expect(tappedCitation?.scientificSource, 'FIGO');

      // 2. Send an emergency message and verify EmergencyDirectiveBanner
      await tester.enterText(
        find.byKey(const Key('assistant_query_input')),
        'Tengo dolor de cabeza fuerte y veo luces en la semana 32',
      );
      await tester.tap(find.byKey(const Key('assistant_send_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('emergency_directive_banner')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('emergency_call_911_button')),
        findsOneWidget,
      );
    },
  );

  test(
    'OfflineFirstEducationRepository and OfflineFirstAssistantRepository persist locally',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final eduRepo = OfflineFirstEducationRepository(database: db);
      final article = ClinicalArticle(
        id: 'art-1',
        slug: 'straw-10-perimenopausia',
        title: 'Transición Menopáusica STRAW+10',
        summary: 'Guía NAMS sobre síntomas vasomotores.',
        bodyMarkdown: '## Etapas STRAW+10\nVariabilidad mayor a 7 días.',
        targetLifeStages: const ['perimenopause'],
        clinicalTags: const ['straw10', 'nams'],
        scientificSource: 'NAMS',
        sourceUrl: 'https://www.menopause.org/',
        reviewedBy: 'Comité Clínico Cora',
        readingTimeMinutes: 6,
        publishedAt: DateTime(2026, 1, 15),
      );

      await eduRepo.cacheArticles([article]);
      final filtered = await eduRepo.listArticles(lifeStage: 'perimenopause');
      expect(filtered.length, 1);
      expect(filtered.first.slug, 'straw-10-perimenopausia');

      final assistantRepo = OfflineFirstAssistantRepository(database: db);
      final msg = AssistantMessage(
        id: 'm-10',
        conversationId: 'c-10',
        role: 'assistant',
        contentMarkdown: 'Respuesta fundamentada con evidencia.',
        citations: const [],
        safetyTriageCategory: 'NONE',
        isEmergencyIntercepted: false,
        disclaimerLevel: 'STANDARD',
        suggestedFollowUps: const ['Pregunta 1'],
        createdAt: DateTime(2026, 11, 10),
      );
      await assistantRepo.saveMessage(msg);
      final savedMsgs = await assistantRepo.listMessages('c-10');
      expect(savedMsgs.length, 1);
      expect(savedMsgs.first.contentMarkdown, msg.contentMarkdown);
    },
  );
}
