import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/gas_sale.dart';
import '../../../../features/administration/domain/entities/enterprise.dart';
import '../../domain/entities/report_data.dart';
import 'sales_report/sales_report_cylinder_stats.dart';
import 'sales_report/sales_report_header.dart';
import 'sales_report/sales_report_recent_sales.dart';
import 'sales_report/sales_report_retail_stats.dart';
import 'sales_report/sales_report_type_cards.dart';
import 'sales_report/sales_report_wholesale_stats.dart';
import 'package:elyf_groupe_app/shared.dart';

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
    // Récupérer l'entreprise active depuis le tenant provider
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    return activeEnterpriseAsync.when(
      data: (enterprise) {
        if (enterprise == null) {
          return const Center(child: Text('Aucune entreprise active disponible'));
        }
        
        final enterpriseId = enterprise.id;
        const moduleId = 'gaz';
        
        final salesAsync = ref.watch(gasSalesProvider);
        final cylindersAsync = ref.watch(cylindersProvider);
        final pointsOfSaleAsync = ref.watch(
          enterprisesByParentAndTypeProvider((
            parentId: enterpriseId,
            type: EnterpriseType.gasPointOfSale,
          )),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
      },
      loading: () => Container(
        padding: const EdgeInsets.all(24),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text('Erreur de chargement de l\'entreprise active'),
        ),
      ),
    );
  }

  Widget _buildContent(
    WidgetRef ref,
    ThemeData theme,
    List<GasSale> sales,
    List<Cylinder> cylinders,
    List<Enterprise> pointsOfSale,
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
        if (reportData.internalWholesaleRevenue > 0) ...[
          const SizedBox(height: 16),
          _buildInternalVsExternalBreakdown(theme, reportData),
        ],
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
      ],
    );
  }
  Widget _buildInternalVsExternalBreakdown(ThemeData theme, GazReportData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: theme.colorScheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ventilation du Chiffre d\'Affaires',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBreakdownRow(
            theme,
            'CA Client Final (Réel)',
            data.realSalesRevenue,
            theme.colorScheme.primary,
            isBold: true,
          ),
          const Divider(),
          _buildBreakdownRow(
            theme,
            'Mouvements Internes (Siège -> POS)',
            data.internalWholesaleRevenue,
            theme.colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    ThemeData theme,
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            CurrencyFormatter.formatDouble(amount),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
