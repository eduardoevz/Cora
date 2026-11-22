import 'package:flutter/material.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/education/domain/models/clinical_article.dart';

class ClinicalLibraryPage extends StatefulWidget {
  const ClinicalLibraryPage({
    super.key,
    required this.articles,
    this.initialLifeStage,
  });

  final List<ClinicalArticle> articles;
  final String? initialLifeStage;

  @override
  State<ClinicalLibraryPage> createState() => _ClinicalLibraryPageState();
}

class _ClinicalLibraryPageState extends State<ClinicalLibraryPage> {
  String _searchQuery = '';
  String? _selectedStage;

  @override
  void initState() {
    super.initState();
    _selectedStage = widget.initialLifeStage;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.articles.where((article) {
      if (_selectedStage != null &&
          !article.targetLifeStages.contains(_selectedStage)) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        return article.title.toLowerCase().contains(q) ||
            article.summary.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca Clínica Cora'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: CoraStitchPageHeader(
              eyebrow: 'EVIDENCIA CIENTÍFICA CURADA',
              title: 'Guías Médicas Cora',
              eyebrowIcon: Icons.menu_book_outlined,
              mintEyebrow: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: const Key('library_search_field'),
              decoration: const InputDecoration(
                hintText: 'Buscar guías clínicas (OMS, ACOG, FIGO, NAMS)...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CoraEmptyStateCard(
                        icon: Icons.menu_book_outlined,
                        title: 'Sin resultados',
                        subtitle:
                            'No se encontraron artículos para este filtro.',
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final article = filtered[index];
                      final tokens = CoraTheme.tokensOf(context);
                      return CoraSurfaceCard(
                        key: Key('article_card_${article.slug}'),
                        padding: EdgeInsets.zero,
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            title: Text(
                              article.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(article.summary),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    CoraMintStatusPill(
                                      label: article.scientificSource,
                                      variant: CoraStatusPillVariant.softMint,
                                    ),
                                    Text(
                                      '${article.readingTimeMinutes} min de lectura',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                        color: tokens.textSecondary,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ArticleReaderPage(article: article),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ArticleReaderPage extends StatelessWidget {
  const ArticleReaderPage({super.key, required this.article});

  final ClinicalArticle article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            article.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Fuente científica: ${article.scientificSource}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Text(
            'Revisado por: ${article.reviewedBy}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(height: 24),
          Text(
            article.bodyMarkdown,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
