import 'package:flutter/material.dart';

import '../../../../domain/entities/cylinder_leak.dart';

/// Filtres pour les fuites.
class LeakFilters extends StatelessWidget {
  const LeakFilters({
    super.key,
    required this.filterStatus,
    required this.onFilterChanged,
    this.showExchanged = true,
  });

  final LeakStatus? filterStatus;
  final ValueChanged<LeakStatus?> onFilterChanged;
  final bool showExchanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(
            label: const Text('Toutes les fuites'),
            selected: true,
            onSelected: (_) {}, // Statut unique "convertie en vide" désormais
          ),
        ],
      ),
    );
  }
}
