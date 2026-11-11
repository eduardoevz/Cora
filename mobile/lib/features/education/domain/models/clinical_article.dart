class ClinicalArticle {
  const ClinicalArticle({
    required this.id,
    required this.slug,
    required this.title,
    required this.summary,
    required this.bodyMarkdown,
    required this.targetLifeStages,
    required this.clinicalTags,
    required this.scientificSource,
    required this.sourceUrl,
    required this.reviewedBy,
    required this.readingTimeMinutes,
    required this.publishedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String summary;
  final String bodyMarkdown;
  final List<String> targetLifeStages;
  final List<String> clinicalTags;
  final String scientificSource;
  final String sourceUrl;
  final String reviewedBy;
  final int readingTimeMinutes;
  final DateTime publishedAt;
}
