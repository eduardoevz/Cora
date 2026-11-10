import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/postpartum/domain/entities/postpartum_entities.dart';
import 'package:mobile/features/postpartum/presentation/providers/postpartum_providers.dart';
import 'package:uuid/uuid.dart';

class PostpartumRecoveryPage extends ConsumerStatefulWidget {
  const PostpartumRecoveryPage({super.key});

  @override
  ConsumerState<PostpartumRecoveryPage> createState() =>
      _PostpartumRecoveryPageState();
}

class _PostpartumRecoveryPageState
    extends ConsumerState<PostpartumRecoveryPage> {
  int _daysPostpartum = 3;
  LochiaStage _lochiaStage = LochiaStage.rubra;
  LochiaFlow _lochiaFlow = LochiaFlow.moderate;
  bool _foulOdor = false;
  final TextEditingController _tempController = TextEditingController();
  PerinealWoundStatus _perinealStatus = PerinealWoundStatus.healingWell;
  CesareanWoundStatus _cesareanStatus = CesareanWoundStatus.notApplicable;
  final Set<PelvicFloorSymptom> _pelvicSymptoms = {PelvicFloorSymptom.normal};
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _tempController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? get _parsedTemperature {
    final text = _tempController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  List<PostpartumClinicalAlert> get _currentAlerts {
    return PostpartumOfflineEvaluator.evaluate(
      daysPostpartum: _daysPostpartum,
      lochiaStage: _lochiaStage,
      lochiaFlow: _lochiaFlow,
      foulOdor: _foulOdor,
      maternalTemperatureC: _parsedTemperature,
      perinealWoundStatus: _perinealStatus,
      cesareanWoundStatus: _cesareanStatus,
      pelvicFloorSymptoms: _pelvicSymptoms.toList(),
    );
  }

  Future<void> _saveLog() async {
    final user = ref.read(activeUserProfileProvider);
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final alerts = _currentAlerts;
      final log = PostpartumRecoveryLog(
        id: const Uuid().v4(),
        userId: user.id,
        loggedAt: DateTime.now(),
        daysPostpartum: _daysPostpartum,
        lochiaStage: _lochiaStage,
        lochiaFlow: _lochiaFlow,
        foulOdor: _foulOdor,
        maternalTemperatureC: _parsedTemperature,
        perinealWoundStatus: _perinealStatus,
        cesareanWoundStatus: _cesareanStatus,
        pelvicFloorSymptoms: _pelvicSymptoms.toList(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        alerts: alerts,
      );

      final repo = ref.read(postpartumRepositoryProvider);
      await repo.saveRecoveryLog(log);

      ref.invalidate(recentRecoveryLogsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro puerperal guardado localmente con éxito'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar registro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alerts = _currentAlerts;
    final recentLogsAsync = ref.watch(recentRecoveryLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperación Puerperal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Days Postpartum Selector
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Días posparto',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Día $_daysPostpartum tras el nacimiento',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          key: const Key('btn_decrement_day'),
                          onPressed: _daysPostpartum > 0
                              ? () => setState(() => _daysPostpartum--)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$_daysPostpartum',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          key: const Key('btn_increment_day'),
                          onPressed: () => setState(() => _daysPostpartum++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Clinical Alerts Banner
            if (alerts.isNotEmpty) ...[
              ...alerts.map((alert) {
                final isUrgent =
                    alert.severity == PostpartumAlertSeverity.urgentEmergency;
                final bgColor = isUrgent
                    ? Colors.red.shade50
                    : Colors.amber.shade50;
                final borderColor = isUrgent ? Colors.red : Colors.amber.shade700;
                final iconColor = isUrgent ? Colors.red.shade700 : Colors.amber.shade800;

                return Container(
                  key: Key('alert_${alert.category}'),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isUrgent
                                ? Icons.warning_amber_rounded
                                : Icons.info_outline,
                            color: iconColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              alert.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: isUrgent
                                    ? Colors.red.shade900
                                    : Colors.brown.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alert.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isUrgent
                              ? Colors.red.shade800
                              : Colors.brown.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.medical_services_outlined,
                                size: 18, color: iconColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                alert.actionRecommended,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

            // Lochia Section
            Text(
              'Evolución de Loquios',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Color / Etapa de loquios',
                        style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<LochiaStage>(
                      initialValue: _lochiaStage,
                      key: const Key('dropdown_lochia_stage'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: LochiaStage.values.map((stage) {
                        return DropdownMenuItem(
                          value: stage,
                          child: Text(stage.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _lochiaStage = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    Text('Flujo / Abundancia',
                        style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<LochiaFlow>(
                      initialValue: _lochiaFlow,
                      key: const Key('dropdown_lochia_flow'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: LochiaFlow.values.map((flow) {
                        return DropdownMenuItem(
                          value: flow,
                          child: Text(flow.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _lochiaFlow = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      key: const Key('switch_foul_odor'),
                      title: const Text('¿Olor fétido o inusual?'),
                      subtitle: const Text(
                          'El mal olor puede señalar una infección bacteriana uterina'),
                      value: _foulOdor,
                      onChanged: (val) => setState(() => _foulOdor = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Maternal Temperature
            Text(
              'Signos Vitales Maternos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _tempController,
                  key: const Key('input_temperature'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Temperatura corporal (°C)',
                    hintText: 'Ej. 36.8 o 38.2',
                    prefixIcon: Icon(Icons.thermostat),
                    border: OutlineInputBorder(),
                    helperText:
                      'Fiebre puerperal: temperatura ≥ 38.0°C en cualquier toma',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Wounds Status
            Text(
              'Heridas y Cicatrización',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Herida Perineal (Episiotomía o Desgarro)',
                        style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<PerinealWoundStatus>(
                      initialValue: _perinealStatus,
                      key: const Key('dropdown_perineal_status'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: PerinealWoundStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _perinealStatus = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    Text('Herida de Cesárea',
                        style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<CesareanWoundStatus>(
                      initialValue: _cesareanStatus,
                      key: const Key('dropdown_cesarean_status'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: CesareanWoundStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _cesareanStatus = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pelvic Floor Symptoms
            Text(
              'Salud del Suelo Pélvico',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: PelvicFloorSymptom.values.map((symptom) {
                  final isSelected = _pelvicSymptoms.contains(symptom);
                  return CheckboxListTile(
                    key: Key('checkbox_${symptom.toApiValue()}'),
                    title: Text(symptom.displayName),
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (symptom == PelvicFloorSymptom.normal) {
                          if (checked == true) {
                            _pelvicSymptoms.clear();
                            _pelvicSymptoms.add(PelvicFloorSymptom.normal);
                          }
                        } else {
                          _pelvicSymptoms.remove(PelvicFloorSymptom.normal);
                          if (checked == true) {
                            _pelvicSymptoms.add(symptom);
                          } else {
                            _pelvicSymptoms.remove(symptom);
                          }
                          if (_pelvicSymptoms.isEmpty) {
                            _pelvicSymptoms.add(PelvicFloorSymptom.normal);
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              key: const Key('input_notes'),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notas u observaciones personales (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            FilledButton.icon(
              key: const Key('btn_save_recovery_log'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _isSaving ? null : _saveLog,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text(
                'Guardar Registro de Recuperación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Logs Section
            Text(
              'Registros Anteriores',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            recentLogsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No hay registros puerperales previos aún.'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      key: Key('log_card_${log.id}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: log.alerts.isNotEmpty
                              ? Colors.red.shade100
                              : Colors.teal.shade100,
                          child: Icon(
                            log.alerts.isNotEmpty
                                ? Icons.warning_amber
                                : Icons.favorite,
                            color: log.alerts.isNotEmpty
                                ? Colors.red
                                : Colors.teal,
                          ),
                        ),
                        title: Text(
                          'Día ${log.daysPostpartum} — ${log.lochiaStage.displayName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Flujo: ${log.lochiaFlow.displayName}'
                          '${log.maternalTemperatureC != null ? " • ${log.maternalTemperatureC}°C" : ""}'
                          '${log.alerts.isNotEmpty ? " • ${log.alerts.length} alertas" : ""}',
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error al cargar historial: $err'),
            ),
          ],
        ),
      ),
    );
  }
}
