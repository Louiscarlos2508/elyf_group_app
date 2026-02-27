import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import '../../application/providers.dart';
import '../../domain/entities/gas_sale.dart';
import '../../../../features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../domain/entities/cylinder.dart';

class PosNetworkReportTab extends ConsumerWidget {
  const PosNetworkReportTab({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);

    return activeEnterpriseAsync.when(
      data: (enterprise) {
        if (enterprise == null) return const SizedBox.shrink();

        final salesAsync = ref.watch(gasSalesProvider);
        final cylindersAsync = ref.watch(cylindersProvider);
        final pointsOfSaleAsync = ref.watch(
          enterprisesByParentAndTypeProvider((
            parentId: enterprise.id,
            type: EnterpriseType.gasPointOfSale,
          )),
        );

        return salesAsync.when(
          data: (sales) {
            return cylindersAsync.when(
              data: (cylinders) {
                return pointsOfSaleAsync.when(
                  data: (pointsOfSale) {
                    if (pointsOfSale.isEmpty) {
                      return _buildEmptyState(context, theme);
                    }
                    return _buildContent(
                        context, ref, theme, sales, pointsOfSale, cylinders);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Erreur POS: $err')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erreur Cylindres: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Erreur Ventes: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erreur Entreprise: $err')),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: 64,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun Point de Vente (POS) trouvé',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cette vue est réservée aux entreprises gérant plusieurs points de vente.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<GasSale> allSales,
    List<Enterprise> pointsOfSale,
    List<Cylinder> cylinders,
  ) {
    final reportService = ref.read(gazReportCalculationServiceProvider);
    
    // Filter sales by date
    final filteredSales = reportService.filterSalesByDateRange(
      sales: allSales,
      startDate: startDate,
      endDate: endDate,
    );

    // Calculate Global Network KPIs
    double totalRevenue = 0;
    for (final sale in filteredSales) {
      totalRevenue += sale.totalAmount;
    }
    final double avgBasket = filteredSales.isEmpty ? 0.0 : totalRevenue / filteredSales.length;

    // Cylinder name map
    final cylinderNames = {for (final c in cylinders) c.id: '${c.weight}kg'};

    // Global Product Breakdown
    final globalProductBreakdown = <String, int>{};
    for (final sale in filteredSales) {
      final label = cylinderNames[sale.cylinderId] ?? 'Inconnu';
      globalProductBreakdown[label] =
          (globalProductBreakdown[label] ?? 0) + sale.quantity;
    }

    // Group sales by POS
    final posStats = <String, _PosStats>{};
    for (final pos in pointsOfSale) {
      final posSales = filteredSales.where((s) => s.enterpriseId == pos.id).toList();
      double revenue = 0;
      int qty = 0;
      final productBreakdown = <String, int>{};

      for (final s in posSales) {
        revenue += s.totalAmount;
        qty += s.quantity;
        final label = cylinderNames[s.cylinderId] ?? 'Inconnu';
        productBreakdown[label] = (productBreakdown[label] ?? 0) + s.quantity;
      }

      // Find top product for this POS
      String topProduct = '-';
      int maxQty = 0;
      productBreakdown.forEach((label, q) {
        if (q > maxQty) {
          maxQty = q;
          topProduct = label;
        }
      });

      posStats[pos.id] = _PosStats(
        enterprise: pos,
        revenue: revenue,
        salesCount: posSales.length,
        quantity: qty,
        topProduct: topProduct,
      );
    }

    // Sort POS by revenue descending
    final sortedPos = posStats.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNetworkKpis(theme, totalRevenue, filteredSales.length, avgBasket),
        const SizedBox(height: 24),
        _buildProductBreakdownSection(theme, globalProductBreakdown),
        const SizedBox(height: 32),
        Text(
          'Performance par Point de Vente',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...sortedPos.map((stats) => _buildPosCard(theme, stats, totalRevenue)),
      ],
    );
  }

  Widget _buildNetworkKpis(ThemeData theme, double totalRevenue, int saleCount, double avgBasket) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _KpiItem(
            label: 'Revenu Réseau',
            value: CurrencyFormatter.format(totalRevenue.toInt()),
            icon: Icons.account_balance_wallet,
            color: theme.colorScheme.primary,
          ),
          const _VerticalDivider(),
          _KpiItem(
            label: 'Ventes Totales',
            value: '$saleCount',
            icon: Icons.shopping_bag_outlined,
            color: theme.colorScheme.secondary,
          ),
          const _VerticalDivider(),
          _KpiItem(
            label: 'Panier Moyen',
            value: CurrencyFormatter.format(avgBasket.toInt()),
            icon: Icons.analytics_outlined,
            color: theme.colorScheme.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildProductBreakdownSection(ThemeData theme, Map<String, int> breakdown) {
    if (breakdown.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Répartition des Ventes Réseau',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: breakdown.entries.map((e) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gas_meter_outlined, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${e.key} : ',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${e.value} unités',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPosCard(ThemeData theme, _PosStats stats, double networkTotal) {
    final share = networkTotal > 0 ? (stats.revenue / networkTotal) * 100 : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.store, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.enterprise.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 12, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.salesCount} ventes',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.inventory_2_outlined, size: 12, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.quantity} bout.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Top : ${stats.topProduct}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(stats.revenue.toInt()),
                   style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${share.toStringAsFixed(1)}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PosStats {
  final Enterprise enterprise;
  final double revenue;
  final int salesCount;
  final int quantity;
  final String topProduct;

  _PosStats({
    required this.enterprise,
    required this.revenue,
    required this.salesCount,
    required this.quantity,
    required this.topProduct,
  });
}

class _KpiItem extends StatelessWidget {
  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
}
}
