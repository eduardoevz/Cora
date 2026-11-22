import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/pregnancy/domain/entities/pregnancy_entities.dart';
import 'package:mobile/features/pregnancy/presentation/providers/pregnancy_providers.dart';
import 'package:uuid/uuid.dart';

class MaternalVitalsPage extends ConsumerStatefulWidget {
  final PregnancyEpisodeEntity episode;

  const MaternalVitalsPage({super.key, required this.episode});

  @override
  ConsumerState<MaternalVitalsPage> createState() => _MaternalVitalsPageState();
}

class _MaternalVitalsPageState extends ConsumerState<MaternalVitalsPage> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _weightController = TextEditingController();

  String _glucoseTiming = 'fasting';
  bool _headache = false;
  bool _visualBlur = false;
  bool _epigastricPain = false;
  bool _suddenEdema = false;

  List<MaternalAlertEntity> _currentAlerts = [];

  @override
  void initState() {
    super.initState();
    _systolicController.addListener(_evaluateLocal);
    _diastolicController.addListener(_evaluateLocal);
    _glucoseController.addListener(_evaluateLocal);
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _glucoseController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _evaluateLocal() {
    final sys = int.tryParse(_systolicController.text);
    final dia = int.tryParse(_diastolicController.text);
    final glu = double.tryParse(_glucoseController.text);

    final symptoms = <String>[];
    if (_headache) symptoms.add('persistent_severe_headache');
    if (_visualBlur) symptoms.add('scotomas_visual_blur');
    if (_epigastricPain) symptoms.add('epigastric_ruq_pain');
    if (_suddenEdema) symptoms.add('sudden_facial_hand_edema');

    setState(() {
      _currentAlerts = MaternalOfflineEvaluator.evaluateOffline(
        systolic: sys,
        diastolic: dia,
        glucose: glu,
        timing: _glucoseTiming,
        symptoms: symptoms,
      );
    });
  }

  Future<void> _saveVitals() async {
    final sys = int.tryParse(_systolicController.text);
    final dia = int.tryParse(_diastolicController.text);
    final glu = double.tryParse(_glucoseController.text);
    final wt = double.tryParse(_weightController.text);

    if (sys == null && dia == null && glu == null && wt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ingresa al menos un valor de signo vital')),
      );
      return;
    }

    if (sys != null && dia != null && sys <= dia) {
      final tokens = CoraTheme.tokensOf(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Error fisiológico: La sistólica debe ser estrictamente mayor que la diastólica.',
          ),
          backgroundColor: tokens.alertUrgent,
        ),
      );
      return;
    }

    final symptomsList = <Map<String, dynamic>>[];
    if (_headache) {
      symptomsList.add({'symptom_type': 'persistent_severe_headache'});
    }
    if (_visualBlur) {
      symptomsList.add({'symptom_type': 'scotomas_visual_blur'});
    }
    if (_epigastricPain) {
      symptomsList.add({'symptom_type': 'epigastric_ruq_pain'});
    }
    if (_suddenEdema) {
      symptomsList.add({'symptom_type': 'sudden_facial_hand_edema'});
    }

    final now = DateTime.now();
    final anchor = widget.episode.lastMenstrualPeriod ??
        widget.episode.clinicalEdd.subtract(const Duration(days: 280));
    final gaWeeks = (now.difference(anchor).inDays / 7).floor().clamp(3, 44);

    final vitalsEntity = MaternalVitalsEntity(
      id: const Uuid().v4(),
      pregnancyEpisodeId: widget.episode.id,
      measuredAt: now,
      gestationalWeeks: gaWeeks,
      systolicMmhg: sys,
      diastolicMmhg: dia,
      glucoseMgDl: glu,
      glucoseTiming: glu != null ? _glucoseTiming : null,
      weightKg: wt,
      symptoms: symptomsList,
      alerts: _currentAlerts,
    );

    final repo = ref.read(pregnancyRepositoryProvider);
    await repo.saveVitals(vitalsEntity);
    ref.invalidate(recentMaternalVitalsProvider);

    _systolicController.clear();
    _diastolicController.clear();
    _glucoseController.clear();
    _weightController.clear();
    setState(() {
      _headache = false;
      _visualBlur = false;
      _epigastricPain = false;
      _suddenEdema = false;
      _currentAlerts = [];
    });

    if (mounted) {
      final tokens = CoraTheme.tokensOf(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Signos vitales registrados y sincronizados'),
          backgroundColor: tokens.follicular,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentAsync = ref.watch(recentMaternalVitalsProvider);

    final tokens = CoraTheme.tokensOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor Materno & Alertas ACOG'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Live Alert Banner if preeclampsia or risk triggered
          if (_currentAlerts.isNotEmpty) ...[
            ..._currentAlerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CoraAlertBanner(
                  title: alert.title,
                  description: alert.message,
                  recommendation: 'Recomendación: ${alert.actionRecommended}',
                  isUrgent: alert.severity == 'urgent_emergency',
                ),
              ),
            ),
          ],

          CoraSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registro de Signos Vitales',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),

                // Blood pressure row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _systolicController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Sistólica (mmHg)',
                          hintText: 'ej. 120',
                          border: const OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.favorite, color: tokens.menstrual),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _diastolicController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Diastólica (mmHg)',
                          hintText: 'ej. 80',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.favorite_border,
                            color: tokens.menstrual,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Glucose and Timing
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _glucoseController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Glucosa (mg/dL)',
                          hintText: 'ej. 92.0',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.bloodtype_outlined,
                            color: tokens.follicular,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _glucoseTiming,
                        decoration: const InputDecoration(
                          labelText: 'Momento',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'fasting', child: Text('Ayunas')),
                          DropdownMenuItem(
                              value: 'postprandial_1h',
                              child: Text('1h Posprandial')),
                          DropdownMenuItem(
                              value: 'postprandial_2h',
                              child: Text('2h Posprandial')),
                          DropdownMenuItem(
                              value: 'random', child: Text('Azar')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _glucoseTiming = val);
                            _evaluateLocal();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Weight
                TextField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Peso materno (kg)',
                    hintText: 'ej. 68.5',
                    border: const OutlineInputBorder(),
                    prefixIcon:
                        Icon(Icons.scale_outlined, color: tokens.luteal),
                  ),
                ),

                const SizedBox(height: 16),
                const CoraSectionLabel(
                  title: 'Síntomas de Alarma ACOG (Marcar si se presentan):',
                ),
                Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: const Text('Cefalea intensa y persistente'),
                        value: _headache,
                        dense: true,
                        onChanged: (val) {
                          setState(() => _headache = val ?? false);
                          _evaluateLocal();
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Visión borrosa, escotomas o luces'),
                        value: _visualBlur,
                        dense: true,
                        onChanged: (val) {
                          setState(() => _visualBlur = val ?? false);
                          _evaluateLocal();
                        },
                      ),
                      CheckboxListTile(
                        title: const Text(
                          'Dolor en boca del estómago / epigastralgia',
                        ),
                        value: _epigastricPain,
                        dense: true,
                        onChanged: (val) {
                          setState(() => _epigastricPain = val ?? false);
                          _evaluateLocal();
                        },
                      ),
                      CheckboxListTile(
                        title:
                            const Text('Hinchazón repentina de manos o cara'),
                        value: _suddenEdema,
                        dense: true,
                        onChanged: (val) {
                          setState(() => _suddenEdema = val ?? false);
                          _evaluateLocal();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                CoraPrimaryActionButton(
                  label: 'Guardar Registro',
                  icon: Icons.save_outlined,
                  onPressed: _saveVitals,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const CoraSectionLabel(title: 'Historial de Registros'),
          const SizedBox(height: 10),

          recentAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return const CoraEmptyStateCard(
                  icon: Icons.monitor_heart_outlined,
                  title: 'Sin registros previos',
                  subtitle: 'No hay registros de signos vitales previos.',
                );
              }

              return Column(
                children: history.map((h) {
                  final bpText =
                      (h.systolicMmhg != null && h.diastolicMmhg != null)
                          ? '${h.systolicMmhg}/${h.diastolicMmhg} mmHg'
                          : 'PA no registrada';
                  final gluText = h.glucoseMgDl != null
                      ? '${h.glucoseMgDl} mg/dL (${h.glucoseTiming})'
                      : '';
                  final wtText = h.weightKg != null ? '${h.weightKg} kg' : '';

                  final hasAlert = h.alerts.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CoraSurfaceCard(
                      padding: EdgeInsets.zero,
                      backgroundColor: hasAlert
                          ? tokens.alertUrgent.withValues(alpha: 0.08)
                          : null,
                      borderColor: hasAlert
                          ? tokens.alertUrgent.withValues(alpha: 0.35)
                          : null,
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Icon(
                            hasAlert
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                            color: hasAlert
                                ? tokens.alertUrgent
                                : tokens.follicular,
                          ),
                          title: Text(
                            '$bpText ${gluText.isNotEmpty ? "• $gluText" : ""}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: hasAlert
                                  ? tokens.alertUrgent
                                  : tokens.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          subtitle: Text(
                            'Semana ${h.gestationalWeeks} • ${h.measuredAt.day}/${h.measuredAt.month} ${wtText.isNotEmpty ? "• $wtText" : ""}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error al cargar historial: $err'),
          ),
        ],
      ),
    );
  }
}
