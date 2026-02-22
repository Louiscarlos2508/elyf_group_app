import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/app/theme/app_theme.dart' show StatusColors;
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';

/// Carte récapitulative du stock de bouteilles.
class StockSummaryCard extends ConsumerWidget {
  const StockSummaryCard({super.key, required this.cylinders});

  final List<Cylinder> cylinders;

  Color _getStockColor(BuildContext context, int stock) {
    final statusColors = Theme.of(context).extension<StatusColors>();
    if (stock <= 5) return statusColors?.danger ?? Theme.of(context).colorScheme.error;
    if (stock <= 15) return Colors.orange; // Amber-like theme aware if possible
    return statusColors?.success ?? Colors.green;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (cylinders.isEmpty) {
      return const SizedBox.shrink();
    }

    // Récupérer le stock pour tous les cylinders
    final enterpriseId = cylinders.first.enterpriseId;
    final stocksAsync = ref.watch(
      cylinderStocksProvider((
        enterpriseId: enterpriseId,
        status: CylinderStatus.full,
        siteId: null,
      )),
    );

    return stocksAsync.when(
      data: (allStocks) {
        // Utiliser le service de calcul pour extraire la logique métier
        final calculationService = ref.read(
          gazDashboardCalculationServiceProvider,
        );
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withAlpha(40),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < cylinders.length; i++) ...[
                Builder(
                  builder: (context) {
                    // Filtrer le stock par poids et calculer le total
                    final stocksForWeight = allStocks
                        .where((s) => s.weight == cylinders[i].weight)
                        .toList();
                    final fullStock = calculationService.calculateTotalStock(
                      stocksForWeight,
                    );
                    return _CylinderStockRow(
                      cylinder: cylinders[i],
                      fullStock: fullStock,
                      stockColor: _getStockColor(context, fullStock),
                    );
                  },
                ),
                if (i < cylinders.length - 1)
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
              ],
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CylinderStockRow extends StatelessWidget {
  const _CylinderStockRow({
    required this.cylinder,
    required this.fullStock,
    required this.stockColor,
  });

  final Cylinder cylinder;
  final int fullStock;
  final Color stockColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cylinder.weight} kg',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Prix détail: ${CurrencyFormatter.formatDouble(cylinder.sellPrice)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Vente: ${CurrencyFormatter.formatDouble(cylinder.sellPrice)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: stockColor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: stockColor.withAlpha(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  fullStock <= 5 ? Icons.warning_amber : Icons.inventory_2,
                  size: 18,
                  color: stockColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '$fullStock',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: stockColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
