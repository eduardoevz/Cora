import 'package:flutter/material.dart';

class PartnerSharingSettingsPage extends StatefulWidget {
  const PartnerSharingSettingsPage({
    super.key,
    this.initialInvitationCode,
    this.initialScopeFertility = false,
    this.initialScopePregnancy = false,
    this.initialScopeMood = false,
    this.onGenerateCode,
    this.onRedeemCode,
    this.onPermissionsChanged,
    this.onRevokeLink,
  });

  final String? initialInvitationCode;
  final bool initialScopeFertility;
  final bool initialScopePregnancy;
  final bool initialScopeMood;
  final Future<String> Function()? onGenerateCode;
  final Future<void> Function(String code)? onRedeemCode;
  final void Function(bool fertility, bool pregnancy, bool mood)?
      onPermissionsChanged;
  final Future<void> Function()? onRevokeLink;

  @override
  State<PartnerSharingSettingsPage> createState() =>
      _PartnerSharingSettingsPageState();
}

class _PartnerSharingSettingsPageState
    extends State<PartnerSharingSettingsPage> {
  String? _activeCode;
  final TextEditingController _codeController = TextEditingController();
  late bool _fertility;
  late bool _pregnancy;
  late bool _mood;
  bool _hasActiveLink = true;

  @override
  void initState() {
    super.initState();
    _activeCode = widget.initialInvitationCode;
    _fertility = widget.initialScopeFertility;
    _pregnancy = widget.initialScopePregnancy;
    _mood = widget.initialScopeMood;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _notifyPermissions() {
    widget.onPermissionsChanged?.call(_fertility, _pregnancy, _mood);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modo Acompañante / Pareja')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invitar a tu Pareja',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Genera un código temporal de 24 horas para compartir '
                    'únicamente lo que tú elijas con tu acompañante.',
                  ),
                  const SizedBox(height: 12),
                  if (_activeCode != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal),
                      ),
                      child: Text(
                        _activeCode!,
                        key: const Key('active_invitation_code_display'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Válido por 24 horas • Un solo uso',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ] else ...[
                    FilledButton.icon(
                      key: const Key('generate_invitation_code_button'),
                      onPressed: () async {
                        if (widget.onGenerateCode != null) {
                          final code = await widget.onGenerateCode!();
                          setState(() => _activeCode = code);
                        } else {
                          setState(() => _activeCode = 'CORA-TESTCODE');
                        }
                      },
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Generar Código de Invitación'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Canjear Código Recibido',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const Key('redeem_code_input'),
                    controller: _codeController,
                    decoration: const InputDecoration(
                      hintText: 'Ingresa el código (ej. CORA-XXXX)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    key: const Key('redeem_code_submit_button'),
                    onPressed: () async {
                      final code = _codeController.text.trim();
                      if (code.isNotEmpty) {
                        final messenger = ScaffoldMessenger.of(context);
                        await widget.onRedeemCode?.call(code);
                        if (!mounted) return;
                        _codeController.clear();
                        messenger.showSnackBar(
                          const SnackBar(
                              content: Text('Vínculo enlazado con éxito')),
                        );
                      }
                    },
                    child: const Text('Vincular Acompañante'),
                  ),
                ],
              ),
            ),
          ),
          if (_hasActiveLink) ...[
            const SizedBox(height: 20),
            const Text(
              'Permisos Compartidos Granulares',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('switch_share_fertility'),
              title: const Text('Compartir ventana fértil'),
              subtitle: const Text('Días estimados de ovulación'),
              value: _fertility,
              onChanged: (val) {
                setState(() => _fertility = val);
                _notifyPermissions();
              },
            ),
            SwitchListTile(
              key: const Key('switch_share_pregnancy'),
              title: const Text('Compartir hitos del embarazo'),
              subtitle: const Text('Semanas de gestación y tamaño fetal'),
              value: _pregnancy,
              onChanged: (val) {
                setState(() => _pregnancy = val);
                _notifyPermissions();
              },
            ),
            SwitchListTile(
              key: const Key('switch_share_mood'),
              title: const Text('Compartir estado de ánimo y consejos'),
              subtitle: const Text('Tips prácticos para que tu pareja te apoye'),
              value: _mood,
              onChanged: (val) {
                setState(() => _mood = val);
                _notifyPermissions();
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const Key('revoke_partner_link_button'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              icon: const Icon(Icons.link_off),
              label: const Text('Revocar Vínculo Inmediatamente'),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await widget.onRevokeLink?.call();
                if (!mounted) return;
                setState(() => _hasActiveLink = false);
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Vínculo revocado de inmediato')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
