import 'package:flutter/material.dart';

import '../../../../domain/entities/point_of_sale.dart';

/// En-tête de la carte de stock d'un point de vente.
class PosStockHeader extends StatelessWidget {
  const PosStockHeader({
    super.key,
    required this.pointOfSale,
  });

  final PointOfSale pointOfSale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.store,
                  size: 20,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pointOfSale.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pointOfSale.address,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF6A7282),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📞 ${pointOfSale.contact}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF99A1AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF030213),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Actif',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

