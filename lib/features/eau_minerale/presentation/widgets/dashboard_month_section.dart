import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/clients_controller.dart';
import '../../application/controllers/finances_controller.dart';
import '../../application/controllers/production_controller.dart';
import '../../application/controllers/sales_controller.dart';
import 'dashboard_kpi_card.dart';

/// Section displaying monthly KPIs.
class DashboardMonthSection extends StatelessWidget {
  const DashboardMonthSection({
    super.key,
    required this.salesState,
    required this.productionState,
    required this.clientsState,
    required this.financesState,
  });

  final AsyncValue<SalesState> salesState;
  final AsyncValue<ProductionState> productionState;
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
  Widget build(BuildContext context) {
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
                  
                  final cards = [
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
      ),
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

