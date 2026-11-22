import 'package:flutter/material.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/adolescence/presentation/widgets/teen_privacy_pin_gate.dart';

class FirstPeriodAndBodyGuidePage extends StatelessWidget {
  const FirstPeriodAndBodyGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        title: const Text('Mi Primer Periodo'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              CoraMintStatusPill(
                label: 'Espacio protegido • Modo Juvenil Seguro',
                icon: Icons.shield_outlined,
                variant: CoraStatusPillVariant.softMint,
              ),
              CoraMintStatusPill(
                label: 'Clínicamente revisado',
                variant: CoraStatusPillVariant.blush,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const CoraStitchPageHeader(
            eyebrow: 'ACOMPAÑAMIENTO BIOLÓGICO',
            title: 'Bienvenida a esta nueva etapa',
            subtitle:
                'Tu cuerpo está madurando a su propio ritmo. Tener preguntas o dudas es completamente normal y aquí estamos para acompañarte.',
            eyebrowIcon: Icons.favorite_outline_rounded,
          ),
          const SizedBox(height: 14),
          CoraSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Qué es normal en tus primeros ciclos?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    CoraBlushInsetBox(
                      backgroundColor: tokens.verifiedSurface,
                      borderColor: tokens.verified.withValues(alpha: 0.25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fisiológico / Sano',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: tokens.verified,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ciclos de 21 a 45 días en los primeros 3 años.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: tokens.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    CoraBlushInsetBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Motivo de consulta',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: tokens.primaryDeep,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sangrado > 8 días o dolor que impide ir a clases.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: tokens.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            icon: Icons.calendar_month_outlined,
            phaseKey: 'ovulatory',
            title: '¿Por qué mis ciclos no son exactamente de 28 días?',
            content:
                'Durante los primeros 1 a 3 años después de tu primera menstruación '
                '(menarquia), tus ovarios y tu cerebro están calibrando su comunicación '
                'hormonal. Por eso, ciclos de entre 21 y 45 días son completamente '
                'normales y saludables para ti.',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            icon: Icons.clean_hands_outlined,
            phaseKey: 'follicular',
            title: 'Higiene y Productos Menstruales',
            content: '• Toallas sanitarias: Cámbialas cada 4 a 6 horas.\n'
                '• Calzones menstruales: Cómodos y reutilizables.\n'
                '• Hidratación: Bebe suficiente agua para reducir cólicos.\n'
                '• Descanso: Dormir bien alivia la fatiga física.',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            icon: Icons.check_circle_outline,
            phaseKey: 'luteal',
            title: 'Mitos Frecuentes',
            content:
                'Mito: No puedes bañarte ni hacer ejercicio con tu periodo.\n'
                'Realidad: El ejercicio suave alivia los cólicos y el baño tibio relaja tus músculos.\n\n'
                'Mito: Si no te baja exactamente cada mes estás enferma.\n'
                'Realidad: En la adolescencia la variación es biológicamente natural.',
          ),
          const SizedBox(height: 20),
          CoraSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TeenPrivacyPinGate(
                    onSuccess: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Acceso privado desbloqueado.'),
                          backgroundColor: tokens.ovulatory,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tokens.accentSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: tokens.accentPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bloqueo con PIN de Privacidad',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'Protege tu diario íntimo y ciclo con un código secreto.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: tokens.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String phaseKey,
    required String title,
    required String content,
  }) {
    final tokens = CoraTheme.tokensOf(context);
    final pair = tokens.phaseColors(phaseKey);
    return CoraSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: pair.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: pair.border),
                ),
                child: Icon(icon, color: pair.foreground, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}
