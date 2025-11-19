import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/controllers/clients_controller.dart';
import '../../../application/controllers/finances_controller.dart';
import '../../../application/controllers/production_controller.dart';
import '../../../application/controllers/sales_controller.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/stock_item.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard_kpi_card.dart';
import '../../widgets/section_placeholder.dart';
import '../../widgets/stock_alert_banner.dart';

/// Professional dashboard screen similar to the reference image.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesState = ref.watch(salesStateProvider);
    final productionState = ref.watch(productionStateProvider);
    final financesState = ref.watch(financesStateProvider);
    final clientsState = ref.watch(clientsStateProvider);
    final stockState = ref.watch(stockStateProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DashboardHeader(
              date: DateTime.now(),
              role: 'Responsable',
            ),
          ),
          // Stock alerts
          SliverToBoxAdapter(
            child: stockState.when(
              data: (data) {
                final lowStockItems = data.items
                    .where((item) =>
                        item.type == StockType.finishedGoods &&
                        item.quantity < 100)
                    .toList();
                if (lowStockItems.isEmpty) return const SizedBox.shrink();
                return StockAlertBanner(
                  productName: lowStockItems.first.name,
                  onTap: () {
                    // Navigate to stock screen
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          // Today section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                "AUJOURD'HUI",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: salesState.when(
                data: (data) => _buildTodaySection(context, data),
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
          // This month section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'CE MOIS',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildMonthSection(
                context,
                salesState,
                productionState,
                clientsState,
                financesState,
              ),
            ),
          ),
          // Production, Expenses, Salaries section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _buildOperationsSection(
                context,
                productionState,
                financesState,
              ),
            ),
          ),
          // Stock section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                'Stock Produits Finis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: stockState.when(
                data: (data) => _buildStockList(context, data),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => SectionPlaceholder(
                  icon: Icons.inventory_2_outlined,
                  title: 'Stock indisponible',
                  subtitle: 'Impossible de charger le stock.',
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildTodaySection(BuildContext context, dynamic salesState) {
    final todayRevenue = salesState.todayRevenue;
    final todaySalesCount = salesState.sales.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return isWide
            ? Row(
                children: [
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Chiffre d\'Affaires',
                      value: _formatCurrency(todayRevenue),
                      subtitle: '$todaySalesCount vente(s)',
                      icon: Icons.trending_up,
                      iconColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardKpiCard(
                      label: 'Encaissements',
                      value: _formatCurrency(todayRevenue),
                      subtitle: '100% collecté',
                      icon: Icons.attach_money,
                      iconColor: Colors.green,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  DashboardKpiCard(
                    label: 'Chiffre d\'Affaires',
                    value: _formatCurrency(todayRevenue),
                    subtitle: '$todaySalesCount vente(s)',
                    icon: Icons.trending_up,
                    iconColor: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  DashboardKpiCard(
                    label: 'Encaissements',
                    value: _formatCurrency(todayRevenue),
                    subtitle: '100% collecté',
                    icon: Icons.attach_money,
                    iconColor: Colors.green,
                  ),
                ],
              );
      },
    );
  }

  Widget _buildMonthSection(
    BuildContext context,
    AsyncValue<SalesState> salesState,
    AsyncValue<ProductionState> productionState,
    AsyncValue<ClientsState> clientsState,
    AsyncValue<FinancesState> financesState,
  ) {
    return salesState.when(
      data: (sales) => productionState.when(
        data: (production) => clientsState.when(
          data: (clients) => financesState.when(
            data: (finances) {
              final monthRevenue = sales.todayRevenue * 30; // Mock
              final monthCollections = (monthRevenue * 0.9).round();
              final collectionRate = 90.0;
              final totalCredits = clients.totalCredit;
              final creditCustomersCount = clients.customers
                  .where((c) => c.totalCredit > 0)
                  .length;
              final monthResult = monthCollections - finances.totalCharges;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  final crossAxisCount = isWide ? 4 : 2;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isWide ? 1.1 : 1.3,
                    children: [
                      DashboardKpiCard(
                        label: 'Chiffre d\'Affaires',
                        value: _formatCurrency(monthRevenue),
                        subtitle: '${sales.sales.length} ventes',
                        icon: Icons.trending_up,
                        iconColor: Colors.blue,
                      ),
                      DashboardKpiCard(
                        label: 'Encaissé',
                        value: _formatCurrency(monthCollections),
                        subtitle: '$collectionRate% taux encaissement',
                        icon: Icons.attach_money,
                        iconColor: Colors.green,
                        valueColor: Colors.green.shade700,
                      ),
                      DashboardKpiCard(
                        label: 'Crédits en Cours',
                        value: _formatCurrency(totalCredits),
                        subtitle: '$creditCustomersCount client(s)',
                        icon: Icons.calendar_today,
                        iconColor: Colors.orange,
                      ),
                      DashboardKpiCard(
                        label: 'Résultat',
                        value: _formatCurrency(monthResult),
                        subtitle: 'Encaissements - Charges',
                        icon: Icons.trending_up,
                        iconColor: Colors.green,
                        valueColor: Colors.green.shade700,
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildOperationsSection(
    BuildContext context,
    AsyncValue<ProductionState> productionState,
    AsyncValue<FinancesState> financesState,
  ) {
    return productionState.when(
      data: (production) => financesState.when(
        data: (finances) {
          final monthProduction = production.totalQuantity;
          final monthExpenses = finances.totalCharges;
          final monthSalaries = 0; // TODO: Add salaries

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final crossAxisCount = isWide ? 3 : 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isWide ? 1.2 : 1.5,
                children: [
                  DashboardKpiCard(
                    label: 'Production',
                    value: monthProduction.toString(),
                    subtitle: '${production.productions.length} session(s) ce mois',
                    icon: Icons.factory,
                    iconColor: Colors.purple,
                  ),
                  DashboardKpiCard(
                    label: 'Dépenses',
                    value: _formatCurrency(monthExpenses),
                    subtitle: '${finances.expenses.length} transaction(s)',
                    icon: Icons.receipt_long,
                    iconColor: Colors.red,
                  ),
                  DashboardKpiCard(
                    label: 'Salaires',
                    value: _formatCurrency(monthSalaries),
                    subtitle: '0 paiement(s)',
                    icon: Icons.people,
                    iconColor: Colors.purple,
                  ),
                ],
              );
            },
          );
        },
        loading: () => const SizedBox(
          height: 150,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStockList(BuildContext context, dynamic stockState) {
    final finishedGoods = stockState.items
        .where((item) => item.type == StockType.finishedGoods)
        .toList();

    if (finishedGoods.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Aucun produit fini en stock',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: finishedGoods.map<Widget>((item) {
          return ListTile(
            title: Text(item.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.quantity.toInt()} ${item.unit}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.settings_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatCurrency(int amount) {
    // Format with spaces for thousands separator
    final amountStr = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < amountStr.length; i++) {
      if (i > 0 && (amountStr.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(amountStr[i]);
    }
    return '${buffer.toString()} CFA';
  }
}

