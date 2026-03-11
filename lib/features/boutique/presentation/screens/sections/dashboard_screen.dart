import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../widgets/dashboard_low_stock_list.dart';
import '../../widgets/dashboard_today_section.dart';
import '../../widgets/dashboard_month_section.dart';

import '../../widgets/boutique_stock_alert_banner.dart';
import '../../widgets/purchase_entry_dialog.dart';
import '../../widgets/expense_entry_dialog.dart';

/// Professional dashboard screen for boutique module.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final salesAsync = ref.watch(recentSalesProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with Gradient
          ElyfModuleHeader(
            title: "Tableau de Bord",
            subtitle: "Suivez vos ventes, stocks et sessions de caisse en temps réel.",
            module: EnterpriseModule.boutique,
            actions: [
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

          // Stock Alert Banner
          SliverToBoxAdapter(
            child: lowStockAsync.when(
              data: (products) {
                if (products.isEmpty) return const SizedBox.shrink();
                final product = products.first;
                return BoutiqueStockAlertBanner(
                  productName: product.name,
                  currentStock: product.stock,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => PurchaseEntryDialog(initialProduct: product),
                    );
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Today section header
          const SliverSectionHeader(
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
                    boutiqueCalculationServiceProvider,
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

          // Actions Rapides
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.add_shopping_cart,
                      label: 'Approvisionner',
                      color: const Color(0xFF08BDBA),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const PurchaseEntryDialog(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.money_off,
                      label: 'Dépense',
                      color: const Color(0xFFE57373),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const ExpenseEntryDialog(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Month section header
          const SliverSectionHeader(
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
          const SliverSectionHeader(
            title: 'ALERTES STOCK',
            bottom: AppSpacing.sm,
          ),

          // Low stock list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
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
                        builder: (_) => PurchaseEntryDialog(initialProduct: product),
                      );
                    },
                    onRestockTap: (product) {
                      showDialog(
                        context: context,
                        builder: (_) => PurchaseEntryDialog(initialProduct: product),
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
          boutiqueCalculationServiceProvider,
        );

        final metrics = calculationService
            .calculateMonthlyMetrics(
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

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
