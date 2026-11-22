import 'package:flutter/material.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';

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
    final tokens = CoraTheme.tokensOf(context);
    final hasAnySharedContent = projection.isLinkActive &&
        (projection.pregnancyMilestone != null ||
            projection.fertilityWindowSummary != null ||
            projection.moodAndSupportTip != null);

    return Scaffold(
      appBar: AppBar(
        title: Text('Acompañando a ${projection.sharingUserName}'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: CoraMintStatusPill(
                label: 'Solo Lectura',
                icon: Icons.visibility_outlined,
                variant: CoraStatusPillVariant.softMint,
              ),
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
            const CoraInfoCallout(
              title: 'Espacio de apoyo respetuoso',
              subtitle:
                  'La información aquí visible es decidida en todo momento por ella.',
              icon: Icons.shield_outlined,
              phaseKey: 'follicular',
            ),
            const SizedBox(height: 16),
            if (!projection.isLinkActive)
              _buildInactiveNotice(tokens)
            else if (!hasAnySharedContent)
              _buildEmptySharedNotice(tokens)
            else ...[
              if (projection.pregnancyMilestone != null)
                _buildCard(
                  keyPrefix: 'pregnancy_milestone',
                  icon: Icons.child_friendly_outlined,
                  iconColor: tokens.luteal,
                  title: 'Hito de Embarazo',
                  content: projection.pregnancyMilestone!,
                  theme: theme,
                ),
              if (projection.fertilityWindowSummary != null)
                _buildCard(
                  keyPrefix: 'fertility_window',
                  icon: Icons.favorite_border,
                  iconColor: tokens.menstrual,
                  title: 'Ventana de Fertilidad y Ciclo',
                  content: projection.fertilityWindowSummary!,
                  theme: theme,
                ),
              if (projection.moodAndSupportTip != null)
                _buildCard(
                  keyPrefix: 'mood_tip',
                  icon: Icons.lightbulb_outline,
                  iconColor: tokens.ovulatory,
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

  Widget _buildInactiveNotice(CoraColorTokens tokens) {
    return CoraSurfaceCard(
      key: const Key('partner_inactive_notice'),
      backgroundColor: tokens.alertPreventiveSurface,
      borderColor: tokens.alertPreventive.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.pause_circle_outline,
              size: 48, color: tokens.alertPreventive),
          const SizedBox(height: 12),
          const Text(
            'Enlace en pausa o revocado',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'El acceso compartido no se encuentra activo actualmente. Conversa con tu compañera si necesitas reactivar el vínculo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: tokens.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySharedNotice(CoraColorTokens tokens) {
    return const CoraEmptyStateCard(
      key: Key('partner_empty_shared_notice'),
      icon: Icons.lock_clock_outlined,
      title: 'Sin información compartida por ahora',
      subtitle:
          'Tu compañera aún no ha activado ámbitos de información para compartir. Recuerda que la privacidad de su salud siempre es su prioridad.',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CoraSurfaceCard(
        key: Key('card_$keyPrefix'),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withValues(alpha: 0.14),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              content,
              key: Key('content_$keyPrefix'),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
