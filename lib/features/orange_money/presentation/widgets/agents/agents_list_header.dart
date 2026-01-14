import 'package:flutter/material.dart';

/// En-tête de la liste des agents avec boutons d'action.
class AgentsListHeader extends StatelessWidget {
  const AgentsListHeader({
    super.key,
    required this.agentCount,
    required this.onAddAgent,
    required this.onRecharge,
  });

  final int agentCount;
  final void Function() onAddAgent;
  final void Function() onRecharge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Liste des agents ($agentCount)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF0A0A0A),
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: onAddAgent,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Nouvel agent', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF54900),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: onRecharge,
            icon: const Icon(Icons.arrow_downward, size: 16),
            label: const Text(
              'Recharge / Retrait',
              style: TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A63E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
