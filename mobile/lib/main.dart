import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/auth/auth_providers.dart';
import 'package:mobile/core/auth/firebase_auth_service.dart';
import 'package:mobile/core/security/privacy_lifecycle_gate.dart';
import 'package:mobile/core/security/security_providers.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/auth/presentation/pages/firebase_auth_page.dart';
import 'package:mobile/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/pages/onboarding_wizard_page.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseCoraAuthService.instance.initialize();
  runApp(
    const ProviderScope(
      child: CoraApp(),
    ),
  );
}

class CoraApp extends ConsumerWidget {
  const CoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStage = ref.watch(currentLifeStageProvider);
    final activeTheme = currentStage == LifeStage.seniorVitality
        ? CoraTheme.highLegibility()
        : CoraTheme.standard();

    return MaterialApp(
      title: 'Cora',
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      home: const CoraRootGate(),
    );
  }
}

class CoraRootGate extends ConsumerStatefulWidget {
  const CoraRootGate({super.key});

  @override
  ConsumerState<CoraRootGate> createState() => _CoraRootGateState();
}

class _CoraRootGateState extends ConsumerState<CoraRootGate> {
  bool _isBootstrapping = true;
  String? _bootstrappedUid;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(discreetAppIconServiceProvider).syncFromNative());
    final auth = ref.read(coraAuthServiceProvider);
    if (!auth.isFirebaseReady) {
      _bootstrapProfile();
    } else if (auth.currentUser != null) {
      _bootstrapProfile(expectedUid: auth.currentUser!.uid);
    } else {
      _isBootstrapping = false;
    }
  }

  Future<void> _bootstrapProfile({String? expectedUid}) async {
    if (!mounted) return;
    setState(() {
      _isBootstrapping = true;
      _bootstrappedUid = expectedUid;
    });
    try {
      final profile =
          await ref.read(identityRepositoryProvider).getActiveProfile();
      if (profile != null &&
          (expectedUid == null || profile.firebaseUid == expectedUid)) {
        ref.read(activeUserProfileProvider.notifier).state = profile;
      } else {
        ref.read(activeUserProfileProvider.notifier).state = null;
      }
    } catch (_) {
      // Allow clean start on onboarding if local database fails to read profile
    } finally {
      if (mounted) {
        setState(() {
          _isBootstrapping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: _buildRootContent(context),
    );
  }

  Widget _buildRootContent(BuildContext context) {
    final authService = ref.watch(coraAuthServiceProvider);
    final localOfflineUser = ref.watch(localOfflineAuthUserProvider);

    if (authService.isFirebaseReady) {
      final authState = ref.watch(coraAuthStateProvider);
      final authUser = localOfflineUser ??
          authState.asData?.value ??
          authService.currentUser;

      if (authUser == null) {
        _bootstrappedUid = null;
        return FirebaseAuthPage(
          onAuthenticated: (user) => _bootstrapProfile(expectedUid: user.uid),
        );
      }

      if (_bootstrappedUid != authUser.uid && !_isBootstrapping) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _bootstrapProfile(expectedUid: authUser.uid);
          }
        });
      }
    }

    if (_isBootstrapping) {
      return _buildLoadingScreen();
    }

    final activeProfile = ref.watch(activeUserProfileProvider);
    if (activeProfile == null || !activeProfile.onboardingCompleted) {
      return const OnboardingWizardPage();
    }

    final lockService = ref.watch(biometricLockServiceProvider);
    return PrivacyLifecycleGate(
      lockService: lockService,
      child: const DynamicHomeDashboardPage(),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 56,
                color: CoraTheme.primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'Cora',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CoraTheme.primaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Cuidado Integral de la Salud Femenina',
                style: TextStyle(fontSize: 15),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
