import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/auth/auth_providers.dart';
import 'package:mobile/core/auth/firebase_auth_service.dart';
import 'package:mobile/core/theme/cora_theme.dart';

class FirebaseAuthPage extends ConsumerStatefulWidget {
  const FirebaseAuthPage({super.key, this.onAuthenticated});

  final void Function(CoraAuthUser user)? onAuthenticated;

  @override
  ConsumerState<FirebaseAuthPage> createState() => _FirebaseAuthPageState();
}

class _FirebaseAuthPageState extends ConsumerState<FirebaseAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(coraAuthServiceProvider);
      final user = _isRegisterMode
          ? await auth.registerWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            )
          : await auth.signInWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      widget.onAuthenticated?.call(user);
    } on CoraAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.messageEs);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ocurrió un error inesperado al autenticar.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Ingresa tu correo arriba para enviarte el enlace.';
      });
      return;
    }
    try {
      await ref.read(coraAuthServiceProvider).sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Te enviamos un correo para restablecer tu contraseña.',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } on CoraAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.messageEs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 56,
                      color: CoraTheme.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cora',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: CoraTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isRegisterMode
                          ? 'Crea tu cuenta protegida para acompañar tu salud en cada etapa.'
                          : 'Inicia sesión para acceder a tu espacio clínico privado.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    if (_errorMessage != null) ...[
                      Container(
                        key: const Key('auth_error_banner'),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      key: const Key('auth_email_input'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        final v = val?.trim() ?? '';
                        if (v.isEmpty || !v.contains('@')) {
                          return 'Ingresa un correo electrónico válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('auth_password_input'),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if ((val ?? '').length < 6) {
                          return 'Mínimo 6 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      key: const Key('auth_submit_button'),
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isRegisterMode
                                  ? 'Crear mi Cuenta Cora'
                                  : 'Iniciar Sesión',
                            ),
                    ),
                    const SizedBox(height: 12),
                    if (!_isRegisterMode)
                      TextButton(
                        key: const Key('auth_reset_password_button'),
                        onPressed: _isLoading ? null : _resetPassword,
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    TextButton(
                      key: const Key('auth_toggle_mode_button'),
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                                _isRegisterMode = !_isRegisterMode;
                                _errorMessage = null;
                              }),
                      child: Text(
                        _isRegisterMode
                            ? '¿Ya tienes cuenta? Inicia sesión'
                            : '¿Primera vez en Cora? Crear cuenta',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
