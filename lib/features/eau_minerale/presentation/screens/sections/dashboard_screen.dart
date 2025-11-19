import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/controllers/clients_controller.dart';
import '../../../application/controllers/finances_controller.dart';
import '../../../application/controllers/production_controller.dart';
import '../../../application/controllers/sales_controller.dart';
import '../../../application/controllers/stock_controller.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/stock_item.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard_kpi_card.dart';
import '../../widgets/section_placeholder.dart';
import '../../widgets/stock_alert_banner.dart';

/// Professional dashboard screen with organized sections and responsive layout.
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
            child: DashboardHeader(date: DateTime.now(), role: 'Responsable'),
          ),
          SliverToBoxAdapter(
            child: stockState.when(
              data: (data) {
                final lowStockItems = data.items
                    .where(
                      (item) =>
                          item.type == StockType.finishedGoods &&
                          item.quantity < 100,
                    )
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
          _buildSectionHeader("AUJOURD'HUI", 24, 16),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverToBoxAdapter(
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
          _buildSectionHeader('CE MOIS', 0, 8),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverToBoxAdapter(
              child: _buildMonthSection(
                context,
                salesState,
                productionState,
                clientsState,
                financesState,
              ),
            ),
          ),
          _buildSectionHeader('Opérations', 0, 8),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverToBoxAdapter(
              child: _buildOperationsSection(
                context,
                productionState,
                financesState,
              ),
            ),
          ),
          _buildSectionHeader('Stock Produits Finis', 0, 8),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            sliver: SliverToBoxAdapter(
              child: stockState.when(
                data: (data) => _buildStockList(context, data),
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => SectionPlaceholder(
                  icon: Icons.inventory_2_outlined,
                  title: 'Stock indisponible',
                  subtitle: 'Impossible de charger le stock.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, double top, double bottom) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, top, 24, bottom),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySection(BuildContext context, SalesState salesState) {
    final todayRevenue = salesState.todayRevenue;
    final todaySalesCount = salesState.sales.length;
    final todayCollections = salesState.sales
        .where((Sale sale) => sale.isFullyPaid)
        .fold(0, (int sum, Sale sale) => sum + sale.amountPaid);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cards = [
          DashboardKpiCard(
            label: 'Chiffre d\'Affaires',
            value: _formatCurrency(todayRevenue),
            subtitle: '$todaySalesCount vente(s)',
            icon: Icons.trending_up,
            iconColor: Colors.blue,
            backgroundColor: Colors.blue,
          ),
          DashboardKpiCard(
            label: 'Encaissements',
            value: _formatCurrency(todayCollections),
            subtitle: todayRevenue > 0
                ? '${((todayCollections / todayRevenue) * 100).toStringAsFixed(0)}% collecté'
                : '0% collecté',
            icon: Icons.attach_money,
            iconColor: Colors.green,
            valueColor: Colors.green.shade700,
            backgroundColor: Colors.green,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          );
        }

        return Column(
          children: [cards[0], const SizedBox(height: 16), cards[1]],
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
              final now = DateTime.now();
              final monthStart = DateTime(now.year, now.month, 1);
              final monthSales = sales.sales
                  .where((s) => s.date.isAfter(monthStart))
                  .toList();
              final monthRevenue = monthSales.fold(
                0,
                (sum, s) => sum + s.totalPrice,
              );
              final monthCollections = monthSales
                  .where((s) => s.isFullyPaid)
                  .fold(0, (sum, s) => sum + s.amountPaid);
              final collectionRate = monthRevenue > 0
                  ? ((monthCollections / monthRevenue) * 100)
                  : 0.0;
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
                    childAspectRatio: isWide ? 1.4 : 1.6,
                    children: [
                      DashboardKpiCard(
                        label: 'Chiffre d\'Affaires',
                        value: _formatCurrency(monthRevenue),
                        subtitle: '${monthSales.length} ventes',
                        icon: Icons.trending_up,
                        iconColor: Colors.blue,
                        backgroundColor: Colors.blue,
                      ),
                      DashboardKpiCard(
                        label: 'Encaissé',
                        value: _formatCurrency(monthCollections),
                        subtitle: '${collectionRate.toStringAsFixed(0)}%',
                        icon: Icons.attach_money,
                        iconColor: Colors.green,
                        valueColor: Colors.green.shade700,
                        backgroundColor: Colors.green,
                      ),
                      DashboardKpiCard(
                        label: 'Crédits en Cours',
                        value: _formatCurrency(totalCredits),
                        subtitle: '$creditCustomersCount client',
                        icon: Icons.calendar_today,
                        iconColor: Colors.orange,
                        backgroundColor: Colors.orange,
                      ),
                      DashboardKpiCard(
                        label: 'Résultat',
                        value: _formatCurrency(monthResult),
                        subtitle: monthResult >= 0 ? 'Bénéfice' : 'Déficit',
                        icon: Icons.account_balance_wallet,
                        iconColor: monthResult >= 0 ? Colors.green : Colors.red,
                        valueColor: monthResult >= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        backgroundColor: monthResult >= 0 ? Colors.green : Colors.red,
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
          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month, 1);
          final monthProductions = production.productions
              .where((p) => p.date.isAfter(monthStart))
              .toList();
          final monthProduction = monthProductions.fold(
            0,
            (sum, p) => sum + p.quantity,
          );
          final monthExpenses = finances.expenses
              .where((e) => e.date.isAfter(monthStart))
              .fold(0, (sum, e) => sum + e.amountCfa);
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
                childAspectRatio: isWide ? 1.5 : 1.8,
                children: [
                  DashboardKpiCard(
                    label: 'Production',
                    value: monthProduction.toString(),
                    subtitle: '${monthProductions.length} session',
                    icon: Icons.factory,
                    iconColor: Colors.purple,
                    backgroundColor: Colors.purple,
                  ),
                  DashboardKpiCard(
                    label: 'Dépenses',
                    value: _formatCurrency(monthExpenses),
                    subtitle: '${finances.expenses.where((e) => e.date.isAfter(monthStart)).length} transaction',
                    icon: Icons.receipt_long,
                    iconColor: Colors.red,
                    backgroundColor: Colors.red,
                  ),
                  DashboardKpiCard(
                    label: 'Salaires',
                    value: _formatCurrency(monthSalaries),
                    subtitle: '0 paiement',
                    icon: Icons.people,
                    iconColor: Colors.indigo,
                    backgroundColor: Colors.indigo,
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

  Widget _buildStockList(BuildContext context, StockState stockState) {
    final theme = Theme.of(context);
    final finishedGoods = stockState.items
        .where((StockItem item) => item.type == StockType.finishedGoods)
        .toList();

    if (finishedGoods.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun produit fini en stock',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...finishedGoods.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLowStock = item.quantity < 100;

            return Container(
              decoration: BoxDecoration(
                border: index < finishedGoods.length - 1
                    ? Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.1,
                          ),
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                title: Text(
                  item.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: isLowStock
                    ? Text(
                        'Stock faible',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isLowStock
                            ? Colors.orange.withValues(alpha: 0.1)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.quantity.toInt()} ${item.unit}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isLowStock
                              ? Colors.orange.shade900
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
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
