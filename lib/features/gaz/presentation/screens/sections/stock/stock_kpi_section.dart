import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../domain/entities/cylinder_stock.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import '../../../../domain/services/gaz_calculation_service.dart';
import '../../../widgets/stock_kpi_card.dart';

/// Section des KPI cards pour le stock.
class StockKpiSection extends ConsumerWidget {
  const StockKpiSection({
    super.key,
    required this.allStocks,
    required this.activePointsOfSale,
    required this.pointsOfSale,
  });

  final List<CylinderStock> allStocks;
  final List<Enterprise> activePointsOfSale;
  final List<Enterprise> pointsOfSale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cylindersAsync = ref.watch(cylindersProvider);
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final settingsAsync = ref.watch(gazSettingsProvider((
      enterpriseId: enterpriseId,
      moduleId: 'gaz',
    )));
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final isPOS = activeEnterprise?.type == EnterpriseType.gasPointOfSale;

    return cylindersAsync.when(
      data: (cylinders) {
        final metrics = GazCalculationService.calculateStockMetrics(
          stocks: allStocks,
          pointsOfSale: pointsOfSale,
          cylinders: cylinders,
          settings: settingsAsync.value,
          targetEnterpriseId: enterpriseId,
        );

        return _StockKpiCards(
          metrics: metrics,
          activePointsOfSaleCount: activePointsOfSale.length,
          totalPointsOfSaleCount: pointsOfSale.length,
          showPosTracking: !isPOS,
          isPOS: isPOS,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) {
        // Fallback: use weights from stocks
        final allWeights = allStocks.map((s) => s.weight).toSet().toList()
          ..sort();
        final fullStocks = GazCalculationService.filterFullStocks(allStocks);
        final emptyStocks = GazCalculationService.filterEmptyStocks(allStocks);
        final fullByWeight = GazCalculationService.groupStocksByWeight(
          fullStocks,
        );
        final emptyByWeight = GazCalculationService.groupStocksByWeight(
          emptyStocks,
        );

        final issueStocks = GazCalculationService.filterIssueStocks(allStocks);
        final issueByWeight = GazCalculationService.groupStocksByWeight(issueStocks);

        final viewType = ref.watch(gazDashboardViewTypeProvider);
        final settings = settingsAsync.value;
        if (viewType == GazDashboardViewType.local && settings != null && settings.nominalStocks.isNotEmpty) {
          for (final weight in allWeights) {
            final nominal = settings.getNominalStock(weight);
            if (nominal > 0) {
              final full = fullByWeight[weight] ?? 0;
              final issues = issueByWeight[weight] ?? 0;
              emptyByWeight[weight] = (nominal - full - issues).clamp(0, nominal);
            }
          }
        }

        final totalFull = fullByWeight.values.fold<int>(0, (sum, val) => sum + val);
        final totalEmpty = emptyByWeight.values.fold<int>(0, (sum, val) => sum + val);
        final totalIssues = issueByWeight.values.fold<int>(0, (sum, val) => sum + val);

        final metrics = StockMetrics(
          fullByWeight: fullByWeight,
          emptyByWeight: emptyByWeight,
          issueByWeight: issueByWeight,
          activePointsOfSaleCount: activePointsOfSale.length,
          totalPointsOfSaleCount: pointsOfSale.length,
          availableWeights: allWeights,
        );

        return _StockKpiCards(
          metrics: metrics,
          activePointsOfSaleCount: activePointsOfSale.length,
          totalPointsOfSaleCount: pointsOfSale.length,
          showPosTracking: !isPOS,
          isPOS: isPOS,
        );
      },
    );
  }
}

/// Widget privé pour afficher les KPI cards.
class _StockKpiCards extends StatelessWidget {
  const _StockKpiCards({
    required this.metrics,
    required this.activePointsOfSaleCount,
    required this.totalPointsOfSaleCount,
    this.showPosTracking = true,
    required this.isPOS,
  });

  final StockMetrics metrics;
  final int activePointsOfSaleCount;
  final int totalPointsOfSaleCount;
  final bool showPosTracking;
  final bool isPOS;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final isWide = constraints.maxWidth > 800;
        if (isWide) {
          return Row(
            children: [
              if (showPosTracking) ...[
                Expanded(
                  child: StockKpiCard(
                    title: 'Points de vente actifs',
                    value: '$activePointsOfSaleCount',
                    subtitle: 'sur $totalPointsOfSaleCount au total',
                    icon: Icons.store,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: StockKpiCard(
                  title: 'Bouteilles pleines',
                  value: '${metrics.totalFull}',
                  subtitle: metrics.fullSummary,
                  icon: Icons.inventory_2,
                  valueColor: const Color(0xFF00A63E),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StockKpiCard(
                  title: isPOS ? 'Bouteilles vides' : 'Patrimoine Vide (Dispo)',
                  value: '${metrics.totalEmpty}',
                  subtitle: metrics.emptySummary,
                  icon: isPOS ? Icons.inventory_2_outlined : Icons.account_balance_wallet_outlined,
                  valueColor: const Color(0xFFF54900),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StockKpiCard(
                  title: 'Bouteilles Trouées / Fuites',
                  value: '${metrics.totalIssues}',
                  subtitle: metrics.issueSummary,
                  icon: Icons.report_problem_outlined,
                  valueColor: theme.colorScheme.error,
                ),
              ),
              if (metrics.totalCentralized > 0) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: StockKpiCard(
                    title: 'Stock en Transit',
                    value: '${metrics.totalCentralized}',
                    subtitle: 'Bouteilles en tournée ou manquantes',
                    icon: Icons.local_shipping_outlined,
                    valueColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          );
        }

        // Mobile: stack vertically
        return Column(
          children: [
            if (showPosTracking) ...[
              StockKpiCard(
                title: 'Points de vente actifs',
                value: '$activePointsOfSaleCount',
                subtitle: 'sur $totalPointsOfSaleCount au total',
                icon: Icons.store,
              ),
              const SizedBox(height: 16),
            ],
            StockKpiCard(
              title: 'Bouteilles pleines',
              value: '${metrics.totalFull}',
              subtitle: metrics.fullSummary,
              icon: Icons.inventory_2,
              valueColor: const Color(0xFF00A63E),
            ),
            const SizedBox(height: 16),
            StockKpiCard(
              title: isPOS ? 'Bouteilles vides' : 'Patrimoine Vide (Dispo)',
              value: '${metrics.totalEmpty}',
              subtitle: metrics.emptySummary,
              icon: isPOS ? Icons.inventory_2_outlined : Icons.account_balance_wallet_outlined,
              valueColor: const Color(0xFFF54900),
            ),
            const SizedBox(height: 16),
            StockKpiCard(
              title: 'Bouteilles Trouées / Fuites',
              value: '${metrics.totalIssues}',
              subtitle: metrics.issueSummary,
              icon: Icons.report_problem_outlined,
              valueColor: theme.colorScheme.error,
            ),
            if (metrics.totalCentralized > 0) ...[
              const SizedBox(height: 16),
              StockKpiCard(
                title: 'Stock en Transit',
                value: '${metrics.totalCentralized}',
                subtitle: 'Bouteilles en tournée ou manquantes',
                icon: Icons.local_shipping_outlined,
                valueColor: theme.colorScheme.primary,
              ),
            ],
          ],
        );
      },
    );
  }
}
