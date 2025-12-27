import 'package:flutter/material.dart';

/// Onglet statistiques pour la vente au détail.
class RetailStatisticsTab extends StatelessWidget {
  const RetailStatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Text(
        'Statistiques - À implémenter',
        style: theme.textTheme.titleLarge,
      ),
    );
  }
}

