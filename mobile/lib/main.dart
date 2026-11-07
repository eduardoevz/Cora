import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/cora_theme.dart';

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
    return MaterialApp(
      title: 'Cora',
      debugShowCheckedModeBanner: false,
      theme: CoraTheme.standard(),
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'Cora — Cuidado Integral de la Salud Femenina',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
