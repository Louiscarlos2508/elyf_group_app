import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/administration/presentation/widgets/audit/audit_log_item.dart';
import 'package:elyf_groupe_app/features/administration/presentation/screens/sections/admin_audit_trail_section.dart';
import 'package:elyf_groupe_app/shared.dart';

// Gaz Imports
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/presentation/screens/sections/dashboard/dashboard_kpi_section.dart';
import 'package:elyf_groupe_app/features/gaz/presentation/screens/sections/dashboard/dashboard_performance_section.dart';
import 'package:elyf_groupe_app/features/gaz/presentation/widgets/dashboard_stock_by_capacity.dart';

// Boutique Imports
import 'package:elyf_groupe_app/features/boutique/application/providers.dart' as b_providers;
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/dashboard_today_section.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/dashboard_month_section.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/dashboard_low_stock_list.dart';

// Mobile Money Imports
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';

// Immobilier Imports
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/property.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/payment.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/contract.dart';
import 'package:elyf_groupe_app/features/immobilier/presentation/widgets/dashboard_today_section_v2.dart' as immob_widgets;
import 'package:elyf_groupe_app/features/immobilier/presentation/widgets/dashboard_month_section_v2.dart' as immob_widgets;

// Eau Minérale Imports
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/dashboard_state_providers.dart' as em_providers;
import 'package:elyf_groupe_app/features/eau_minerale/presentation/widgets/dashboard_today_section.dart' as em_widgets;
import 'package:elyf_groupe_app/features/eau_minerale/presentation/widgets/dashboard_month_section.dart' as em_widgets;
import 'package:elyf_groupe_app/features/eau_minerale/presentation/widgets/dashboard_stock_list.dart' as em_widgets;

/// Strategy interface for building module-specific dashboards
abstract class EnterpriseDashboardStrategy {
  /// Returns the list of tabs available for this strategy
  List<Tab> getTabs(Set<String> permissions);

  /// Builds the content for the tab at the given index
  Widget buildTabContent(
    BuildContext context,
    WidgetRef ref,
    int index,
    Enterprise enterprise,
    Set<String> permissions,
  );

  /// Factory method to get the correct strategy based on enterprise type
  static EnterpriseDashboardStrategy fromEnterprise(Enterprise enterprise) {
    if (enterprise.type.isGas) {
      if (enterprise.type == EnterpriseType.gasWarehouse) return _GazWarehouseStrategy();
      if (enterprise.type == EnterpriseType.gasPointOfSale) return _GazPosStrategy();
      return _GazStrategy();
    }
    if (enterprise.type.isMobileMoney) return _MobileMoneyStrategy();
    if (enterprise.type.isWater) return _EauMineraleStrategy();
    if (enterprise.type.isRealEstate) return _ImmobilierStrategy();
    if (enterprise.type.isShop) return _BoutiqueStrategy();

    return _GenericStrategy();
  }

  /// Helper to filter tabs based on required permissions
  List<Tab> filterTabs(List<({Tab tab, String? permission})> definitions, Set<String> permissions) {
    return definitions
        .where((def) => def.permission == null || permissions.contains('*') || permissions.contains(def.permission))
        .map((def) => def.tab)
        .toList();
  }
}

// --- Concrete Strategies ---

class _GenericStrategy extends EnterpriseDashboardStrategy {
  @override
  List<Tab> getTabs(Set<String> permissions) => filterTabs([
    (tab: const Tab(text: 'Aperçu', icon: Icon(Icons.dashboard_outlined)), permission: 'view_dashboard'),
    (tab: const Tab(text: 'Équipe', icon: Icon(Icons.people_outline)), permission: 'manage_staff'),
    (tab: const Tab(text: 'Info', icon: Icon(Icons.info_outline)), permission: null),
    (tab: const Tab(text: 'Audit', icon: Icon(Icons.history_outlined)), permission: 'view_audit_logs'),
  ], permissions);

  @override
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise, Set<String> permissions) {
    final tabs = getTabs(permissions);
    if (index >= tabs.length) return const SizedBox();
    final tabText = (tabs[index].text ?? '').toLowerCase();

    if (tabText.contains('aperçu')) return const Center(child: Text('Aperçu Général'));
    if (tabText.contains('équipe')) return const Center(child: Text('Gestion Équipe'));
    if (tabText.contains('info')) return const Center(child: Text('Informations Légales'));
    if (tabText.contains('audit')) return _buildAuditTab(context, ref, enterprise);
    return const SizedBox();
  }
}

class _GazStrategy extends EnterpriseDashboardStrategy {
  @override
  List<Tab> getTabs(Set<String> permissions) => filterTabs([
    (tab: const Tab(text: 'Aperçu', icon: Icon(Icons.dashboard_outlined)), permission: 'view_dashboard'),
    (tab: const Tab(text: 'Stock', icon: Icon(Icons.propane_tank_outlined)), permission: 'view_stock'),
    (tab: const Tab(text: 'Livraisons', icon: Icon(Icons.local_shipping_outlined)), permission: 'view_tours'),
    (tab: const Tab(text: 'Équipe', icon: Icon(Icons.people_outline)), permission: 'manage_staff'),
    (tab: const Tab(text: 'Audit', icon: Icon(Icons.history_outlined)), permission: 'view_audit_logs'),
  ], permissions);

  @override
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise, Set<String> permissions) {
    final tabs = getTabs(permissions);
    if (index >= tabs.length) return const SizedBox();
    final tabText = (tabs[index].text ?? '').toLowerCase();

    if (tabText.contains('aperçu')) return _buildGazApercu(context, ref, enterprise);
    if (tabText.contains('stock')) {
      return CustomScrollView(
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(child: DashboardStockByCapacity()),
          ),
        ],
      );
    }
    if (tabText.contains('livraisons')) return const Center(child: Text('Suivi Camions & Livraisons (Prochainement)'));
    if (tabText.contains('équipe')) return const Center(child: Text('Équipe Gaz (Prochainement)'));
    if (tabText.contains('audit')) return _buildAuditTab(context, ref, enterprise);
    
    return const SizedBox();
  }

  Widget _buildGazApercu(BuildContext context, WidgetRef ref, Enterprise enterprise) {
    final dashboardDataAsync = ref.watch(gazDashboardDataProviderComplete);
    final viewType = ref.watch(gazDashboardViewTypeProvider);
    final settingsAsync = ref.watch(gazSettingsProvider((
      enterpriseId: enterprise.id,
      moduleId: 'gaz',
    )));

    return dashboardDataAsync.when(
      data: (data) => CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: DashboardKpiSection(
                sales: data.sales,
                remittances: data.remittances,
                expenses: data.expenses,
                cylinders: data.cylinders,
                stocks: data.stocks,
                pointsOfSale: data.pointsOfSale,
                settings: settingsAsync.value,
                viewType: viewType,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: DashboardPerformanceSection(
                sales: data.sales,
                expenses: data.expenses,
              ),
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
    );
  }
}

class _GazPosStrategy extends _GazStrategy {
  @override
  List<Tab> getTabs(Set<String> permissions) => filterTabs([
    (tab: const Tab(text: 'Aperçu', icon: Icon(Icons.dashboard_outlined)), permission: 'view_dashboard'),
    (tab: const Tab(text: 'Stock', icon: Icon(Icons.propane_tank_outlined)), permission: 'view_stock'),
    (tab: const Tab(text: 'Ventes', icon: Icon(Icons.receipt_long_outlined)), permission: 'view_sales'),
    (tab: const Tab(text: 'Audit', icon: Icon(Icons.history_outlined)), permission: 'view_audit_logs'),
  ], permissions);

  @override
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise, Set<String> permissions) {
    final tabs = getTabs(permissions);
    if (index >= tabs.length) return const SizedBox();
    final tabText = (tabs[index].text ?? '').toLowerCase();

    if (tabText.contains('aperçu')) return _buildGazApercu(context, ref, enterprise);
    if (tabText.contains('stock')) {
      return CustomScrollView(
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(child: DashboardStockByCapacity()),
          ),
        ],
      );
    }
    if (tabText.contains('ventes')) return const Center(child: Text('Historique Ventes (Prochainement)'));
    if (tabText.contains('audit')) return _buildAuditTab(context, ref, enterprise);
    return const SizedBox();
  }
}

class _GazWarehouseStrategy extends _GazStrategy {
  // Warehouse specific implementation - inherits from _GazStrategy for now
}

class _MobileMoneyStrategy extends EnterpriseDashboardStrategy {
  @override
  List<Tab> getTabs(Set<String> permissions) => filterTabs([
    (tab: const Tab(text: 'Trésorerie', icon: Icon(Icons.account_balance_wallet_outlined)), permission: 'view_liquidity'),
    (tab: const Tab(text: 'Commissions', icon: Icon(Icons.percent_outlined)), permission: 'view_commissions'),
    (tab: const Tab(text: 'Opérations', icon: Icon(Icons.history_edu_outlined)), permission: 'view_transactions'),
    (tab: const Tab(text: 'Audit', icon: Icon(Icons.history_outlined)), permission: 'view_audit_logs'),
  ], permissions);

  @override
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise, Set<String> permissions) {
    final tabs = getTabs(permissions);
    if (index >= tabs.length) return const SizedBox();
    final tabText = (tabs[index].text ?? '').toLowerCase();

    if (tabText.contains('trésorerie')) {
      final balanceAsync = ref.watch(orangeMoneyTreasuryBalanceProvider(enterprise.id));
      return balanceAsync.when(
        data: (balances) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMetricCard(context, 'Cash en main', '${balances['cash'] ?? 0} FCFA', Icons.money),
            _buildMetricCard(context, 'Solde Mobile Money', '${balances['mobileMoney'] ?? 0} FCFA', Icons.account_balance_wallet),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      );
    }
    
    if (tabText.contains('commissions')) {
      final statsAsync = ref.watch(commissionsStatisticsProvider(enterprise.id));
      return statsAsync.when(
        data: (stats) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMetricCard(context, 'Commissions du mois', '${stats['totalPending'] ?? 0} FCFA', Icons.pending_actions),
            _buildMetricCard(context, 'Commissions payées', '${stats['totalPaid'] ?? 0} FCFA', Icons.check_circle_outline),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      );
    }

    if (tabText.contains('opérations')) {
      final now = DateTime.now();
      final key = '${enterprise.id}|${DateTime(now.year, now.month, now.day).millisecondsSinceEpoch}';
      final statsAsync = ref.watch(dailyTransactionStatsProvider(key));
      return statsAsync.when(
        data: (stats) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMetricCard(context, 'Dépôts (Aujourd\'hui)', '${stats['deposits'] ?? 0} FCFA', Icons.arrow_downward),
            _buildMetricCard(context, 'Retraits (Aujourd\'hui)', '${stats['withdrawals'] ?? 0} FCFA', Icons.arrow_upward),
            _buildMetricCard(context, 'Nombre total', '${stats['transactionCount'] ?? 0}', Icons.tag),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      );
    }

    if (tabText.contains('audit')) return _buildAuditTab(context, ref, enterprise);
    return const SizedBox();
  }
}

class _EauMineraleStrategy extends EnterpriseDashboardStrategy {
  @override
  List<Tab> getTabs(Set<String> permissions) => filterTabs([
    (tab: const Tab(text: 'Production', icon: Icon(Icons.water_drop_outlined)), permission: 'view_production'),
    (tab: const Tab(text: 'Stock', icon: Icon(Icons.inventory_2_outlined)), permission: 'view_stock'),
    (tab: const Tab(text: 'Ventes', icon: Icon(Icons.local_shipping_outlined)), permission: 'view_sales'),
    (tab: const Tab(text: 'Audit', icon: Icon(Icons.history_outlined)), permission: 'view_audit_logs'),
  ], permissions);

  @override
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise, Set<String> permissions) {
    final tabs = getTabs(permissions);
    if (index >= tabs.length) return const SizedBox();
    final tabText = (tabs[index].text ?? '').toLowerCase();

    if (tabText.contains('production')) return const Center(child: Text('Sessions de Production (Prochainement)'));
    if (tabText.contains('stock')) return const Center(child: Text('Stock Sachets & Matières Premières (Prochainement)'));
    if (tabText.contains('ventes')) return const Center(child: Text('Livraisons Eau (Prochainement)'));
    if (tabText.contains('audit')) return _buildAuditTab(context, ref, enterprise);
    return const SizedBox();
  }
}

class _ImmobilierStrategy extends EnterpriseDashboardStrategy {
  @override
  List<Tab> getTabs(Set<String> permissions) => filterTabs([
    (tab: const Tab(text: 'Biens', icon: Icon(Icons.home_work_outlined)), permission: 'view_properties'),
    (tab: const Tab(text: 'Loyers', icon: Icon(Icons.monetization_on_outlined)), permission: 'view_payments'),
    (tab: const Tab(text: 'Contrats', icon: Icon(Icons.description_outlined)), permission: 'view_contracts'),
    (tab: const Tab(text: 'Audit', icon: Icon(Icons.history_outlined)), permission: 'view_audit_logs'),
  ], permissions);

  @override
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise, Set<String> permissions) {
    final tabs = getTabs(permissions);
    if (index >= tabs.length) return const SizedBox();
    final tabText = (tabs[index].text ?? '').toLowerCase();

    if (tabText.contains('biens')) {
      final propertiesAsync = ref.watch(propertiesProvider);
      return propertiesAsync.when(
        data: (properties) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMetricCard(context, 'Total des biens', '${properties.length}', Icons.home_work),
            _buildMetricCard(context, 'Biens occupés', '${properties.where((p) => p.status == PropertyStatus.rented).length}', Icons.person_outline),
            _buildMetricCard(context, 'Biens libres', '${properties.where((p) => p.status == PropertyStatus.available).length}', Icons.vpn_key_outlined),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      );
    }

    if (tabText.contains('loyers')) {
      final paymentsAsync = ref.watch(paymentsProvider);
      return paymentsAsync.when(
        data: (payments) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMetricCard(context, 'Loyers encaissés', '${payments.where((p) => p.status == PaymentStatus.paid).length}', Icons.payments_outlined),
            _buildMetricCard(context, 'Total encaissé', '${payments.where((p) => p.status == PaymentStatus.paid).fold<int>(0, (sum, p) => sum + p.amount)} FCFA', Icons.monetization_on),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      );
    }

    if (tabText.contains('contrats')) {
      final contractsAsync = ref.watch(contractsProvider);
      return contractsAsync.when(
        data: (contracts) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMetricCard(context, 'Contrats actifs', '${contracts.where((c) => c.status == ContractStatus.active).length}', Icons.description_outlined),
            _buildMetricCard(context, 'Contrats en attente', '${contracts.where((c) => c.status == ContractStatus.pending).length}', Icons.hourglass_empty),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      );
    }
    
    if (tabText.contains('audit')) return _buildAuditTab(context, ref, enterprise);
    return const SizedBox();
  }
}

class _BoutiqueStrategy extends EnterpriseDashboardStrategy {
  @override
  List<Tab> getTabs(Set<String> permissions) => filterTabs([
    (tab: const Tab(text: 'Aperçu', icon: Icon(Icons.point_of_sale_outlined)), permission: 'view_dashboard'),
    (tab: const Tab(text: 'Stock', icon: Icon(Icons.inventory_2_outlined)), permission: 'view_stock'),
    (tab: const Tab(text: 'Caisse', icon: Icon(Icons.payments_outlined)), permission: 'view_treasury'),
    (tab: const Tab(text: 'Audit', icon: Icon(Icons.history_outlined)), permission: 'view_audit_logs'),
  ], permissions);

  @override
  Widget buildTabContent(BuildContext context, WidgetRef ref, int index, Enterprise enterprise, Set<String> permissions) {
    final tabs = getTabs(permissions);
    if (index >= tabs.length) return const SizedBox();
    final tabText = (tabs[index].text ?? '').toLowerCase();

    if (tabText.contains('aperçu')) return _buildBoutiqueApercu(context, ref, enterprise);
    if (tabText.contains('stock')) return _buildBoutiqueStock(context, ref, enterprise);
    if (tabText.contains('caisse')) return const Center(child: Text('Fermeture de Caisse (Prochainement)'));
    if (tabText.contains('audit')) return _buildAuditTab(context, ref, enterprise);
    return const SizedBox();
  }

  Widget _buildBoutiqueApercu(
    BuildContext context,
    WidgetRef ref,
    Enterprise enterprise,
  ) {
    final salesAsync = ref.watch(b_providers.recentSalesProvider);
    final metricsAsync = ref.watch(b_providers.boutiqueMonthlyMetricsProvider);

    return CustomScrollView(
      slivers: [
        const SliverSectionHeader(title: "AUJOURD'HUI"),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: salesAsync.when(
              data: (sales) {
                final calculationService = ref.read(
                  b_providers.boutiqueCalculationServiceProvider,
                );
                final metrics = calculationService.calculateTodayMetrics(sales);
                return DashboardTodaySection(metrics: metrics);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ),
        const SliverSectionHeader(title: 'CE MOIS'),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: metricsAsync.when(
              data: (data) {
                final calculationService = ref.read(
                  b_providers.boutiqueCalculationServiceProvider,
                );
                final metrics = calculationService.calculateMonthlyMetrics(
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoutiqueStock(
    BuildContext context,
    WidgetRef ref,
    Enterprise enterprise,
  ) {
    final lowStockAsync = ref.watch(b_providers.lowStockProductsProvider);

    return CustomScrollView(
      slivers: [
        const SliverSectionHeader(title: 'ALERTES STOCK'),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: lowStockAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Aucune alerte',
                    message: 'Stocks suffisants.',
                  );
                }
                return DashboardLowStockList(
                  products: products,
                  onProductTap: (_) {},
                  onRestockTap: (_) {},
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildAuditTab(BuildContext context, WidgetRef ref, Enterprise enterprise) {
  final logsAsync = ref.watch(auditLogsForEntityProvider((type: 'enterprise', id: enterprise.id)));

  return logsAsync.when(
    data: (logs) {
      if (logs.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_toggle_off, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Text(
                'Aucune activité enregistrée', 
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        itemBuilder: (context, index) => AuditLogItem(log: logs[index]),
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, s) => Center(child: Text('Erreur: $e')),
  );
}

Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon) {
  final theme = Theme.of(context);
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
    ),
    color: theme.colorScheme.surface,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
