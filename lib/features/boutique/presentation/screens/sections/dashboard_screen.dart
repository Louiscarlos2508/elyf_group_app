import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';

import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../widgets/dashboard_low_stock_list.dart';
import '../../widgets/dashboard_today_section.dart';
import '../../widgets/dashboard_month_section.dart';

import '../../widgets/restock_dialog.dart';
import '../../widgets/boutique_header.dart';

/// Professional dashboard screen for boutique module.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(recentSalesProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with Gradient
          BoutiqueHeader(
            title: "BOUTIQUE",
            subtitle: "Tableau de Bord",
            gradientColors: [
              const Color(0xFF08BDBA), // Primary Teal/Cyan
              const Color(0xFF0F766E), // Darker Teal
            ],
            shadowColor: const Color(0xFF08BDBA),
            additionalActions: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    ref.invalidate(recentSalesProvider);
                    ref.invalidate(productsProvider);
                    ref.invalidate(lowStockProductsProvider);
                    ref.invalidate(purchasesProvider);
                    ref.invalidate(expensesProvider);
                    ref.invalidate(boutiqueMonthlyMetricsProvider);
                  },
                  tooltip: 'Actualiser',
                ),
              ),
            ],
          ),

          // Today section header
          SectionHeader(
            title: "AUJOURD'HUI",
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),

          // Today KPIs
          SliverPadding(
            padding: AppSpacing.sectionPadding,
            sliver: SliverToBoxAdapter(
              child: salesAsync.when(
                data: (sales) {
                  final calculationService = ref.read(
                    boutiqueDashboardCalculationServiceProvider,
                  );
                  final metrics = calculationService.calculateTodayMetrics(
                    sales,
                  );
                  return DashboardTodaySection(metrics: metrics);
                },
                loading: () => Column(
                  children: [
                    ElyfShimmer(child: ElyfShimmer.listTile()),
                  ],
                ),
                error: (error, stackTrace) => ErrorDisplayWidget(
                  error: error,
                  onRetry: () => ref.refresh(recentSalesProvider),
                ),
              ),
            ),
          ),

          // Month section header
          const SectionHeader(
            title: 'CE MOIS',
            bottom: AppSpacing.sm,
          ),

          // Month KPIs
          SliverPadding(
            padding: AppSpacing.sectionPadding,
            sliver: SliverToBoxAdapter(
              child: _buildMonthKpis(context, ref),
            ),
          ),

          // Low stock section header
          const SectionHeader(
            title: 'ALERTES STOCK',
            bottom: AppSpacing.sm,
          ),

          // Low stock list
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            sliver: SliverToBoxAdapter(
              child: lowStockAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Aucune alerte de stock',
                      message: 'Tous les produits sont en stock suffisant.',
                    );
                  }
                  return DashboardLowStockList(
                    products: products,
                    onProductTap: (product) {
                      showDialog(
                        context: context,
                        builder: (_) => RestockDialog(product: product),
                      );
                    },
                  );
                },
                loading: () => Column(
                  children: [
                    ElyfShimmer(child: ElyfShimmer.listTile()),
                    const SizedBox(height: 8),
                    ElyfShimmer(child: ElyfShimmer.listTile()),
                  ],
                ),
                error: (error, stackTrace) => ErrorDisplayWidget(
                  error: error,
                  title: 'Erreur de chargement',
                  message: 'Impossible de charger les alertes de stock.',
                  onRetry: () => ref.refresh(lowStockProductsProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthKpis(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(boutiqueMonthlyMetricsProvider);

    return metricsAsync.when(
      data: (data) {
        final calculationService = ref.read(
          boutiqueDashboardCalculationServiceProvider,
        );

        final metrics = calculationService
            .calculateMonthlyMetricsWithPurchases(
          sales: data.sales,
          expenses: data.expenses,
          purchases: data.purchases,
        );

        return DashboardMonthSection(
          monthRevenue: metrics.revenue,
          monthSalesCount: metrics.salesCount,
          monthPurchasesAmount: metrics.purchasesAmount,
          monthExpensesAmount: metrics.expensesAmount,
          monthProfit: metrics.profit,
        );
      },
      loading: () => Column(
        children: [
          ElyfShimmer(child: ElyfShimmer.listTile()),
          const SizedBox(height: 16),
          ElyfShimmer(child: ElyfShimmer.listTile()),
        ],
      ),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        title: 'Erreur de chargement des métriques mensuelles',
        onRetry: () => ref.refresh(boutiqueMonthlyMetricsProvider),
      ),
    );
  }
}
