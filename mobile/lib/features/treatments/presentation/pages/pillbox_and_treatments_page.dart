import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/notifications/discreet_notification_service.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/treatments/domain/entities/treatment_entities.dart';
import 'package:mobile/features/treatments/presentation/providers/treatment_providers.dart';
import 'package:uuid/uuid.dart';

class PillboxAndTreatmentsPage extends ConsumerStatefulWidget {
  const PillboxAndTreatmentsPage({super.key});

  @override
  ConsumerState<PillboxAndTreatmentsPage> createState() =>
      _PillboxAndTreatmentsPageState();
}

class _PillboxAndTreatmentsPageState
    extends ConsumerState<PillboxAndTreatmentsPage> {
  bool _isDiscreet = true;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeUserProfileProvider);
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pastillero y Tratamientos')),
        body: const Center(child: Text('Cargando perfil...')),
      );
    }

    final regimensAsync = ref.watch(userRegimensProvider(profile.id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pastillero y Tratamientos'),
        actions: [
          IconButton(
            key: const Key('add_regimen_button'),
            icon: const Icon(Icons.add),
            tooltip: 'Añadir tratamiento',
            onPressed: () => _showAddRegimenDialog(context, profile.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Privacy Mode Card
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: SwitchListTile(
                key: const Key('discreet_mode_switch'),
                secondary: Icon(
                  _isDiscreet ? Icons.visibility_off : Icons.visibility,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Modo Discreto de Notificaciones'),
                subtitle: Text(
                  _isDiscreet
                      ? 'Texto enmascarado: "Tienes un recordatorio de bienestar en Cora"'
                      : 'Texto clínico con nombre del medicamento y dosis',
                  style: theme.textTheme.bodySmall,
                ),
                value: _isDiscreet,
                onChanged: (val) => setState(() => _isDiscreet = val),
              ),
            ),
            const SizedBox(height: 16),

            // Today's Doses Header
            Text(
              'Tomas Programadas para Hoy',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            regimensAsync.when(
              data: (regimens) {
                if (regimens.isEmpty) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.medication_outlined,
                              size: 48, color: theme.colorScheme.primary),
                          const SizedBox(height: 12),
                          const Text(
                            'No tienes tratamientos registrados',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Registra anticonceptivos, suplementos (ácido fólico, hierro) o medicación.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Añadir Tratamiento'),
                            onPressed: () =>
                                _showAddRegimenDialog(context, profile.id),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: regimens.map((regimen) {
                    return _buildRegimenPillboxCard(
                        context, regimen, profile.id);
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error al cargar regímenes: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegimenPillboxCard(
    BuildContext context,
    TreatmentRegimenEntity regimen,
    String userId,
  ) {
    final theme = Theme.of(context);
    final notificationService = ref.read(discreetNotificationServiceProvider);
    final reminderText = notificationService.formatReminder(
      type: NotificationType.treatmentIntake,
      detailedTitle: 'Tomar ${regimen.name}',
      detailedBody: '${regimen.dosage} a las ${regimen.scheduledTime}',
      isDiscreet: _isDiscreet,
    );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        regimen.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${regimen.dosage} • ${regimen.scheduledTime} hrs',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    regimen.scheduleType == 'cyclic_active_break'
                        ? '${regimen.activeDays}/${regimen.breakDays}'
                        : regimen.category,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor:
                      theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Reminder Preview
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recordatorio: "${reminderText.body}"',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  key: Key('skip_dose_${regimen.id}'),
                  onPressed: () => _recordDose(
                    regimen: regimen,
                    userId: userId,
                    status: 'skipped',
                  ),
                  child: const Text('Omitir'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: Key('take_dose_${regimen.id}'),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Tomar Dosis'),
                  onPressed: () => _recordDose(
                    regimen: regimen,
                    userId: userId,
                    status: 'taken',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordDose({
    required TreatmentRegimenEntity regimen,
    required String userId,
    required String status,
  }) async {
    final repo = ref.read(treatmentsRepositoryProvider);
    final now = DateTime.now().toUtc();
    final scheduledFor = DateTime.utc(now.year, now.month, now.day, 21, 0);

    await repo.recordIntake(
      regimenId: regimen.id,
      scheduledFor: scheduledFor,
      takenAt: status == 'taken' ? now : null,
      status: status,
      notes: status == 'taken' ? 'Tomada puntualmente' : 'Dosis omitida',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'taken'
              ? '¡Dosis de ${regimen.name} registrada con éxito!'
              : 'Dosis de ${regimen.name} marcada como omitida.'),
          backgroundColor: status == 'taken' ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  void _showAddRegimenDialog(BuildContext context, String userId) {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController(text: '1 comprimido');
    final timeCtrl = TextEditingController(text: '09:00');
    String selectedCategory = 'contraceptive_oral_combined';
    String selectedSchedule = 'cyclic_active_break';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuevo Tratamiento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('regimen_name_input'),
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del fármaco / suplemento'),
                ),
                TextField(
                  key: const Key('regimen_dosage_input'),
                  controller: dosageCtrl,
                  decoration: const InputDecoration(labelText: 'Dosis (ej. 1 comprimido, 400 mcg)'),
                ),
                TextField(
                  key: const Key('regimen_time_input'),
                  controller: timeCtrl,
                  decoration: const InputDecoration(labelText: 'Hora programada (HH:MM)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: const [
                    DropdownMenuItem(value: 'contraceptive_oral_combined', child: Text('Anticonceptivo Combinado')),
                    DropdownMenuItem(value: 'contraceptive_progestin_only', child: Text('Minipíldora (Progestina)')),
                    DropdownMenuItem(value: 'supplement', child: Text('Suplemento (Ácido fólico, etc.)')),
                    DropdownMenuItem(value: 'chronic_medication', child: Text('Medicación Crónica')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCategory = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('save_new_regimen_button'),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final repo = ref.read(treatmentsRepositoryProvider);
                final newRegimen = TreatmentRegimenEntity(
                  id: const Uuid().v4(),
                  userId: userId,
                  name: name,
                  category: selectedCategory,
                  dosage: dosageCtrl.text.trim(),
                  scheduleType: selectedSchedule,
                  scheduledTime: timeCtrl.text.trim(),
                  activeDays: 21,
                  breakDays: 7,
                  startDate: DateTime.now().toUtc(),
                );

                await repo.saveRegimen(newRegimen);
                ref.invalidate(userRegimensProvider(userId));

                if (context.mounted) {
                  Navigator.of(dialogCtx).pop();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
