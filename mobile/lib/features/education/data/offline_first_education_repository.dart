import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/education/domain/models/clinical_article.dart';

class OfflineFirstEducationRepository {
  OfflineFirstEducationRepository({required AppDatabase database})
      : _db = database;

  final AppDatabase _db;

  Future<void> cacheArticles(List<ClinicalArticle> articles) async {
    await _db.batch((batch) {
      for (final a in articles) {
        batch.insert(
          _db.clinicalArticleEntries,
          ClinicalArticleEntriesCompanion.insert(
            id: a.id,
            slug: a.slug,
            title: a.title,
            summary: a.summary,
            bodyMarkdown: a.bodyMarkdown,
            targetLifeStagesJson: jsonEncode(a.targetLifeStages),
            clinicalTagsJson: jsonEncode(a.clinicalTags),
            scientificSource: a.scientificSource,
            sourceUrl: a.sourceUrl,
            reviewedBy: a.reviewedBy,
            readingTimeMinutes: Value(a.readingTimeMinutes),
            publishedAt: Value(a.publishedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<ClinicalArticle>> listArticles({
    String? lifeStage,
    String? tag,
    String? searchQuery,
  }) async {
    final rows = await _db.select(_db.clinicalArticleEntries).get();
    var items = rows.map(_mapRow).toList();

    if (lifeStage != null && lifeStage.isNotEmpty) {
      final norm = lifeStage.trim().toLowerCase();
      items = items.where((a) => a.targetLifeStages.contains(norm)).toList();
    }
    if (tag != null && tag.isNotEmpty) {
      final normTag = tag.trim().toLowerCase();
      items = items.where((a) => a.clinicalTags.contains(normTag)).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      items = items
          .where((a) =>
              a.title.toLowerCase().contains(q) ||
              a.summary.toLowerCase().contains(q) ||
              a.bodyMarkdown.toLowerCase().contains(q))
          .toList();
    }
    return items;
  }

  Future<ClinicalArticle?> getArticleBySlug(String slug) async {
    final query = _db.select(_db.clinicalArticleEntries)
      ..where((t) => t.slug.equals(slug));
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  ClinicalArticle _mapRow(ClinicalArticleEntry row) {
    final stages = (jsonDecode(row.targetLifeStagesJson) as List<dynamic>)
        .map((e) => e.toString())
        .toList();
    final tags = (jsonDecode(row.clinicalTagsJson) as List<dynamic>)
        .map((e) => e.toString())
        .toList();
    return ClinicalArticle(
      id: row.id,
      slug: row.slug,
      title: row.title,
      summary: row.summary,
      bodyMarkdown: row.bodyMarkdown,
      targetLifeStages: stages,
      clinicalTags: tags,
      scientificSource: row.scientificSource,
      sourceUrl: row.sourceUrl,
      reviewedBy: row.reviewedBy,
      readingTimeMinutes: row.readingTimeMinutes,
      publishedAt: row.publishedAt,
    );
  }
}
