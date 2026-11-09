import 'package:flutter/material.dart';
import 'package:mobile/features/adolescence/presentation/widgets/teen_privacy_pin_gate.dart';

class FirstPeriodAndBodyGuidePage extends StatelessWidget {
  const FirstPeriodAndBodyGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Primer Periodo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner motivacional
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.favorite_outline, color: Colors.white, size: 36),
                const SizedBox(height: 12),
                const Text(
                  '¡Bienvenida a esta nueva etapa!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu cuerpo está madurando a su propio ritmo. Tener preguntas '
                  'o dudas es completamente normal y aquí estamos para acompañarte.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. Variabilidad Normal
          _buildInfoCard(
            context,
            icon: Icons.calendar_month_outlined,
            iconColor: const Color(0xFF0EA5E9),
            title: '¿Por qué mis ciclos no son exactamente de 28 días?',
            content:
                'Durante los primeros 1 a 3 años después de tu primera menstruación '
                '(menarquia), tus ovarios y tu cerebro están calibrando su comunicación '
                'hormonal. Por eso, ciclos de entre 21 y 45 días son completamente '
                'normales y saludables para ti.',
          ),
          const SizedBox(height: 12),

          // 2. Productos y Cuidado
          _buildInfoCard(
            context,
            icon: Icons.clean_hands_outlined,
            iconColor: const Color(0xFF10B981),
            title: 'Higiene y Productos Menstruales',
            content:
                '• Toallas sanitarias: Cámbialas cada 4 a 6 horas.\n'
                '• Calzones menstruales: Cómodos y reutilizables.\n'
                '• Hidratación: Bebe suficiente agua para reducir cólicos.\n'
                '• Descanso: Dormir bien alivia la fatiga física.',
          ),
          const SizedBox(height: 12),

          // 3. Mitos vs Hechos
          _buildInfoCard(
            context,
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFFF59E0B),
            title: 'Mitos Frecuentes',
            content:
                '❌ Mito: No puedes bañarte ni hacer ejercicio con tu periodo.\n'
                '✅ Realidad: El ejercicio suave alivia los cólicos y el baño tibio relaja tus músculos.\n\n'
                '❌ Mito: Si no te baja exactamente cada mes estás enferma.\n'
                '✅ Realidad: En la adolescencia la variación es biológicamente natural.',
          ),
          const SizedBox(height: 24),

          // Acceso a PIN de Privacidad
          Card(
            color: const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.lock_outline, color: Color(0xFF475569)),
              title: const Text('Bloqueo con PIN de Privacidad'),
              subtitle: const Text('Protege tu diario íntimo y ciclo con un código secreto.'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TeenPrivacyPinGate(
                      onSuccess: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Acceso privado desbloqueado.'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF334155),
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
