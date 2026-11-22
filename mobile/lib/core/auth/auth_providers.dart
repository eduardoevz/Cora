import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/auth/firebase_auth_service.dart';

final coraAuthServiceProvider = Provider<ICoraAuthService>((ref) {
  return FirebaseCoraAuthService.instance;
});

final coraAuthStateProvider = StreamProvider<CoraAuthUser?>((ref) {
  final authService = ref.watch(coraAuthServiceProvider);
  return authService.authStateChanges();
});
