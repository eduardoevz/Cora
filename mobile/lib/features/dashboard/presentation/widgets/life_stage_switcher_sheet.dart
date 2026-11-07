import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

class LifeStageSwitcherSheet extends ConsumerStatefulWidget {
  final UserProfileEntity profile;

  const LifeStageSwitcherSheet({super.key, required this.profile});

  static Future<void> show(BuildContext context, UserProfileEntity profile) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LifeStageSwitcherSheet(profile: profile),
    );
  }

  @override
  ConsumerState<LifeStageSwitcherSheet> createState() =>
      _LifeStageSwitcherSheetState();
}

class _LifeStageSwitcherSheetState
    extends ConsumerState<LifeStageSwitcherSheet> {
  late LifeStage _selectedStage;
  TransitionReason _selectedReason = TransitionReason.naturalProgression;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStage = widget.profile.currentLifeStage;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirmTransition() async {
    setState(() => _isLoading = true);
    try {
      final updated =
          await ref.read(identityRepositoryProvider).switchLifeStage(
                profileId: widget.profile.id,
                newStage: _selectedStage,
                reason: _selectedReason,
                notes: _notesController.text.trim().isNotEmpty
                    ? _notesController.text.trim()
                    : null,
              );

      ref.read(activeUserProfileProvider.notifier).state = updated;

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Etapa actualizada a: ${_selectedStage.label}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar de etapa: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cambiar Etapa de Vida',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cora adaptará dinámicamente tu pantalla principal y módulos activos.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LifeStage>(
              key: const Key('switch_target_stage_dropdown'),
              initialValue: _selectedStage,
              decoration: const InputDecoration(
                labelText: 'Nueva etapa biológica',
                border: OutlineInputBorder(),
              ),
              items: LifeStage.values.map((stage) {
                return DropdownMenuItem(
                  value: stage,
                  child: Text(stage.label),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStage = val);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TransitionReason>(
              key: const Key('switch_reason_dropdown'),
              initialValue: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Motivo del cambio',
                border: OutlineInputBorder(),
              ),
              items: TransitionReason.values.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(r.label),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedReason = val);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('switch_notes_input'),
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas o contexto clínico (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('confirm_stage_switch_button'),
              onPressed: _isLoading ? null : _confirmTransition,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmar Transición'),
            ),
          ],
        ),
      ),
    );
  }
}
