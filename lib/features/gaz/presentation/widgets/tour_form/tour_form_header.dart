import 'package:flutter/material.dart';

/// En-tête du formulaire de tour.
class TourFormHeader extends StatelessWidget {
  const TourFormHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouveau tour d\'approvisionnement',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Créez un nouveau cycle de collecte et rechargement',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF717182),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
