import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/assistant/domain/models/assistant_models.dart';

class OfflineFirstAssistantRepository {
  OfflineFirstAssistantRepository({required AppDatabase database})
      : _db = database;

  final AppDatabase _db;

  Future<void> saveMessage(AssistantMessage message) async {
    await _db.into(_db.assistantMessageEntries).insertOnConflictUpdate(
          AssistantMessageEntriesCompanion.insert(
            id: message.id,
            conversationId: message.conversationId,
            role: message.role,
            contentMarkdown: message.contentMarkdown,
            citationsJson: jsonEncode(
              message.citations.map((c) => c.toJson()).toList(),
            ),
            safetyTriageCategory: Value(message.safetyTriageCategory),
            isEmergencyIntercepted: Value(message.isEmergencyIntercepted),
            disclaimerLevel: Value(message.disclaimerLevel),
            suggestedFollowUpsJson: jsonEncode(message.suggestedFollowUps),
            createdAt: Value(message.createdAt),
          ),
        );
  }

  Future<List<AssistantMessage>> listMessages(String conversationId) async {
    final query = _db.select(_db.assistantMessageEntries)
      ..where((t) => t.conversationId.equals(conversationId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    final rows = await query.get();
    return rows.map(_mapMessageRow).toList();
  }

  AssistantMessage _mapMessageRow(AssistantMessageEntry row) {
    final rawCitations = jsonDecode(row.citationsJson) as List<dynamic>;
    final citations = rawCitations
        .map((e) => ClinicalCitation.fromJson(e as Map<String, dynamic>))
        .toList();
    final followUps = (jsonDecode(row.suggestedFollowUpsJson) as List<dynamic>)
        .map((e) => e.toString())
        .toList();
    return AssistantMessage(
      id: row.id,
      conversationId: row.conversationId,
      role: row.role,
      contentMarkdown: row.contentMarkdown,
      citations: citations,
      safetyTriageCategory: row.safetyTriageCategory,
      isEmergencyIntercepted: row.isEmergencyIntercepted,
      disclaimerLevel: row.disclaimerLevel,
      suggestedFollowUps: followUps,
      createdAt: row.createdAt,
    );
  }
}
