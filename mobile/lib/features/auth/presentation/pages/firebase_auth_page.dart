import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/auth/auth_providers.dart';
import 'package:mobile/core/auth/firebase_auth_service.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
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
        final tokens = CoraTheme.tokensOf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Te enviamos un correo para restablecer tu contraseña.',
            ),
            backgroundColor: tokens.ovulatory,
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
    final tokens = CoraTheme.tokensOf(context);
    return Scaffold(
      backgroundColor: tokens.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: tokens.accentSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: tokens.borderSubtle),
                        ),
                        child: Icon(
                          Icons.spa_outlined,
                          size: 32,
                          color: tokens.primaryDeep,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'PLATAFORMA GINECOLÓGICA & ENDOCRINA',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tokens.verified,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cora',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isRegisterMode
                          ? 'Crea tu cuenta protegida para acompañar tu salud en cada etapa.'
                          : 'Salud hormonal y reproductiva con rigor clínico y respeto absoluto por tus ritmos biológicos.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) ...[
                      KeyedSubtree(
                        key: const Key('auth_error_banner'),
                        child: CoraAlertBanner(
                          title: 'No fue posible autenticar',
                          description: _errorMessage!,
                          isUrgent: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    CoraSurfaceCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: const Key('auth_email_input'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email_outlined),
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
                          CoraPrimaryActionButton(
                            key: const Key('auth_submit_button'),
                            label: _isRegisterMode
                                ? 'Crear mi Cuenta Cora'
                                : 'Iniciar Sesión',
                            isLoading: _isLoading,
                            onPressed: _submit,
                          ),
                        ],
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
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      key: const Key('continue_offline_local_button'),
                      onPressed: _isLoading
                          ? null
                          : () {
                              const localUser = CoraAuthUser(
                                uid: 'cora-local-offline-user',
                                email: 'local@cora.health',
                              );
                              ref
                                  .read(localOfflineAuthUserProvider.notifier)
                                  .state = localUser;
                              widget.onAuthenticated?.call(localUser);
                            },
                      icon: const Icon(Icons.offline_bolt_outlined, size: 18),
                      label: const Text(
                        'Continuar en Modo Local (Offline-First)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    CoraSurfaceCard(
                      backgroundColor: tokens.blushInset,
                      padding: const EdgeInsets.all(16),
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: tokens.surface,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: tokens.borderSubtle),
                                ),
                                child: Icon(
                                  Icons.verified_user_outlined,
                                  size: 18,
                                  color: tokens.verified,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Compromiso de Privacidad Cora',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const CoraMintStatusPill(
                                label: 'HIPAA • GDPR',
                                variant: CoraStatusPillVariant.mint,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tus biomarcadores, sintomatología y fechas de ciclo cuentan con cifrado de extremo a extremo. Jamás se comercializan.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CoraSurfaceCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            borderRadius: 14,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _TrustMiniBadge(
                                  icon: Icons.lock_outline,
                                  label: 'Cifrado E2EE',
                                  color: tokens.verified,
                                ),
                                _TrustMiniBadge(
                                  icon: Icons.shield_outlined,
                                  label: 'Cero Rastreo',
                                  color: tokens.primaryDeep,
                                ),
                                _TrustMiniBadge(
                                  icon: Icons.medical_information_outlined,
                                  label: 'Auditoría',
                                  color: tokens.luteal,
                                ),
                              ],
                            ),
                          ),
                        ],
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

class _TrustMiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TrustMiniBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
