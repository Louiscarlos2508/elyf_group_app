import 'package:flutter/material.dart';

/// En-tête de l'écran des agents.
class AgentsHeader extends StatelessWidget {
  const AgentsHeader({
    super.key,
    this.onHistoryPressed,
  });

  final VoidCallback? onHistoryPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '👥 Agents Affiliés',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFFF54900),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Gérez vos agents affiliés et leurs transactions de recharge',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF4A5565),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: onHistoryPressed,
          icon: const Icon(Icons.history, size: 16),
          label: const Text(
            'Historique global',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF0A0A0A),
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 36),
            side: BorderSide(
              color: Colors.black.withValues(alpha: 0.1),
              width: 1.219,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

