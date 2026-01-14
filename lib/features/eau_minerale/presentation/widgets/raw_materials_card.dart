import 'package:flutter/material.dart';

import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/packaging_stock.dart';
import '../../domain/entities/stock_item.dart';

/// Card displaying raw materials stock summary (including bobines and packaging).
class RawMaterialsCard extends StatelessWidget {
  const RawMaterialsCard({
    super.key,
    required this.items,
    required this.availableBobines,
    required this.bobineStocks,
    required this.packagingStocks,
  });

  final List<StockItem> items;
  final int availableBobines; // Total pour compatibilité
  final List<BobineStock> bobineStocks; // Stocks de bobines par type
  final List<PackagingStock> packagingStocks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter raw materials (excluding sachets which are managed as bobines, and bidons which are packaging)
    final rawMaterials = items
        .where(
          (item) =>
              item.type == StockType.rawMaterial &&
              !item.name.toLowerCase().contains('sachet') &&
              !item.name.toLowerCase().contains('bidon'),
        )
        .toList();

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
          // Afficher les bobines par type (comme les emballages)
          if (bobineStocks.isNotEmpty) ...[
            ...bobineStocks.map((stock) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPackagingItem(
                  context,
                  stock.type,
                  'Géré automatiquement • Déduit lors des installations en production',
                  stock.quantity.toDouble(),
                  stock.unit,
                  stock.estStockFaible,
                  stock.seuilAlerte,
                ),
              );
            }),
          ] else if (availableBobines > 0) ...[
            // Fallback si bobineStocks est vide mais availableBobines > 0
            _buildMaterialItem(
              context,
              'Bobines',
              'Gérées depuis le stock • Sorties lors des installations en production',
              availableBobines.toDouble(),
              'unité',
            ),
          ],
          // Afficher les emballages (un seul type: "Emballage")
          if (packagingStocks.isNotEmpty) ...[
            const SizedBox(height: 16),
            // Calculer la quantité totale de tous les emballages
            _buildPackagingItem(
              context,
              'Emballage',
              'Géré automatiquement • Déduit lors des productions',
              packagingStocks.fold<double>(
                0.0,
                (sum, stock) => sum + stock.quantity.toDouble(),
              ),
              'unité',
              packagingStocks.any((stock) => stock.estStockFaible),
              packagingStocks.isNotEmpty
                  ? packagingStocks.first.seuilAlerte
                  : null,
            ),
          ],
          // Afficher les autres matières premières
          if (rawMaterials.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...rawMaterials.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildMaterialItem(
                  context,
                  item.name,
                  'Géré manuellement • Utilisé en production',
                  item.quantity,
                  item.unit,
                ),
              );
            }),
          ],
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

  Widget _buildPackagingItem(
    BuildContext context,
    String name,
    String description,
    double quantity,
    String unit,
    bool isLowStock,
    int? seuilAlerte,
  ) {
    final theme = Theme.of(context);
    final color = isLowStock ? Colors.red : Colors.orange.shade800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isLowStock) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'FAIBLE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (seuilAlerte != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Seuil d\'alerte: $seuilAlerte $unit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '${quantity.toStringAsFixed(0)} $unit',
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
