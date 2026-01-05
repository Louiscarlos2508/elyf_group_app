import 'package:flutter/material.dart';

import '../../../domain/entities/agent.dart';

/// Filtre par statut des agents.
class AgentsStatusFilter extends StatelessWidget {
  const AgentsStatusFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AgentStatus? value;
  final ValueChanged<AgentStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210.586,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 1.219),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent, width: 1.219),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AgentStatus?>(
          value: value,
          hint: const Text(
            'Tous les statuts',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF0A0A0A),
            ),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF0A0A0A)),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Tous les statuts', style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A))),
            ),
            ...AgentStatus.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status.label, style: const TextStyle(fontSize: 14, color: Color(0xFF0A0A0A))),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

