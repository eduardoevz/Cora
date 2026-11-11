import 'package:flutter/material.dart';
import 'package:mobile/core/security/biometric_lock_service.dart';

class PrivacyLifecycleGate extends StatefulWidget {
  const PrivacyLifecycleGate({
    super.key,
    required this.child,
    required this.lockService,
  });

  final Widget child;
  final BiometricLockService lockService;

  @override
  State<PrivacyLifecycleGate> createState() => _PrivacyLifecycleGateState();
}

class _PrivacyLifecycleGateState extends State<PrivacyLifecycleGate>
    with WidgetsBindingObserver {
  bool _showPrivacyShield = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      widget.lockService.recordAppPaused();
      setState(() {
        _showPrivacyShield = true;
      });
    } else if (state == AppLifecycleState.resumed) {
      final requiresAuth =
          widget.lockService.checkRequiresAuthenticationOnResume();
      if (!requiresAuth) {
        setState(() {
          _showPrivacyShield = false;
        });
      }
    }
  }

  Future<void> _handleUnlock() async {
    final success = await widget.lockService.authenticateMock(success: true);
    if (success && mounted) {
      setState(() {
        _showPrivacyShield = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showPrivacyShield)
          Positioned.fill(
            key: const Key('privacy_shield_overlay'),
            child: Material(
              color: Colors.white,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 72,
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Cora — Privacidad Protegida',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tus datos de salud están resguardados.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          key: const Key('privacy_shield_unlock_button'),
                          onPressed: _handleUnlock,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Desbloquear con Biometría / PIN'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
