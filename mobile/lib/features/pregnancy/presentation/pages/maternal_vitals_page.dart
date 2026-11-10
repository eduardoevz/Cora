import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        const SnackBar(content: Text('Ingresa al menos un valor de signo vital')),
      );
      return;
    }

    if (sys != null && dia != null && sys <= dia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error fisiológico: La sistólica debe ser estrictamente mayor que la diastólica.',
          ),
          backgroundColor: Colors.red,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signos vitales registrados y sincronizados'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentAsync = ref.watch(recentMaternalVitalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor Materno & Alertas ACOG'),
        backgroundColor: Colors.pink.shade50,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Live Alert Banner if preeclampsia or risk triggered
          if (_currentAlerts.isNotEmpty) ...[
            ..._currentAlerts.map(
              (alert) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: alert.severity == 'urgent_emergency'
                      ? Colors.red.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: alert.severity == 'urgent_emergency'
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          alert.severity == 'urgent_emergency'
                              ? Icons.warning
                              : Icons.info_outline,
                          color: alert.severity == 'urgent_emergency'
                              ? Colors.red.shade900
                              : Colors.orange.shade900,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: alert.severity == 'urgent_emergency'
                                  ? Colors.red.shade900
                                  : Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.message,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Recomendación: ${alert.actionRecommended}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registro de Signos Vitales',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Blood pressure row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _systolicController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sistólica (mmHg)',
                            hintText: 'ej. 120',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.favorite, color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _diastolicController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Diastólica (mmHg)',
                            hintText: 'ej. 80',
                            border: OutlineInputBorder(),
                            prefixIcon:
                                Icon(Icons.favorite_border, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Glucose and Timing
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _glucoseController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Glucosa (mg/dL)',
                            hintText: 'ej. 92.0',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.bloodtype, color: Colors.teal),
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
                    decoration: const InputDecoration(
                      labelText: 'Peso materno (kg)',
                      hintText: 'ej. 68.5',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale, color: Colors.blue),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Síntomas de Alarma ACOG (Marcar si se presentan):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
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
                    title: const Text('Dolor en boca del estómago / epigastralgia'),
                    value: _epigastricPain,
                    dense: true,
                    onChanged: (val) {
                      setState(() => _epigastricPain = val ?? false);
                      _evaluateLocal();
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Hinchazón repentina de manos o cara'),
                    value: _suddenEdema,
                    dense: true,
                    onChanged: (val) {
                      setState(() => _suddenEdema = val ?? false);
                      _evaluateLocal();
                    },
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saveVitals,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Registro'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Historial de Registros',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          recentAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No hay registros de signos vitales previos.'),
                  ),
                );
              }

              return Column(
                children: history.map((h) {
                  final bpText = (h.systolicMmhg != null && h.diastolicMmhg != null)
                      ? '${h.systolicMmhg}/${h.diastolicMmhg} mmHg'
                      : 'PA no registrada';
                  final gluText = h.glucoseMgDl != null
                      ? '${h.glucoseMgDl} mg/dL (${h.glucoseTiming})'
                      : '';
                  final wtText = h.weightKg != null ? '${h.weightKg} kg' : '';

                  final hasAlert = h.alerts.isNotEmpty;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: hasAlert ? Colors.red.shade50 : Colors.white,
                    child: ListTile(
                      leading: Icon(
                        hasAlert ? Icons.warning : Icons.check_circle,
                        color: hasAlert ? Colors.red : Colors.green,
                      ),
                      title: Text(
                        '$bpText ${gluText.isNotEmpty ? "• $gluText" : ""}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasAlert ? Colors.red.shade900 : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Semana ${h.gestationalWeeks} • ${h.measuredAt.day}/${h.measuredAt.month} ${wtText.isNotEmpty ? "• $wtText" : ""}',
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
