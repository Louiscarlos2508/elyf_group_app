import 'package:flutter/material.dart';

/// En-tête de la section personnel avec bouton d'ajout.
class PersonnelHeader extends StatelessWidget {
  const PersonnelHeader({
    super.key,
    required this.onAddDay,
    this.isReadOnly = false,
  });

  final VoidCallback? onAddDay;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isReadOnly 
                    ? 'Détail du personnel' 
                    : 'Personnel et production journalière',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isReadOnly
                    ? 'Liste du personnel ayant travaillé sur cette session'
                    : 'Enregistrez le personnel et la production pour chaque jour',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!isReadOnly) ...[
          const SizedBox(width: 16), // Espace avant le bouton
          IntrinsicWidth(
            child: FilledButton.icon(
              onPressed: onAddDay,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter jour'),
            ),
          ),
        ],
      ],
    );
  }
}
