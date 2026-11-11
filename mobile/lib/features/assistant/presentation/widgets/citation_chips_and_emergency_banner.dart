import 'package:flutter/material.dart';
import 'package:mobile/features/assistant/domain/models/assistant_models.dart';

class CitationChips extends StatelessWidget {
  const CitationChips({
    super.key,
    required this.citations,
    this.onCitationTap,
  });

  final List<ClinicalCitation> citations;
  final void Function(ClinicalCitation citation)? onCitationTap;

  @override
  Widget build(BuildContext context) {
    if (citations.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: citations.map((citation) {
          return ActionChip(
            key: Key('citation_chip_${citation.articleSlug}'),
            avatar: const Icon(Icons.menu_book_outlined, size: 16),
            label: Text(
              '${citation.scientificSource} — ${citation.sectionHeading}',
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: onCitationTap == null
                ? null
                : () => onCitationTap!(citation),
          );
        }).toList(),
      ),
    );
  }
}

class EmergencyDirectiveBanner extends StatelessWidget {
  const EmergencyDirectiveBanner({
    super.key,
    required this.triageCategory,
    required this.directiveMarkdown,
    this.onEmergencyCallPressed,
  });

  final String triageCategory;
  final String directiveMarkdown;
  final VoidCallback? onEmergencyCallPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('emergency_directive_banner'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade700, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency_outlined, color: Colors.red.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Atención Médica Urgente Prioritaria',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            directiveMarkdown,
            style: TextStyle(color: Colors.red.shade900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              FilledButton.icon(
                key: const Key('emergency_call_911_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                onPressed: onEmergencyCallPressed ?? () {},
                icon: const Icon(Icons.phone_in_talk),
                label: const Text('Llamar a Emergencias (911 / 988)'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
