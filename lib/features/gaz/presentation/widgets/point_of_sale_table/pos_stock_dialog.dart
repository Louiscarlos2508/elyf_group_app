import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/point_of_sale.dart';
import '../point_of_sale_stock_card.dart';

/// Dialog pour afficher le stock d'un point de vente.
class PosStockDialog extends ConsumerWidget {
  const PosStockDialog({
    super.key,
    required this.pointOfSale,
    required this.enterpriseId,
  });

  final PointOfSale pointOfSale;
  final String enterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocksAsync = ref.watch(
      cylinderStocksProvider((
        enterpriseId: enterpriseId,
        status: null, // Tous les statuts
        siteId: pointOfSale.id,
      )),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: stocksAsync.when(
          data: (allStocks) {
            // Filtrer les stocks pour ce point de vente
            final posStocks = allStocks
                .where((s) => s.siteId == pointOfSale.id || s.siteId == null)
                .toList();

            // Calculer les totaux
            final posFull = posStocks
                .where((s) => s.status == CylinderStatus.full)
                .fold<int>(0, (sum, s) => sum + s.quantity);
            final posEmpty = posStocks
                .where(
                  (s) =>
                      s.status == CylinderStatus.emptyAtStore ||
                      s.status == CylinderStatus.emptyInTransit,
                )
                .fold<int>(0, (sum, s) => sum + s.quantity);

            // Grouper par capacité
            final stockByCapacity = <int, ({int full, int empty})>{};
            final availableWeights =
                posStocks.map((s) => s.weight).toSet().toList()..sort();
            for (final weight in availableWeights) {
              final full = posStocks
                  .where(
                    (s) =>
                        s.weight == weight && s.status == CylinderStatus.full,
                  )
                  .fold<int>(0, (sum, s) => sum + s.quantity);
              final empty = posStocks
                  .where(
                    (s) =>
                        s.weight == weight &&
                        (s.status == CylinderStatus.emptyAtStore ||
                            s.status == CylinderStatus.emptyInTransit),
                  )
                  .fold<int>(0, (sum, s) => sum + s.quantity);
              if (full > 0 || empty > 0) {
                stockByCapacity[weight] = (full: full, empty: empty);
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Stock - ${pointOfSale.name}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: PointOfSaleStockCard(
                      pointOfSale: pointOfSale,
                      fullBottles: posFull,
                      emptyBottles: posEmpty,
                      stockByCapacity: stockByCapacity,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Stock - ${pointOfSale.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
          error: (error, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Stock - ${pointOfSale.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
