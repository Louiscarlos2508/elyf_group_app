import 'package:flutter/material.dart';

/// En-tête de la section personnel avec bouton d'ajout.
class PersonnelHeader extends StatelessWidget {
  const PersonnelHeader({super.key, required this.onAddDay});

  final VoidCallback? onAddDay;

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
                'Personnel et production journalière',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enregistrez le personnel et la production pour chaque jour',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IntrinsicWidth(
          child: FilledButton.icon(
            onPressed: onAddDay,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter jour'),
          ),
        ),
      ],
    );
  }
}
