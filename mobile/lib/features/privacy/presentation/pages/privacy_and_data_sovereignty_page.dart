import 'package:flutter/material.dart';
import '../../../../core/security/biometric_lock_service.dart';
import '../../../../core/security/discreet_app_icon_service.dart';
import '../../../../core/theme/cora_design_components.dart';
import '../../../../core/theme/cora_theme.dart';

class PrivacyAndDataSovereigntyPage extends StatefulWidget {
  final BiometricLockService biometricService;
  final DiscreetAppIconService iconService;
  final Future<void> Function()? onExportData;
  final Future<void> Function(String phrase)? onPurgeAccount;
  final Future<void> Function()? onSignOut;

  const PrivacyAndDataSovereigntyPage({
    super.key,
    required this.biometricService,
    required this.iconService,
    this.onExportData,
    this.onPurgeAccount,
    this.onSignOut,
  });

  @override
  State<PrivacyAndDataSovereigntyPage> createState() =>
      _PrivacyAndDataSovereigntyPageState();
}

class _PrivacyAndDataSovereigntyPageState
    extends State<PrivacyAndDataSovereigntyPage> {
  late bool _biometricEnabled;
  late BiometricLockTimeout _timeout;
  late DiscreetAppIcon _currentIcon;
  bool _isExporting = false;
  bool _isPurging = false;

  @override
  void initState() {
    super.initState();
    _biometricEnabled = widget.biometricService.isBiometricEnabled;
    _timeout = widget.biometricService.timeout;
    _currentIcon = widget.iconService.currentIcon;
  }

  Future<void> _handleExportData() async {
    setState(() => _isExporting = true);
    try {
      if (widget.onExportData != null) {
        await widget.onExportData!();
      }
      if (mounted) {
        final tokens = CoraTheme.tokensOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('export_success_snackbar'),
            content: const Text(
                'Copia portable exportada con éxito en archivo ZIP.'),
            backgroundColor: tokens.follicular,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final tokens = CoraTheme.tokensOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('export_error_snackbar'),
            content: Text('Error al exportar datos: $e'),
            backgroundColor: tokens.alertUrgent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showPurgeConfirmationDialog() {
    final phraseController = TextEditingController();
    const requiredPhrase = 'ELIMINAR MI CUENTA CORA';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isPhraseMatching = phraseController.text == requiredPhrase;

            return AlertDialog(
              key: const Key('purge_confirmation_dialog'),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: CoraTheme.tokensOf(context).alertUrgent),
                  const SizedBox(width: 8),
                  const Flexible(child: Text('Purga Irreversible')),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Esta acción eliminará de forma inmediata y definitiva todos tus registros de salud, ciclos, síntomas, notas, archivos clínicos y tu cuenta.',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Para confirmar, escribe exactamente la frase:',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SelectableText(
                      requiredPhrase,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('purge_phrase_field'),
                      controller: phraseController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: requiredPhrase,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  key: const Key('purge_cancel_button'),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  key: const Key('purge_confirm_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isPhraseMatching && !_isPurging
                      ? () async {
                          Navigator.of(dialogCtx).pop();
                          await _executePurge(phraseController.text);
                        }
                      : null,
                  child: const Text('Eliminar Definitivamente'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executePurge(String phrase) async {
    setState(() => _isPurging = true);
    try {
      if (widget.onPurgeAccount != null) {
        await widget.onPurgeAccount!(phrase);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: Key('purge_success_snackbar'),
            content: Text('Cuenta y datos eliminados irreversiblemente.'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final tokens = CoraTheme.tokensOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('purge_error_snackbar'),
            content: Text('Error al procesar purga: $e'),
            backgroundColor: tokens.alertUrgent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidad y Soberanía'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Seguridad y Acceso', Icons.lock_outline),
          CoraSurfaceCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('biometric_switch'),
                    title: const Text('Bloqueo Biométrico'),
                    subtitle: const Text(
                        'Solicitar huella o rostro para acceder a Cora'),
                    value: _biometricEnabled,
                    onChanged: (val) {
                      setState(() => _biometricEnabled = val);
                      widget.biometricService.setBiometricEnabled(val);
                    },
                  ),
                  if (_biometricEnabled)
                    ListTile(
                      title: const Text('Tiempo de bloqueo'),
                      subtitle: Text(
                        _timeout == BiometricLockTimeout.immediate
                            ? 'Inmediato'
                            : '1 minuto en segundo plano',
                      ),
                      trailing: DropdownButton<BiometricLockTimeout>(
                        key: const Key('timeout_dropdown'),
                        value: _timeout,
                        items: const [
                          DropdownMenuItem(
                            value: BiometricLockTimeout.immediate,
                            child: Text('Inmediato'),
                          ),
                          DropdownMenuItem(
                            value: BiometricLockTimeout.oneMinute,
                            child: Text('1 minuto'),
                          ),
                        ],
                        onChanged: (newVal) {
                          if (newVal != null) {
                            setState(() => _timeout = newVal);
                            widget.biometricService.setTimeout(newVal);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Modo Discreto', Icons.visibility_off_outlined),
          CoraSurfaceCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  // ignore: deprecated_member_use
                  RadioListTile<DiscreetAppIcon>(
                    key: const Key('radio_icon_default'),
                    title: const Text('Cora Original'),
                    subtitle:
                        const Text('Ícono y nombre estándar de la aplicación'),
                    value: DiscreetAppIcon.coraDefault,
                    // ignore: deprecated_member_use
                    groupValue: _currentIcon,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) {
                        widget.iconService.switchIcon(val);
                        setState(() => _currentIcon = val);
                      }
                    },
                  ),
                  // ignore: deprecated_member_use
                  RadioListTile<DiscreetAppIcon>(
                    key: const Key('radio_icon_calendar'),
                    title: const Text('Mi Calendario'),
                    subtitle:
                        const Text('Ícono discreto de calendario personal'),
                    value: DiscreetAppIcon.neutralCalendar,
                    // ignore: deprecated_member_use
                    groupValue: _currentIcon,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) {
                        widget.iconService.switchIcon(val);
                        setState(() => _currentIcon = val);
                      }
                    },
                  ),
                  // ignore: deprecated_member_use
                  RadioListTile<DiscreetAppIcon>(
                    key: const Key('radio_icon_notes'),
                    title: const Text('Notas'),
                    subtitle: const Text(
                        'Ícono de libreta discreta para mayor privacidad'),
                    value: DiscreetAppIcon.neutralNotes,
                    // ignore: deprecated_member_use
                    groupValue: _currentIcon,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) {
                        widget.iconService.switchIcon(val);
                        setState(() => _currentIcon = val);
                      }
                    },
                  ),
                  // ignore: deprecated_member_use
                  RadioListTile<DiscreetAppIcon>(
                    key: const Key('radio_icon_calculator'),
                    title: const Text('Calculadora'),
                    subtitle: const Text('Ícono de utilería neutra'),
                    value: DiscreetAppIcon.pocketCalculator,
                    // ignore: deprecated_member_use
                    groupValue: _currentIcon,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) {
                        widget.iconService.switchIcon(val);
                        setState(() => _currentIcon = val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(
              'Soberanía y Portabilidad (GDPR)', Icons.download_outlined),
          CoraSurfaceCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                leading:
                    Icon(Icons.folder_zip_outlined, color: tokens.follicular),
                title: const Text('Exportar Todos mis Datos'),
                subtitle: const Text(
                    'Descarga una copia completa en ZIP con archivos JSON legibles.'),
                trailing: _isExporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : ElevatedButton(
                        key: const Key('export_data_button'),
                        onPressed: _handleExportData,
                        child: const Text('Exportar'),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          if (widget.onSignOut != null) ...[
            CoraSurfaceCard(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  key: const Key('sign_out_tile'),
                  leading: Icon(Icons.logout, color: tokens.textSecondary),
                  title: const Text('Cerrar Sesión'),
                  subtitle: const Text(
                      'Desconecta tu sesión de Firebase en este dispositivo'),
                  onTap: () async {
                    await widget.onSignOut!();
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          _buildSectionHeader('Zona de Peligro', Icons.delete_forever,
              color: tokens.alertUrgent),
          CoraSurfaceCard(
            backgroundColor: tokens.alertUrgentSurface,
            borderColor: tokens.alertUrgent.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eliminación Definitiva de Cuenta',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: tokens.alertUrgent),
                ),
                const SizedBox(height: 8),
                Text(
                  'Purga irreversible de todos tus registros médicos, archivos y cuenta en nuestros servidores y en este dispositivo. No hay recuperación posible.',
                  style: TextStyle(fontSize: 13, color: tokens.textPrimary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  key: const Key('open_purge_dialog_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.alertUrgent,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Eliminar Mi Cuenta Cora'),
                  onPressed: _isPurging ? null : _showPurgeConfirmationDialog,
                ),
              ],
            ),
          ),
          SizedBox(height: 48 + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color? color}) {
    final tokens = CoraTheme.tokensOf(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? tokens.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color ?? tokens.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
