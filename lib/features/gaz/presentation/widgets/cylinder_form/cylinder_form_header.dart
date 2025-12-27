import 'package:flutter/material.dart';

/// En-tête du formulaire de bouteille.
class CylinderFormHeader extends StatelessWidget {
  const CylinderFormHeader({
    super.key,
    required this.isEditing,
  });

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            isEditing ? 'Modifier la Bouteille' : 'Nouvelle Bouteille',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

