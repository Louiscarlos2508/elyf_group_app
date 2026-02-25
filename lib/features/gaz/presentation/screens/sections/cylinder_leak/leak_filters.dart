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
            label: const Text('Tous'),
            selected: filterStatus == null,
            onSelected: (selected) {
              if (selected) {
                onFilterChanged(null);
              }
            },
          ),
          ...LeakStatus.values.where((s) => showExchanged || s != LeakStatus.exchanged).map((status) {
            return FilterChip(
              label: Text(status.label),
              selected: filterStatus == status,
              onSelected: (selected) {
                onFilterChanged(selected ? status : null);
              },
            );
          }),
        ],
      ),
    );
  }
}
