import 'package:flutter/material.dart';

/// Widget pour l'état vide de la liste des propriétés.
class PropertyListEmptyState extends StatelessWidget {
  const PropertyListEmptyState({
    super.key,
    required this.isEmpty,
    required this.onResetFilters,
  });

  final bool isEmpty;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isEmpty ? Icons.home_outlined : Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            isEmpty ? 'Aucune propriété enregistrée' : 'Aucun résultat trouvé',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!isEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onResetFilters,
              child: const Text('Réinitialiser les filtres'),
            ),
          ],
        ],
      ),
    );
  }
}
