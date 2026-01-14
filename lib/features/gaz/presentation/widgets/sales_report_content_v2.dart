import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/entities/point_of_sale.dart';
import '../../domain/entities/report_data.dart';
import 'sales_report/sales_report_cylinder_stats.dart';
import 'sales_report/sales_report_header.dart';
import 'sales_report/sales_report_recent_sales.dart';
import 'sales_report/sales_report_retail_stats.dart';
import 'sales_report/sales_report_type_cards.dart';
import 'sales_report/sales_report_wholesale_stats.dart';

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
      pointsOfSaleProvider((enterpriseId: 'gaz_1', moduleId: 'gaz')),
    );
    final reportDataAsync = ref.watch(
      gazReportDataProvider(
        (period: GazReportPeriod.custom, startDate: startDate, endDate: endDate)
            as ({
              GazReportPeriod period,
              DateTime? startDate,
              DateTime? endDate,
            }),
      ),
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
                        ref,
                        theme,
                        sales,
                        cylinders,
                        pointsOfSale,
                        reportData,
                        isWide,
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _buildContent(
                      ref,
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
                    ref,
                    theme,
                    sales,
                    [],
                    [],
                    reportData,
                    isWide,
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
    WidgetRef ref,
    ThemeData theme,
    List<GasSale> sales,
    List<Cylinder> cylinders,
    List<PointOfSale> pointsOfSale,
    GazReportData reportData,
    bool isWide,
  ) {
    // Utiliser le service de calcul pour extraire la logique métier
    final reportService = ref.read(gazReportCalculationServiceProvider);
    final filteredSales = reportService.filterSalesByDateRange(
      sales: sales,
      startDate: startDate,
      endDate: endDate,
    );
    final groupedSales = reportService.separateSalesByType(filteredSales);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SalesReportHeader(reportData: reportData),
        const SizedBox(height: 24),
        SalesReportTypeCards(
          retailSales: groupedSales.retailSales,
          wholesaleSales: groupedSales.wholesaleSales,
        ),
        const SizedBox(height: 24),
        Text(
          'Statistiques Détaillées',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SalesReportCylinderStats(sales: filteredSales, cylinders: cylinders),
        const SizedBox(height: 24),
        if (groupedSales.retailSales.isNotEmpty) ...[
          Text(
            'Statistiques Ventes au Détail',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SalesReportRetailStats(retailSales: groupedSales.retailSales),
          const SizedBox(height: 24),
        ],
        if (groupedSales.wholesaleSales.isNotEmpty) ...[
          Text(
            'Statistiques Ventes en Gros',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SalesReportWholesaleStats(
            wholesaleSales: groupedSales.wholesaleSales,
          ),
          const SizedBox(height: 24),
        ],
        SalesReportRecentSales(sales: filteredSales),
      ],
    );
  }
}
