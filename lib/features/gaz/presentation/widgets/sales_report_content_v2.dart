import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/entities/point_of_sale.dart';
import '../../domain/entities/report_data.dart';
import '../../../../shared/utils/currency_formatter.dart';

/// Content widget for sales report tab - style eau_minerale.
class GazSalesReportContentV2 extends ConsumerWidget {
  const GazSalesReportContentV2({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(gasSalesProvider);
    final cylindersAsync = ref.watch(cylindersProvider);
    final pointsOfSaleAsync = ref.watch(
      pointsOfSaleProvider(
        (enterpriseId: 'gaz_1', moduleId: 'gaz'),
      ),
    );
    final reportDataAsync = ref.watch(
      gazReportDataProvider((
        period: GazReportPeriod.custom,
        startDate: startDate,
        endDate: endDate,
      ) as ({
          GazReportPeriod period,
          DateTime? startDate,
          DateTime? endDate,
        })),
    );

    final isWide = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.all(isWide ? 24 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: reportDataAsync.when(
        data: (reportData) {
          return salesAsync.when(
            data: (sales) {
              return cylindersAsync.when(
                data: (cylinders) {
                  return pointsOfSaleAsync.when(
                    data: (pointsOfSale) {
                      return _buildContent(
                        theme,
                        sales,
                        cylinders,
                        pointsOfSale,
                        reportData,
                        isWide,
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _buildContent(
                      theme,
                      sales,
                      cylinders,
                      [],
                      reportData,
                      isWide,
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => salesAsync.when(
                  data: (sales) => _buildContent(
                    theme,
                    sales,
                    [],
                    [],
                    reportData,
                    isWide,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    List<GasSale> sales,
    List<Cylinder> cylinders,
    List<PointOfSale> pointsOfSale,
    GazReportData reportData,
    bool isWide,
  ) {
    // Filter sales by period
    final filteredSales = sales.where((s) {
      return s.saleDate
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          s.saleDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Group by type
    final retailSales = filteredSales
        .where((s) => s.saleType == SaleType.retail)
        .toList();
    final wholesaleSales = filteredSales
        .where((s) => s.saleType == SaleType.wholesale)
        .toList();

    return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Détail des Ventes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${reportData.salesCount} ventes • Total: ${CurrencyFormatter.formatDouble(reportData.salesRevenue)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ventes par type
                  Text(
                    'Répartition par Type',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeCard(
                          theme,
                          'Détail',
                          retailSales.length,
                          retailSales.fold<double>(
                            0,
                            (sum, s) => sum + s.totalAmount,
                          ),
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTypeCard(
                          theme,
                          'Gros',
                          wholesaleSales.length,
                          wholesaleSales.fold<double>(
                            0,
                            (sum, s) => sum + s.totalAmount,
                          ),
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Statistiques détaillées par type
                  Text(
                    'Statistiques Détaillées',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Statistiques par type de bouteille
                  _buildCylinderStatistics(theme, filteredSales, cylinders),
                  const SizedBox(height: 24),

                  // Statistiques ventes au détail
                  if (retailSales.isNotEmpty) ...[
                    Text(
                      'Statistiques Ventes au Détail',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRetailStatistics(theme, retailSales, pointsOfSale),
                    const SizedBox(height: 24),
                  ],

                  // Statistiques ventes en gros
                  if (wholesaleSales.isNotEmpty) ...[
                    Text(
                      'Statistiques Ventes en Gros',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildWholesaleStatistics(theme, wholesaleSales),
                    const SizedBox(height: 24),
                  ],

                  // Liste des ventes récentes
                  Text(
                    'Ventes Récentes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredSales.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Aucune vente pour cette période',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ...filteredSales
                        .take(10)
                        .map((sale) => _buildSaleRow(theme, sale)),
                ],
              );
  }

  Widget _buildTypeCard(
    ThemeData theme,
    String type,
    int count,
    double total,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatDouble(total),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count vente${count > 1 ? 's' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleRow(ThemeData theme, GasSale sale) {
    final formattedDate =
        '${sale.saleDate.day.toString().padLeft(2, '0')}/${sale.saleDate.month.toString().padLeft(2, '0')}/${sale.saleDate.year} ${sale.saleDate.hour.toString().padLeft(2, '0')}:${sale.saleDate.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: sale.saleType == SaleType.retail
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                sale.saleType == SaleType.retail
                    ? Icons.store
                    : Icons.local_shipping,
                size: 20,
                color: sale.saleType == SaleType.retail
                    ? Colors.orange
                    : Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.saleType == SaleType.wholesale && sale.wholesalerName != null
                        ? sale.wholesalerName!
                        : sale.customerName ?? 'Client anonyme',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  // Informations supplémentaires pour ventes en gros
                  if (sale.saleType == SaleType.wholesale && sale.tourId != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tour d\'approvisionnement',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (sale.saleType == SaleType.wholesale && sale.wholesalerName != null && sale.customerName != null && sale.customerName != sale.wholesalerName) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Client: ${sale.customerName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatDouble(sale.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (sale.quantity > 1)
                  Text(
                    '${sale.quantity} × ${CurrencyFormatter.formatDouble(sale.unitPrice)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWholesaleStatistics(ThemeData theme, List<GasSale> wholesaleSales) {
    // Grouper par tour
    final salesByTour = <String, List<GasSale>>{};
    final salesByWholesaler = <String, ({String name, List<GasSale> sales})>{};

    for (final sale in wholesaleSales) {
      // Grouper par tour
      if (sale.tourId != null) {
        salesByTour.putIfAbsent(sale.tourId!, () => []).add(sale);
      }

      // Grouper par grossiste
      if (sale.wholesalerId != null && sale.wholesalerName != null) {
        if (!salesByWholesaler.containsKey(sale.wholesalerId!)) {
          salesByWholesaler[sale.wholesalerId!] = (
            name: sale.wholesalerName!,
            sales: <GasSale>[]
          );
        }
        salesByWholesaler[sale.wholesalerId!]!.sales.add(sale);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistiques par tour
        if (salesByTour.isNotEmpty) ...[
          Text(
            'Par Tour d\'Approvisionnement',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...salesByTour.entries.map((entry) {
            final tourSales = entry.value;
            final total = tourSales.fold<double>(
              0,
              (sum, s) => sum + s.totalAmount,
            );
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 16,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tour ${entry.key.substring(0, 8)}...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatDouble(total),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${tourSales.length} vente${tourSales.length > 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Statistiques par grossiste
        if (salesByWholesaler.isNotEmpty) ...[
          Text(
            'Par Grossiste',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...salesByWholesaler.entries.map((entry) {
            final wholesalerData = entry.value;
            final total = wholesalerData.sales.fold<double>(
              0,
              (sum, s) => sum + s.totalAmount,
            );
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          wholesalerData.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatDouble(total),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${wholesalerData.sales.length} vente${wholesalerData.sales.length > 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildCylinderStatistics(
    ThemeData theme,
    List<GasSale> sales,
    List<Cylinder> cylinders,
  ) {
    // Grouper les ventes par type de bouteille
    final salesByCylinder = <String, ({int weight, int count, double total})>{};

    for (final sale in sales) {
      final cylinder = cylinders.firstWhere(
        (c) => c.id == sale.cylinderId,
        orElse: () => cylinders.isNotEmpty ? cylinders.first : throw StateError('No cylinders'),
      );

      if (!salesByCylinder.containsKey(sale.cylinderId)) {
        salesByCylinder[sale.cylinderId] = (
          weight: cylinder.weight,
          count: 0,
          total: 0.0,
        );
      }
      final current = salesByCylinder[sale.cylinderId]!;
      salesByCylinder[sale.cylinderId] = (
        weight: current.weight,
        count: current.count + sale.quantity,
        total: current.total + sale.totalAmount,
      );
    }

    if (salesByCylinder.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Par Type de Bouteille',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...salesByCylinder.entries.map((entry) {
            final data = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${data.weight} kg',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatDouble(data.total),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${data.count} bouteille${data.count > 1 ? 's' : ''} vendue${data.count > 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRetailStatistics(
    ThemeData theme,
    List<GasSale> retailSales,
    List<PointOfSale> pointsOfSale,
  ) {
    // Grouper par client
    final salesByClient = <String, ({int count, double total})>{};
    for (final sale in retailSales) {
      final clientName = sale.customerName ?? 'Client anonyme';
      if (!salesByClient.containsKey(clientName)) {
        salesByClient[clientName] = (count: 0, total: 0.0);
      }
      final current = salesByClient[clientName]!;
      salesByClient[clientName] = (
        count: current.count + sale.quantity,
        total: current.total + sale.totalAmount,
      );
    }

    // Calculer les totaux
    final totalRetail = retailSales.fold<double>(
      0,
      (sum, s) => sum + s.totalAmount,
    );
    final totalQuantity = retailSales.fold<int>(
      0,
      (sum, s) => sum + s.quantity,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Résumé global
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${retailSales.length}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'Vente${retailSales.length > 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    CurrencyFormatter.formatDouble(totalRetail),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'Total',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '$totalQuantity',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'Bouteille${totalQuantity > 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Top clients
        if (salesByClient.isNotEmpty) ...[
          Text(
            'Top Clients',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...(salesByClient.entries.toList()
                ..sort((a, b) => b.value.total.compareTo(a.value.total)))
              .take(5)
              .map((entry) {
            final data = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatDouble(data.total),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${data.count} bouteille${data.count > 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}