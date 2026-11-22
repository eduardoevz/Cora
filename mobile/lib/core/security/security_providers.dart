import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/security/biometric_lock_service.dart';
import 'package:mobile/core/security/discreet_app_icon_service.dart';

final biometricLockServiceProvider = Provider<BiometricLockService>((ref) {
  return BiometricLockService();
});

final discreetAppIconServiceProvider =
    ChangeNotifierProvider<DiscreetAppIconService>((ref) {
  return DiscreetAppIconService();
});
