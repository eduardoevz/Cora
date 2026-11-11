class ClinicalCitation {
  const ClinicalCitation({
    required this.articleId,
    required this.articleSlug,
    required this.articleTitle,
    required this.sectionHeading,
    required this.scientificSource,
    required this.sourceUrl,
  });

  final String articleId;
  final String articleSlug;
  final String articleTitle;
  final String sectionHeading;
  final String scientificSource;
  final String sourceUrl;

  Map<String, dynamic> toJson() => {
        'article_id': articleId,
        'article_slug': articleSlug,
        'article_title': articleTitle,
        'section_heading': sectionHeading,
        'scientific_source': scientificSource,
        'source_url': sourceUrl,
      };

  factory ClinicalCitation.fromJson(Map<String, dynamic> json) {
    return ClinicalCitation(
      articleId: json['article_id']?.toString() ?? '',
      articleSlug: json['article_slug']?.toString() ?? '',
      articleTitle: json['article_title']?.toString() ?? '',
      sectionHeading: json['section_heading']?.toString() ?? '',
      scientificSource: json['scientific_source']?.toString() ?? '',
      sourceUrl: json['source_url']?.toString() ?? '',
    );
  }
}

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.contentMarkdown,
    required this.citations,
    required this.safetyTriageCategory,
    required this.isEmergencyIntercepted,
    required this.disclaimerLevel,
    required this.suggestedFollowUps,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String role;
  final String contentMarkdown;
  final List<ClinicalCitation> citations;
  final String safetyTriageCategory;
  final bool isEmergencyIntercepted;
  final String disclaimerLevel;
  final List<String> suggestedFollowUps;
  final DateTime createdAt;
}
