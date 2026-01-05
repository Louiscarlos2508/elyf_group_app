import 'package:flutter/material.dart';

/// Bouton de tri pour les agents.
class AgentsSortButton extends StatelessWidget {
  const AgentsSortButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.swap_vert, size: 16, color: Color(0xFF0A0A0A)),
        label: const Text(
          'Croissant',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF0A0A0A),
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

