import 'package:flutter/material.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';

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
    this.onOpenCompanionView,
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
  final VoidCallback? onOpenCompanionView;

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
    final tokens = CoraTheme.tokensOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Modo Acompañante / Pareja')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CoraSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invitar a tu Pareja',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Genera un código temporal de 24 horas para compartir '
                  'únicamente lo que tú elijas con tu acompañante.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                if (_activeCode != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: tokens.follicularSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tokens.follicular),
                    ),
                    child: Text(
                      _activeCode!,
                      key: const Key('active_invitation_code_display'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: tokens.follicular,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Válido por 24 horas • Un solo uso',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                        ),
                  ),
                ] else ...[
                  FilledButton.icon(
                    key: const Key('generate_invitation_code_button'),
                    onPressed: () async {
                      if (widget.onGenerateCode != null) {
                        final code = await widget.onGenerateCode!();
                        if (!mounted) return;
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
          const SizedBox(height: 16),
          CoraSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Canjear Código Recibido',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
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
          if (_hasActiveLink) ...[
            const SizedBox(height: 20),
            const CoraSectionLabel(title: 'Permisos Compartidos Granulares'),
            const SizedBox(height: 8),
            CoraSurfaceCard(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
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
                      subtitle:
                          const Text('Semanas de gestación y tamaño fetal'),
                      value: _pregnancy,
                      onChanged: (val) {
                        setState(() => _pregnancy = val);
                        _notifyPermissions();
                      },
                    ),
                    SwitchListTile(
                      key: const Key('switch_share_mood'),
                      title: const Text('Compartir estado de ánimo y consejos'),
                      subtitle: const Text(
                          'Tips prácticos para que tu pareja te apoye'),
                      value: _mood,
                      onChanged: (val) {
                        setState(() => _mood = val);
                        _notifyPermissions();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (widget.onOpenCompanionView != null) ...[
              FilledButton.tonalIcon(
                key: const Key('open_companion_view_button'),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Abrir Vista de Acompañante (Solo Lectura)'),
                onPressed: widget.onOpenCompanionView,
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              key: const Key('revoke_partner_link_button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.alertUrgent,
                side: BorderSide(color: tokens.alertUrgent),
              ),
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
