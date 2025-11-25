import 'package:flutter/material.dart';

import '../../domain/entities/stock_item.dart';

/// Card displaying raw materials stock summary.
class RawMaterialsCard extends StatelessWidget {
  const RawMaterialsCard({
    super.key,
    required this.items,
  });

  final List<StockItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Filter raw materials
    final rawMaterials = items
        .where((item) => item.type == StockType.rawMaterial)
        .toList();
    
    // Find specific items
    StockItem sachets = rawMaterials.firstWhere(
      (item) => item.name.toLowerCase().contains('sachet'),
      orElse: () => StockItem(
        id: 'sachets',
        name: 'Sachets',
        quantity: 0,
        unit: 'kg',
        type: StockType.rawMaterial,
        updatedAt: DateTime.now(),
      ),
    );
    
    StockItem bidons = rawMaterials.firstWhere(
      (item) => item.name.toLowerCase().contains('bidon'),
      orElse: () => StockItem(
        id: 'bidons',
        name: 'Bidons',
        quantity: 0,
        unit: 'unité',
        type: StockType.rawMaterial,
        updatedAt: DateTime.now(),
      ),
    );
    
    // If no items found, use defaults
    if (rawMaterials.isEmpty) {
      sachets = StockItem(
        id: 'sachets',
        name: 'Sachets',
        quantity: 0,
        unit: 'kg',
        type: StockType.rawMaterial,
        updatedAt: DateTime.now(),
      );
      bidons = StockItem(
        id: 'bidons',
        name: 'Bidons',
        quantity: 0,
        unit: 'unité',
        type: StockType.rawMaterial,
        updatedAt: DateTime.now(),
      );
    } else if (rawMaterials.length == 1) {
      // If only one raw material, assign it to sachets
      sachets = rawMaterials.first;
    } else {
      // Use first two items
      sachets = rawMaterials[0];
      bidons = rawMaterials.length > 1 ? rawMaterials[1] : bidons;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Matières Premières',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMaterialItem(
            context,
            'Sachets',
            'Géré manuellement • Utilisé en production',
            sachets.quantity,
            sachets.unit,
          ),
          const SizedBox(height: 16),
          _buildMaterialItem(
            context,
            'Bidons',
            'Géré manuellement • Utilisé en production',
            bidons.quantity,
            bidons.unit,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialItem(
    BuildContext context,
    String name,
    String description,
    double quantity,
    String unit,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${quantity.toStringAsFixed(0)} $unit',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.orange.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

