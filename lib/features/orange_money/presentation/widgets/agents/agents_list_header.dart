import 'package:flutter/material.dart';

/// En-tête de la liste des agents avec boutons d'action.
class AgentsListHeader extends StatelessWidget {
  const AgentsListHeader({
    super.key,
    required this.agentCount,
    required this.onAddAgent,
    required this.onRecharge,
    this.title = 'Liste des agents',
    this.addButtonLabel = 'Nouvel agent',
  });

  final int agentCount;
  final String title;
  final String addButtonLabel;
  final void Function() onAddAgent;
  final void Function() onRecharge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '$title ($agentCount)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: onAddAgent,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(addButtonLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: onRecharge,
                icon: const Icon(Icons.swap_vert_rounded, size: 18),
                label: const Text('Recharge / Retrait'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C897), // Success green
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
