import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/cora_api_client.dart';
import 'package:mobile/features/education/data/offline_first_education_repository.dart';
import 'package:mobile/features/education/domain/models/clinical_article.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

final educationRepositoryProvider =
    Provider<OfflineFirstEducationRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return OfflineFirstEducationRepository(database: db);
});

final educationArticlesProvider =
    FutureProvider<List<ClinicalArticle>>((ref) async {
  final repo = ref.watch(educationRepositoryProvider);
  final api = ref.watch(coraApiClientProvider);

  // Offline-First: ensure local curated articles exist immediately
  var cached = await repo.listArticles();
  if (cached.isEmpty) {
    await repo.cacheArticles(_seedCuratedArticles);
    cached = await repo.listArticles();
  }

  // Opportunistically refresh from backend in the background (non-blocking)
  unawaited(() async {
    try {
      final res = await api.dio.get(
        '/education/articles',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final items = (res.data['items'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
        final fetched = items
            .map(
              (item) => ClinicalArticle(
                id: item['id']?.toString() ?? item['slug']?.toString() ?? '',
                slug: item['slug']?.toString() ?? '',
                title: item['title']?.toString() ?? '',
                summary: item['summary']?.toString() ?? '',
                bodyMarkdown: item['summary']?.toString() ?? '',
                targetLifeStages:
                    (item['target_life_stages'] as List<dynamic>? ?? const [])
                        .map((e) => e.toString())
                        .toList(),
                clinicalTags:
                    (item['clinical_tags'] as List<dynamic>? ?? const [])
                        .map((e) => e.toString())
                        .toList(),
                scientificSource: item['scientific_source']?.toString() ?? '',
                sourceUrl: item['source_url']?.toString() ?? '',
                reviewedBy: item['reviewed_by']?.toString() ?? '',
                readingTimeMinutes: item['reading_time_minutes'] as int? ?? 4,
                publishedAt: DateTime.tryParse(
                      item['published_at']?.toString() ?? '',
                    ) ??
                    DateTime.now(),
              ),
            )
            .toList();
        if (fetched.isNotEmpty) {
          await repo.cacheArticles(fetched);
        }
      }
    } catch (_) {
      // Ignore network errors in offline mode
    }
  }());

  return cached;
});

final List<ClinicalArticle> _seedCuratedArticles = [
  ClinicalArticle(
    id: 'seed-figo-01',
    slug: 'guia-figo-sangrado-y-ciclo-menstrual',
    title: 'Criterios FIGO para el Sangrado Uterino y Ciclo Menstrual',
    summary:
        'Parámetros clínicos internacionales de la FIGO para clasificar duración, frecuencia y regularidad del ciclo femenino.',
    bodyMarkdown: '### Parámetros Clínicos FIGO\n\n'
        'Un ciclo menstrual adulto típico dura entre **24 y 38 días**, con sangrado de **4 a 8 días**. '
        'En la adolescencia (primeros años posmenarquia) son fisiológicos ciclos entre **21 y 45 días**.\n\n'
        'Consulta con tu profesional de salud si empapas 1 o más toallas por hora durante 2 horas seguidas o presentas dolor pélvico incapacitante.',
    targetLifeStages: const ['adolescence', 'regular_adult'],
    clinicalTags: const ['figo', 'ciclo_menstrual', 'sangrado'],
    scientificSource: 'FIGO Menstrual Disorders Committee',
    sourceUrl: 'https://www.figo.org/guidelines-menstrual-disorders',
    reviewedBy: 'Comité Clínico de Ginecología Cora',
    readingTimeMinutes: 4,
    publishedAt: DateTime(2026, 1, 15),
  ),
  ClinicalArticle(
    id: 'seed-fertility-02',
    slug: 'biomarcadores-fertilidad-metodo-sintotermico',
    title: 'Biomarcadores de Fertilidad y Algoritmo Sintotérmico',
    summary:
        'Correlación fisiológica entre temperatura basal (BBT), moco cervical tipo clara de huevo y pico de hormona luteinizante (LH).',
    bodyMarkdown: '### Doble Confirmación Ovulatoria\n\n'
        'La combinación de **moco cervical fértil (clara de huevo)** y el **salto térmico bifásico** '
        '(3 temperaturas posovulatorias superiores a las 6 previas) permite identificar con precisión tu ventana fértil.',
    targetLifeStages: const ['conception_search', 'regular_adult'],
    clinicalTags: const ['fertilidad', 'temperatura_basal', 'sintotermico'],
    scientificSource: 'Sensiplan / ACOG',
    sourceUrl: 'https://www.acog.org',
    reviewedBy: 'Comité Clínico de Fertilidad Cora',
    readingTimeMinutes: 4,
    publishedAt: DateTime(2026, 1, 15),
  ),
  ClinicalArticle(
    id: 'seed-acog-03',
    slug: 'criterios-acog-hipertension-gestacional-preeclampsia',
    title: 'Criterios ACOG para Tensión Arterial en el Embarazo',
    summary:
        'Detección preventiva de hipertensión gestacional y signos de alarma de preeclampsia durante la gestación.',
    bodyMarkdown: '### Vigilancia de Tensión Arterial\n\n'
        'Valores **≥ 140/90 mmHg** requieren valoración obstétrica prioritaria. '
        'Cifras **≥ 160/110 mmHg** o acompañadas de cefalea intensa, visión borrosa o dolor en boca del estómago son motivo de atención de urgencias.',
    targetLifeStages: const ['pregnancy'],
    clinicalTags: const ['embarazo', 'preeclampsia', 'acog'],
    scientificSource: 'ACOG Practice Bulletin No. 222',
    sourceUrl: 'https://www.acog.org',
    reviewedBy: 'Comité Clínico de Obstetricia Cora',
    readingTimeMinutes: 5,
    publishedAt: DateTime(2026, 1, 15),
  ),
  ClinicalArticle(
    id: 'seed-epds-04',
    slug: 'escala-edimburgo-epds-salud-mental-perinatal',
    title: 'Salud Emocional en el Posparto y Escala de Edimburgo (EPDS)',
    summary:
        'Protocolo de acompañamiento emocional en el puerperio y reconocimiento oportuno de depresión posparto.',
    bodyMarkdown: '### Cuidado Emocional Perinatal\n\n'
        'El tamizaje **EPDS** permite identificar fatiga emocional o depresión posparto desde puntajes ≥ 10. '
        'No estás sola: pedir ayuda profesional a tiempo protege tu bienestar y el de tu bebé.',
    targetLifeStages: const ['postpartum'],
    clinicalTags: const ['posparto', 'epds', 'salud_mental'],
    scientificSource: 'Cox et al. / OMS Salud Perinatal',
    sourceUrl: 'https://www.who.int',
    reviewedBy: 'Comité de Salud Mental Perinatal Cora',
    readingTimeMinutes: 4,
    publishedAt: DateTime(2026, 1, 15),
  ),
  ClinicalArticle(
    id: 'seed-straw-05',
    slug: 'transicion-menopausica-criterios-straw10',
    title: 'Transición a la Menopausia y Criterios STRAW+10',
    summary:
        'Comprendiendo la variabilidad menstrual, síntomas vasomotores, salud ósea y cuidado cardiometabólico.',
    bodyMarkdown: '### Etapas STRAW+10\n\n'
        'Una diferencia persistente ≥ 7 días entre ciclos consecutivos caracteriza la transición temprana; '
        'pausas ≥ 60 días indican transición tardía. Tras 12 meses sin menstruación, cualquier nuevo sangrado requiere valoración ginecológica.',
    targetLifeStages: const ['perimenopause', 'senior_vitality'],
    clinicalTags: const ['menopausia', 'straw10', 'salud_osea'],
    scientificSource: 'STRAW+10 / NAMS',
    sourceUrl: 'https://www.menopause.org',
    reviewedBy: 'Comité de Endocrinología y Ginecología Cora',
    readingTimeMinutes: 5,
    publishedAt: DateTime(2026, 1, 15),
  ),
];
