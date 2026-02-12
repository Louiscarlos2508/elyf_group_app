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
    final theme = Theme.of(context);
    
    return Container(
      height: 44, // Taller for better touch
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AgentStatus?>(
          value: value,
          hint: Text(
            'Tous les statuts',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: 'Outfit',
            ),
          ),
          isExpanded: false,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Tous les statuts',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
            ...AgentStatus.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(
                  status.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Outfit',
                  ),
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
