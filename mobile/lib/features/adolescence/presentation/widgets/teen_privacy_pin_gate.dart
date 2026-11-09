import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

class TeenPrivacyPinGate extends StatefulWidget {
  final VoidCallback onSuccess;
  final String? initialHashedPin;
  final String salt;

  const TeenPrivacyPinGate({
    super.key,
    required this.onSuccess,
    this.initialHashedPin,
    this.salt = 'cora_teen_salt_2026',
  });

  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt$pin$salt');
    return sha256.convert(bytes).toString();
  }

  @override
  State<TeenPrivacyPinGate> createState() => TeenPrivacyPinGateState();
}

class TeenPrivacyPinGateState extends State<TeenPrivacyPinGate> {
  String _enteredPin = '';
  late String _storedHashedPin;
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutSecondsRemaining = 0;
  Timer? _lockoutTimer;
  String? _errorMessage;

  int get failedAttempts => _failedAttempts;
  bool get isLockedOut => _isLockedOut;
  int get lockoutSecondsRemaining => _lockoutSecondsRemaining;

  @override
  void initState() {
    super.initState();
    _storedHashedPin = widget.initialHashedPin ??
        TeenPrivacyPinGate.hashPin('1234', widget.salt);
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void onDigitPressed(String digit) {
    if (_isLockedOut || _enteredPin.length >= 4) return;

    setState(() {
      _errorMessage = null;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void onDeletePressed() {
    if (_isLockedOut || _enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  void _verifyPin() {
    final hashed = TeenPrivacyPinGate.hashPin(_enteredPin, widget.salt);
    if (hashed == _storedHashedPin) {
      setState(() {
        _failedAttempts = 0;
        _errorMessage = null;
      });
      widget.onSuccess();
    } else {
      final newFailures = _failedAttempts + 1;
      if (newFailures >= 5) {
        _triggerLockout();
      } else {
        setState(() {
          _failedAttempts = newFailures;
          _enteredPin = '';
          _errorMessage =
              'PIN incorrecto. Intentos restantes: ${5 - newFailures}';
        });
      }
    }
  }

  void _triggerLockout() {
    _lockoutTimer?.cancel();
    setState(() {
      _failedAttempts = 5;
      _isLockedOut = true;
      _lockoutSecondsRemaining = 30;
      _enteredPin = '';
      _errorMessage = 'Demasiados intentos fallidos. Bloqueado temporalmente.';
    });

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_lockoutSecondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _isLockedOut = false;
          _lockoutSecondsRemaining = 0;
          _failedAttempts = 0;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _lockoutSecondsRemaining--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PIN de Privacidad'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.shield_outlined,
                  size: 56, color: Color(0xFF6366F1)),
              const SizedBox(height: 16),
              Text(
                _isLockedOut
                    ? 'Acceso Bloqueado'
                    : 'Ingresa tu PIN de 4 dígitos',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_isLockedOut)
                Text(
                  'Espera $_lockoutSecondsRemaining segundos para reintentar',
                  key: const Key('lockout_countdown_text'),
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              else
                Text(
                  'Tu privacidad clínica está protegida con cifrado local',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
              const SizedBox(height: 20),
              // Indicador de 4 dígitos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFE2E8F0),
                      border: Border.all(
                        color: const Color(0xFF6366F1),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMessage!,
                    key: const Key('pin_error_text'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // Teclado numérico
              _buildKeypad(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['1', '2', '3'].map(_buildKey).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['4', '5', '6'].map(_buildKey).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['7', '8', '9'].map(_buildKey).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 72, height: 72),
              _buildKey('0'),
              SizedBox(
                width: 72,
                height: 72,
                child: IconButton(
                  key: const Key('delete_key'),
                  onPressed: _isLockedOut ? null : onDeletePressed,
                  icon: const Icon(Icons.backspace_outlined),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String digit) {
    return SizedBox(
      width: 72,
      height: 72,
      child: OutlinedButton(
        key: Key('pin_key_$digit'),
        onPressed: _isLockedOut ? null : () => onDigitPressed(digit),
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
