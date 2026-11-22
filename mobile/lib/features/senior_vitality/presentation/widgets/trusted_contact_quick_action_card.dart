import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/senior_vitality/domain/models/trusted_support_contact.dart';
import 'package:mobile/features/senior_vitality/presentation/providers/senior_vitality_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class TrustedContactQuickActionCard extends ConsumerWidget {
  const TrustedContactQuickActionCard({super.key});

  Future<void> _showRegisterContactSheet(
      BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController(text: 'Hija / Familiar');
    final phoneCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registrar Contacto de Apoyo',
                  style: Theme.of(sheetCtx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('trusted_contact_name_input'),
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('trusted_contact_relation_input'),
                  controller: relationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Parentesco (ej. Hija, Esposo, Cuidador)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('trusted_contact_phone_input'),
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  key: const Key('save_trusted_contact_button'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: () async {
                    final user = ref.read(activeUserProfileProvider);
                    if (user == null ||
                        nameCtrl.text.trim().isEmpty ||
                        phoneCtrl.text.trim().isEmpty) {
                      return;
                    }
                    final contact = TrustedSupportContact(
                      id: const Uuid().v4(),
                      userId: user.id,
                      contactName: nameCtrl.text.trim(),
                      relationship: relationCtrl.text.trim().isEmpty
                          ? 'Familiar'
                          : relationCtrl.text.trim(),
                      phoneNumber: phoneCtrl.text.trim(),
                      isPrimary: true,
                    );
                    await ref
                        .read(seniorVitalityRepositoryProvider)
                        .saveSupportContact(contact);
                    ref.invalidate(primarySupportContactProvider);
                    if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Contacto'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showActionSheet(BuildContext context, TrustedSupportContact contact) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Confirmar Comunicación',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '¿Deseas comunicarte con ${contact.contactName} (${contact.phoneNumber})?',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  key: const Key('confirm_call_button'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    final uri = Uri.parse('tel:${contact.phoneNumber}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: const Icon(Icons.call, size: 28),
                  label: const Text(
                    'Llamar ahora',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('confirm_sms_button'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    final uri = Uri.parse('sms:${contact.phoneNumber}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: const Icon(Icons.message, size: 28),
                  label: const Text(
                    'Enviar mensaje SMS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final contactAsync = ref.watch(primarySupportContactProvider);

    return contactAsync.when(
      data: (contact) {
        if (contact == null) {
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showRegisterContactSheet(context, ref),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 20.0),
                child: Row(
                  children: [
                    Icon(Icons.person_add_alt_1_rounded,
                        size: 36, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contacto Familiar de Apoyo',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Toca para vincular a tu cuidador o familiar',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          key: const Key('trusted_contact_quick_card'),
          elevation: 3,
          color: theme.colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showActionSheet(context, contact),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.call,
                        size: 28, color: theme.colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Llamar a ${contact.contactName}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${contact.relationship} • Toca para confirmar llamada',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.touch_app_rounded,
                      color: theme.colorScheme.primary, size: 30),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
