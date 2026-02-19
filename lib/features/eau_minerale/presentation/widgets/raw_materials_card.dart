import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';

import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/packaging_stock.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/stock_item.dart';

/// Helper class pour regrouper les stocks de même type.
class _GroupedStock {
  _GroupedStock({
    required this.quantity,
    required this.isLowStock,
    this.seuilAlerte,
    this.unitsPerLot = 1,
  });

  final int quantity;
  final bool isLowStock;
  final int? seuilAlerte;
  final int unitsPerLot;

  String get quantityLabel {
    if (unitsPerLot <= 1) return '$quantity unités';
    final lots = quantity / unitsPerLot;
    return '${lots.toStringAsFixed(1)} lots ($quantity unités)';
  }
}

class RawMaterialsCard extends StatelessWidget {
  final List<StockItem> items;
  final List<Product>? products; // Optionnel pour enrichir les données
  final int availableBobines; // Total pour compatibilité
  final List<BobineStock> bobineStocks; // Stocks de bobines par type
  final List<PackagingStock> packagingStocks;

  const RawMaterialsCard({
    super.key,
    required this.items,
    this.products,
    required this.availableBobines,
    required this.bobineStocks,
    required this.packagingStocks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // List of raw materials from catalog (empty if catalog not loaded)
    final rawMaterialProducts = products?.where((p) => p.isRawMaterial).toList() ?? [];

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
          
          // 2. Afficher chaque matière première du catalogue
          ...rawMaterialProducts.map((product) {
            final nameLower = product.name.toLowerCase();
            
            // Chercher la quantité totale dans toutes les sources de stock
            double totalQuantity = 0;
            bool isLowStock = false;
            int? seuilAlerte;

            // a. Chercher dans packagingStocks
            final pkgStocks = packagingStocks.where((s) => s.type.toLowerCase() == nameLower);
            for (final s in pkgStocks) {
              totalQuantity += s.quantity;
              if (s.estStockFaible) isLowStock = true;
              seuilAlerte = s.seuilAlerte;
            }

            // b. Chercher dans bobineStocks
            final bbStocks = bobineStocks.where((s) => s.type.toLowerCase() == nameLower);
            for (final s in bbStocks) {
              totalQuantity += s.quantity;
              if (s.estStockFaible) isLowStock = true;
              seuilAlerte = s.seuilAlerte;
            }

            // c. Chercher dans les items génériques (si non déjà compté)
            if (pkgStocks.isEmpty && bbStocks.isEmpty) {
              final genericItems = items.where((i) => i.name.toLowerCase() == nameLower);
              for (final i in genericItems) {
                totalQuantity += i.quantity;
                // Pas de seuil d'alerte sur les items génériques dans ce modèle
              }
            }

            // Libellé de quantité
            String quantityDisplay;
            if (product.unitsPerLot > 1) {
              final lots = totalQuantity / product.unitsPerLot;
              quantityDisplay = '${lots.toStringAsFixed(1)} lots (${totalQuantity.toInt()} ${product.unit})';
            } else {
              quantityDisplay = '${totalQuantity.toInt()} ${product.unit}';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildPackagingItem(
                context,
                product.name,
                product.description ?? (product.unitsPerLot > 1 
                  ? 'Format: ${product.unitsPerLot} ${product.unit}/lot' 
                  : 'Géré à l\'unité'),
                totalQuantity,
                product.unit,
                isLowStock,
                seuilAlerte,
                customQuantityLabel: quantityDisplay,
              ),
            );
          }),

          // 3. Optionnel: Afficher les stocks qui ne sont PAS dans le catalogue (cas d'erreur/legacy)
          ...() {
            final catalogNames = rawMaterialProducts.map((p) => p.name.toLowerCase()).toSet();
            final legacyItems = items.where((i) => 
              i.type == StockType.rawMaterial && 
              !catalogNames.contains(i.name.toLowerCase()) &&
              !i.name.toLowerCase().contains('sachet') // Sachet est géré en interne
            ).toList();

            if (legacyItems.isEmpty) return <Widget>[];

            return [
              const Divider(height: 32),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Autres articles (Hors Catalogue)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              ...legacyItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildMaterialItem(
                  context,
                  item.name,
                  'Article non défini dans le catalogue',
                  item.quantity,
                  item.unit,
                ),
              )),
            ];
          }(),
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
