import 'package:flutter/material.dart';

class PartnerCompanionProjection {
  final String sharingUserName;
  final bool isLinkActive;
  final String? pregnancyMilestone;
  final String? fertilityWindowSummary;
  final String? moodAndSupportTip;

  const PartnerCompanionProjection({
    required this.sharingUserName,
    this.isLinkActive = true,
    this.pregnancyMilestone,
    this.fertilityWindowSummary,
    this.moodAndSupportTip,
  });
}

class PartnerCompanionViewPage extends StatelessWidget {
  final PartnerCompanionProjection projection;
  final VoidCallback? onRefresh;

  const PartnerCompanionViewPage({
    super.key,
    required this.projection,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAnySharedContent = projection.isLinkActive &&
        (projection.pregnancyMilestone != null ||
            projection.fertilityWindowSummary != null ||
            projection.moodAndSupportTip != null);

    return Scaffold(
      appBar: AppBar(
        title: Text('Acompañando a ${projection.sharingUserName}'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_outlined, size: 16, color: Colors.teal.shade800),
                const SizedBox(width: 4),
                Text(
                  'Solo Lectura',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          onRefresh?.call();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              color: Colors.blueGrey.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blueGrey.shade200),
              ),
              child: const Padding(
                padding: EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.blueGrey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Espacio de apoyo respetuoso. La información aquí visible es decidida en todo momento por ella.',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!projection.isLinkActive)
              _buildInactiveNotice()
            else if (!hasAnySharedContent)
              _buildEmptySharedNotice()
            else ...[
              if (projection.pregnancyMilestone != null)
                _buildCard(
                  keyPrefix: 'pregnancy_milestone',
                  icon: Icons.child_friendly_outlined,
                  iconColor: Colors.purple,
                  title: 'Hito de Embarazo',
                  content: projection.pregnancyMilestone!,
                  theme: theme,
                ),
              if (projection.fertilityWindowSummary != null)
                _buildCard(
                  keyPrefix: 'fertility_window',
                  icon: Icons.favorite_border,
                  iconColor: Colors.pink,
                  title: 'Ventana de Fertilidad y Ciclo',
                  content: projection.fertilityWindowSummary!,
                  theme: theme,
                ),
              if (projection.moodAndSupportTip != null)
                _buildCard(
                  keyPrefix: 'mood_tip',
                  icon: Icons.lightbulb_outline,
                  iconColor: Colors.amber.shade800,
                  title: 'Consejo de Apoyo y Bienestar',
                  content: projection.moodAndSupportTip!,
                  theme: theme,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInactiveNotice() {
    return Container(
      key: const Key('partner_inactive_notice'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.pause_circle_outline, size: 48, color: Colors.amber.shade800),
          const SizedBox(height: 12),
          const Text(
            'Enlace en pausa o revocado',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'El acceso compartido no se encuentra activo actualmente. Conversa con tu compañera si necesitas reactivar el vínculo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySharedNotice() {
    return Container(
      key: const Key('partner_empty_shared_notice'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_clock_outlined, size: 48, color: Colors.grey.shade600),
          const SizedBox(height: 12),
          const Text(
            'Sin información compartida por ahora',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu compañera aún no ha activado ámbitos de información para compartir. Recuerda que la privacidad de su salud siempre es su prioridad.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String keyPrefix,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required ThemeData theme,
  }) {
    return Card(
      key: Key('card_$keyPrefix'),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withValues(alpha: 0.15),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              content,
              key: Key('content_$keyPrefix'),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
