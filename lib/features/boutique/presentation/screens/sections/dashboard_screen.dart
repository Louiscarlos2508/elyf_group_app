import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard_low_stock_list.dart';
import '../../widgets/dashboard_month_section.dart';
import '../../widgets/dashboard_today_section.dart';
import '../../widgets/restock_dialog.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/refresh_button.dart';

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
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DashboardHeader(
                      date: DateTime.now(),
                      role: 'Gérant',
                    ),
                  ),
                  Semantics(
                    label: 'Actualiser le tableau de bord',
                    hint: 'Recharge toutes les données affichées',
                    button: true,
                    child: RefreshButton(
                      onRefresh: () {
                    ref.invalidate(recentSalesProvider);
                    ref.invalidate(productsProvider);
                    ref.invalidate(lowStockProductsProvider);
                    ref.invalidate(purchasesProvider);
                    ref.invalidate(expensesProvider);
                    ref.invalidate(boutiqueMonthlyMetricsProvider);
                      },
                      tooltip: 'Actualiser le tableau de bord',
                    ),
                  ),
                ],
              ),
            ),
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
                loading: () => const LoadingIndicator(),
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
              child: _buildMonthKpis(ref),
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
                loading: () => const LoadingIndicator(height: 100),
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

  Widget _buildMonthKpis(WidgetRef ref) {
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
      loading: () => const LoadingIndicator(height: 200),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        title: 'Erreur de chargement des métriques mensuelles',
        onRetry: () => ref.refresh(boutiqueMonthlyMetricsProvider),
      ),
    );
  }
}
