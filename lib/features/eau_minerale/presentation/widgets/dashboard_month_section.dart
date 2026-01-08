import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/clients_controller.dart';
import '../../application/controllers/finances_controller.dart';
import '../../application/controllers/sales_controller.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/customer_account.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/services/dashboard_calculation_service.dart';
import 'dashboard_kpi_card.dart';

/// Section displaying monthly KPIs.
/// TODO: Réimplémenter avec productionSessionsStateProvider
class DashboardMonthSection extends ConsumerWidget {
  const DashboardMonthSection({
    super.key,
    required this.salesState,
    required this.productionState,
    required this.clientsState,
    required this.financesState,
  });

  final AsyncValue<SalesState> salesState;
  final AsyncValue<dynamic> productionState; // TODO: Remplacer par productionSessionsStateProvider
  final AsyncValue<ClientsState> clientsState;
  final AsyncValue<FinancesState> financesState;

  String _formatCurrency(int amount) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Réimplémenter avec les sessions de production
    return salesState.when(
      data: (sales) => clientsState.when(
        data: (clients) => financesState.when(
          data: (finances) {
              final calculationService = ref.read(dashboardCalculationServiceProvider);
              // Convert CustomerSummary to CustomerAccount for the calculation service
              final customerAccounts = clients.customers.map((c) => CustomerAccount(
                id: c.id,
                name: c.name,
                outstandingCredit: c.totalCredit,
                lastOrderDate: c.lastPurchaseDate ?? DateTime.now(),
                phone: c.phone,
              )).toList();
              // Use the method that accepts ExpenseRecord list
              final metrics = calculationService.calculateMonthlyMetricsFromRecords(
                sales: sales.sales,
                customers: customerAccounts,
                expenses: finances.expenses,
              );

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  
                  final cards = [
                    DashboardKpiCard(
                      label: 'Chiffre d\'Affaires',
                      value: _formatCurrency(metrics.revenue),
                      subtitle: '${metrics.salesCount} ventes',
                      icon: Icons.trending_up,
                      iconColor: Colors.blue,
                      backgroundColor: Colors.blue,
                    ),
                    DashboardKpiCard(
                      label: 'Encaissé',
                      value: _formatCurrency(metrics.collections),
                      subtitle: '${metrics.collectionRate.toStringAsFixed(0)}%',
                      icon: Icons.attach_money,
                      iconColor: Colors.green,
                      valueColor: Colors.green.shade700,
                      backgroundColor: Colors.green,
                    ),
                    DashboardKpiCard(
                      label: 'Crédits en Cours',
                      value: _formatCurrency(metrics.totalCredits),
                      subtitle: '${metrics.creditCustomersCount} client',
                      icon: Icons.calendar_today,
                      iconColor: Colors.orange,
                      backgroundColor: Colors.orange,
                    ),
                    DashboardKpiCard(
                      label: 'Résultat',
                      value: _formatCurrency(metrics.result),
                      subtitle: metrics.isProfit ? 'Bénéfice' : 'Déficit',
                      icon: Icons.account_balance_wallet,
                      iconColor: metrics.isProfit ? Colors.green : Colors.red,
                      valueColor: metrics.isProfit
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      backgroundColor: metrics.isProfit ? Colors.green : Colors.red,
                    ),
                  ];

                  if (isWide) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[1]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[2]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[3]),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[1]),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[2]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[3]),
                        ],
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
    );
  }
}

