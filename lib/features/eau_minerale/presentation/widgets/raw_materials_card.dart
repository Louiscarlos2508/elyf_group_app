import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';

import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/packaging_stock.dart';
import '../../domain/entities/stock_item.dart';

/// Helper class pour regrouper les stocks de même type.
class _GroupedStock {
  _GroupedStock({
    required this.quantity,
    required this.isLowStock,
    this.seuilAlerte,
  });

  final int quantity;
  final bool isLowStock;
  final int? seuilAlerte;
}

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

    return ElyfCard(
      isGlass: true,
      borderColor: Colors.orange.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
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
          const SizedBox(height: 24),
          // Afficher les bobines par type
          if (bobineStocks.isNotEmpty) ...[
            ...() {
              final Map<String, _GroupedStock> groupedStocks = {};
              for (final stock in bobineStocks) {
                final existing = groupedStocks[stock.type];
                if (existing == null) {
                  groupedStocks[stock.type] = _GroupedStock(
                    quantity: stock.quantity,
                    isLowStock: stock.estStockFaible,
                    seuilAlerte: stock.seuilAlerte,
                  );
                } else {
                  groupedStocks[stock.type] = _GroupedStock(
                    quantity: existing.quantity + stock.quantity,
                    isLowStock: existing.isLowStock || stock.estStockFaible,
                    seuilAlerte: existing.seuilAlerte ?? stock.seuilAlerte,
                  );
                }
              }
              
              return groupedStocks.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildPackagingItem(
                    context,
                    entry.key,
                    'Bobines pour production • Déduction automatique',
                    entry.value.quantity.toDouble(),
                    'unité',
                    entry.value.isLowStock,
                    entry.value.seuilAlerte,
                  ),
                );
              });
            }(),
          ],
          
          // Afficher les emballages individuellement
          if (packagingStocks.isNotEmpty) ...[
            ...packagingStocks.map((stock) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildPackagingItem(
                  context,
                  stock.type, // Nom de l'emballage (ex: Préforme, Bouchon)
                  stock.unitsPerLot > 1
                      ? 'Format: ${stock.unitsPerLot} unités/lot'
                      : 'Géré à l\'unité',
                  stock.quantity.toDouble(),
                  stock.unit,
                  stock.estStockFaible,
                  stock.seuilAlerte,
                  customQuantityLabel: stock.quantityLabel,
                ),
              );
            }),
          ],

          // Afficher les autres matières premières
          if (rawMaterials.isNotEmpty) ...[
            ...rawMaterials.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildMaterialItem(
                  context,
                  item.name,
                  'Matière gérée manuellement',
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
    int? seuilAlerte, {
    String? customQuantityLabel,
  }) {
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
              customQuantityLabel ?? '${quantity.toStringAsFixed(0)} $unit',
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
