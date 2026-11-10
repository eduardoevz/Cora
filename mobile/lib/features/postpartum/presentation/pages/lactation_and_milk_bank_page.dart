import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/postpartum/domain/entities/postpartum_entities.dart';
import 'package:mobile/features/postpartum/presentation/providers/postpartum_providers.dart';
import 'package:uuid/uuid.dart';

class LactationAndMilkBankPage extends ConsumerStatefulWidget {
  const LactationAndMilkBankPage({super.key});

  @override
  ConsumerState<LactationAndMilkBankPage> createState() =>
      _LactationAndMilkBankPageState();
}

class _LactationAndMilkBankPageState
    extends ConsumerState<LactationAndMilkBankPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Timer State
  Timer? _ticker;
  DateTime? _sessionStart;
  int _leftSeconds = 0;
  int _rightSeconds = 0;
  OfferedBreast _activeTimerBreast = OfferedBreast.none;
  OfferedBreast _lastOfferedBreast = OfferedBreast.none;
  FeedingType _feedingType = FeedingType.breastOnly;
  final TextEditingController _bottleVolumeController =
      TextEditingController();
  final TextEditingController _timerNotesController = TextEditingController();
  bool _isSavingSession = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tabController.dispose();
    _bottleVolumeController.dispose();
    _timerNotesController.dispose();
    super.dispose();
  }

  void _startOrSwitchBreast(OfferedBreast breast) {
    _sessionStart ??= DateTime.now();

    if (_activeTimerBreast == breast) {
      // Pause
      _ticker?.cancel();
      _ticker = null;
      setState(() {
        _activeTimerBreast = OfferedBreast.none;
      });
      return;
    }

    _ticker?.cancel();
    _lastOfferedBreast = breast;
    _activeTimerBreast = breast;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_activeTimerBreast == OfferedBreast.left) {
          _leftSeconds++;
        } else if (_activeTimerBreast == OfferedBreast.right) {
          _rightSeconds++;
        }
      });
    });

    setState(() {});
  }

  void _resetTimer() {
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _sessionStart = null;
      _leftSeconds = 0;
      _rightSeconds = 0;
      _activeTimerBreast = OfferedBreast.none;
      _lastOfferedBreast = OfferedBreast.none;
      _bottleVolumeController.clear();
      _timerNotesController.clear();
    });
  }

  String _formatDuration(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _saveLactationSession() async {
    final user = ref.read(activeUserProfileProvider);
    if (user == null) return;

    final totalSecs = _leftSeconds + _rightSeconds;
    if (totalSecs == 0 && _bottleVolumeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registra al menos un minuto de toma o volumen en biberón'),
        ),
      );
      return;
    }

    setState(() => _isSavingSession = true);
    try {
      final now = DateTime.now();
      final start = _sessionStart ?? now.subtract(Duration(seconds: totalSecs));
      final double? bottleVol =
          double.tryParse(_bottleVolumeController.text.trim().replaceAll(',', '.'));

      final session = LactationSession(
        id: const Uuid().v4(),
        userId: user.id,
        startedAt: start,
        endedAt: now,
        leftDurationSeconds: _leftSeconds,
        rightDurationSeconds: _rightSeconds,
        totalDurationSeconds: totalSecs,
        lastOfferedBreast: _lastOfferedBreast,
        suggestedNextBreast:
            LactationSession.calculateNextBreast(_lastOfferedBreast),
        bottleVolumeMl: bottleVol,
        feedingType: _feedingType,
        notes: _timerNotesController.text.trim().isEmpty
            ? null
            : _timerNotesController.text.trim(),
      );

      final repo = ref.read(postpartumRepositoryProvider);
      await repo.saveLactationSession(session);

      ref.invalidate(recentLactationSessionsProvider);
      _resetTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toma registrada con éxito'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar toma: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingSession = false);
    }
  }

  void _showAddMilkDialog(BuildContext context) {
    final volController = TextEditingController();
    final notesController = TextEditingController();
    StorageLocation selectedLoc = StorageLocation.refrigerator;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final now = DateTime.now();
            final expiresAt =
                MilkStashEntry.calculateExpiration(now, selectedLoc);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Añadir Leche al Banco',
                      style: Theme.of(dialogCtx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: volController,
                      key: const Key('input_milk_volume'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Volumen extraído (ml)',
                        prefixIcon: Icon(Icons.water_drop),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<StorageLocation>(
                      initialValue: selectedLoc,
                      key: const Key('dropdown_storage_location'),
                      decoration: const InputDecoration(
                        labelText: 'Ubicación de almacenamiento',
                        border: OutlineInputBorder(),
                      ),
                      items: StorageLocation.values.map((loc) {
                        return DropdownMenuItem(
                          value: loc,
                          child: Text(loc.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedLoc = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Caducidad estimada CDC/OMS: '
                        '${expiresAt.day}/${expiresAt.month}/${expiresAt.year} '
                        'a las ${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      key: const Key('input_milk_notes'),
                      decoration: const InputDecoration(
                        labelText: 'Notas (lote, hora de extracción, etc.)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      key: const Key('btn_confirm_add_milk'),
                      onPressed: () async {
                        final vol = double.tryParse(volController.text
                            .trim()
                            .replaceAll(',', '.'));
                        if (vol == null || vol <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ingresa un volumen válido en ml'),
                            ),
                          );
                          return;
                        }

                        final user = ref.read(activeUserProfileProvider);
                        if (user == null) return;

                        final entry = MilkStashEntry(
                          id: const Uuid().v4(),
                          userId: user.id,
                          pumpedAt: now,
                          volumeMl: vol,
                          storageLocation: selectedLoc,
                          expiresAt: expiresAt,
                          notes: notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                        );

                        final repo = ref.read(postpartumRepositoryProvider);
                        await repo.saveMilkStashEntry(entry);
                        ref.invalidate(activeMilkStashProvider);

                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      },
                      child: const Text('Guardar en Banco de Leche'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestedNext = ref.watch(suggestedNextBreastProvider);
    final milkStashAsync = ref.watch(activeMilkStashProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lactancia y Banco de Leche'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.timer_outlined), text: 'Tomas y Cronómetro'),
            Tab(icon: Icon(Icons.kitchen_outlined), text: 'Banco de Leche'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Breastfeeding Tracker & Dual Timer
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Suggested Next Breast Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.swap_calls,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Próximo pecho sugerido',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              suggestedNext.displayName,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Dual Timer Interactive Cards (>= 56 dp touch targets)
                Row(
                  children: [
                    // Left Breast Card
                    Expanded(
                      child: Card(
                        elevation: _activeTimerBreast == OfferedBreast.left ? 4 : 1,
                        color: _activeTimerBreast == OfferedBreast.left
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: _activeTimerBreast == OfferedBreast.left
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: _activeTimerBreast == OfferedBreast.left ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          key: const Key('btn_left_breast_timer'),
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _startOrSwitchBreast(OfferedBreast.left),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 12),
                            child: Column(
                              children: [
                                Icon(
                                  _activeTimerBreast == OfferedBreast.left
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  size: 48,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Pecho Izquierdo',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDuration(_leftSeconds),
                                  key: const Key('text_left_duration'),
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: const [],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _activeTimerBreast == OfferedBreast.left
                                      ? 'Tocando para pausar'
                                      : 'Toca para cronometrar',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Right Breast Card
                    Expanded(
                      child: Card(
                        elevation: _activeTimerBreast == OfferedBreast.right ? 4 : 1,
                        color: _activeTimerBreast == OfferedBreast.right
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: _activeTimerBreast == OfferedBreast.right
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: _activeTimerBreast == OfferedBreast.right ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          key: const Key('btn_right_breast_timer'),
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _startOrSwitchBreast(OfferedBreast.right),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 12),
                            child: Column(
                              children: [
                                Icon(
                                  _activeTimerBreast == OfferedBreast.right
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  size: 48,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Pecho Derecho',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDuration(_rightSeconds),
                                  key: const Key('text_right_duration'),
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: const [],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _activeTimerBreast == OfferedBreast.right
                                      ? 'Tocando para pausar'
                                      : 'Toca para cronometrar',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Total session time & Reset Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiempo total: ${_formatDuration(_leftSeconds + _rightSeconds)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: (_leftSeconds + _rightSeconds > 0)
                          ? _resetTimer
                          : null,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reiniciar'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Feeding Type & Bottle
                DropdownButtonFormField<FeedingType>(
                  initialValue: _feedingType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de alimentación',
                    border: OutlineInputBorder(),
                  ),
                  items: FeedingType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _feedingType = val);
                  },
                ),
                const SizedBox(height: 14),

                if (_feedingType != FeedingType.breastOnly) ...[
                  TextField(
                    controller: _bottleVolumeController,
                    key: const Key('input_bottle_volume'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Volumen en biberón (ml, opcional)',
                      prefixIcon: Icon(Icons.local_drink),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                TextField(
                  controller: _timerNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas de la toma (agarre, ánimo del bebé)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                FilledButton.icon(
                  key: const Key('btn_save_lactation_session'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: _isSavingSession ? null : _saveLactationSession,
                  icon: _isSavingSession
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Guardar Sesión de Lactancia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // TAB 2: Milk Stash (FIFO Bank)
          milkStashAsync.when(
            data: (stashList) {
              return Scaffold(
                floatingActionButton: FloatingActionButton.extended(
                  key: const Key('btn_open_add_milk'),
                  onPressed: () => _showAddMilkDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Extraer Leche'),
                ),
                body: stashList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: theme.colorScheme.secondary),
                            const SizedBox(height: 12),
                            const Text(
                              'Tu banco de leche está vacío.',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Pulsa "Extraer Leche" para registrar un lote.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: stashList.length,
                        itemBuilder: (context, index) {
                          final entry = stashList[index];
                          final isExpired = entry.isExpired;
                          final hoursLeft = entry.remainingTime.inHours;

                          Color badgeColor;
                          String badgeText;
                          if (isExpired) {
                            badgeColor = Colors.red;
                            badgeText = 'Caducado';
                          } else if (hoursLeft < 24) {
                            badgeColor = Colors.orange;
                            badgeText = 'Vence en ${hoursLeft}h';
                          } else {
                            final daysLeft = entry.remainingTime.inDays;
                            badgeColor = Colors.green;
                            badgeText = 'Vence en ${daysLeft}d';
                          }

                          return Card(
                            key: Key('stash_card_${entry.id}'),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isExpired
                                    ? Colors.red.shade300
                                    : theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${entry.volumeMl.toStringAsFixed(0)} ml',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border:
                                              Border.all(color: badgeColor),
                                        ),
                                        child: Text(
                                          badgeText,
                                          style: TextStyle(
                                            color: badgeColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    entry.storageLocation.displayName,
                                    style: TextStyle(
                                      color: theme.colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Extraída: ${entry.pumpedAt.day}/${entry.pumpedAt.month} '
                                    '${entry.pumpedAt.hour.toString().padLeft(2, '0')}:${entry.pumpedAt.minute.toString().padLeft(2, '0')}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  if (entry.notes != null) ...[
                                    const SizedBox(height: 4),
                                    Text('Notas: ${entry.notes}',
                                        style: theme.textTheme.bodySmall),
                                  ],
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    key: Key('btn_consume_${entry.id}'),
                                    onPressed: () async {
                                      final repo = ref.read(
                                          postpartumRepositoryProvider);
                                      await repo.markMilkStashConsumed(entry.id);
                                      ref.invalidate(activeMilkStashProvider);
                                    },
                                    icon: const Icon(Icons.done_all),
                                    label: const Text('Marcar como consumido'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ],
      ),
    );
  }
}
