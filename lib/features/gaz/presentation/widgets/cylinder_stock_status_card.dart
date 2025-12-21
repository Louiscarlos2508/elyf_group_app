import 'package:flutter/material.dart';

import '../../domain/entities/cylinder.dart';

/// Carte affichant le stock par statut pour un format donné.
class CylinderStockStatusCard extends StatelessWidget {
  const CylinderStockStatusCard({
    super.key,
    required this.weight,
    required this.fullQuantity,
    required this.emptyAtStoreQuantity,
    required this.emptyInTransitQuantity,
    required this.defectiveQuantity,
    required this.leakQuantity,
  });

  final int weight;
  final int fullQuantity;
  final int emptyAtStoreQuantity;
  final int emptyInTransitQuantity;
  final int defectiveQuantity;
  final int leakQuantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${weight}kg',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _StatusRow(
              label: CylinderStatus.full.label,
              quantity: fullQuantity,
              color: Colors.green,
            ),
            _StatusRow(
              label: CylinderStatus.emptyAtStore.label,
              quantity: emptyAtStoreQuantity,
              color: Colors.orange,
            ),
            _StatusRow(
              label: CylinderStatus.emptyInTransit.label,
              quantity: emptyInTransitQuantity,
              color: Colors.blue,
            ),
            _StatusRow(
              label: CylinderStatus.defective.label,
              quantity: defectiveQuantity,
              color: Colors.red,
            ),
            _StatusRow(
              label: CylinderStatus.leak.label,
              quantity: leakQuantity,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.quantity,
    required this.color,
  });

  final String label;
  final int quantity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$quantity',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}