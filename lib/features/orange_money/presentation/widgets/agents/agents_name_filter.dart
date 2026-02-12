import 'package:flutter/material.dart';

/// Filtre par nom des agents.
class AgentsNameFilter extends StatelessWidget {
  const AgentsNameFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 44,
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
        child: DropdownButton<String?>(
          value: value,
          hint: Text(
            'Trier par',
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
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text('Défaut'),
            ),
            DropdownMenuItem(
              value: 'name',
              child: Text('Nom (A-Z)'),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
