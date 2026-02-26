import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import '../point_of_sale_stock_card.dart';
import '../../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_icon_button.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_stock_calculation_service.dart';

/// Dialog pour afficher le stock d'un point de vente.
class PosStockDialog extends ConsumerWidget {
  const PosStockDialog({
    super.key,
    required this.enterprise,
    required this.enterpriseId,
  });

  final Enterprise enterprise;
  final String enterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocksAsync = ref.watch(
      cylinderStocksProvider((
        enterpriseId: enterprise.id, // POS ID
        status: null, // Tous les statuts
        siteId: null,
      )),
    );

    final cylindersAsync = ref.watch(cylindersProvider);
    final settingsAsync = ref.watch(gazSettingsProvider((
      enterpriseId: enterprise.id,
      moduleId: 'gaz',
    )));
    final transfersAsync = ref.watch(stockTransfersProvider(enterprise.id));

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
                .where((s) => s.enterpriseId == enterprise.id)
                .toList();

            final cylinders = cylindersAsync.value ?? [];
            final settings = settingsAsync.value;

            final metrics = GazStockCalculationService.calculatePosStockMetrics(
              enterpriseId: enterprise.id,
              siteId: null,
              allStocks: allStocks,
              transfers: transfersAsync.value,
              cylinders: cylinders,
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Stock - ${enterprise.name}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElyfIconButton(
                      icon: Icons.close,
                      onPressed: () => Navigator.of(context).pop(),
                      useGlassEffect: false,
                      size: 32,
                      iconSize: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: PointOfSaleStockCard(
                      enterprise: enterprise,
                      fullBottles: metrics.totalFull,
                      emptyBottles: metrics.totalEmpty,
                      totalInTransit: metrics.totalInTransit,
                      issueBottles: metrics.totalIssues,
                      stockByCapacity: metrics.stockByCapacity,
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
                      'Stock - ${enterprise.name}',
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
                      'Stock - ${enterprise.name}',
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
