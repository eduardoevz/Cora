import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/cora_api_client.dart';
import 'package:mobile/core/security/privacy_lifecycle_gate.dart';
import 'package:mobile/core/security/security_providers.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/dashboard/presentation/pages/dynamic_home_dashboard_page.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/pages/onboarding_wizard_page.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  @override
  void initState() {
    super.initState();
    _bootstrapProfile();
  }

  Future<void> _bootstrapProfile() async {
    try {
      final profile =
          await ref.read(identityRepositoryProvider).getActiveProfile();
      if (profile != null) {
        ref
            .read(coraApiClientProvider)
            .setAuthToken('mock-token:${profile.firebaseUid}');
        ref.read(activeUserProfileProvider.notifier).state = profile;
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
    if (_isBootstrapping) {
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
}
