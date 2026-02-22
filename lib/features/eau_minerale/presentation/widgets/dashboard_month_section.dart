import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import '../../application/controllers/clients_controller.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/customer_account.dart';
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
  final AsyncValue<dynamic> productionState;
  final AsyncValue<ClientsState> clientsState;
  final AsyncValue<FinancesState> financesState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Réimplémenter avec les sessions de production
    return salesState.when(
      data: (sales) => clientsState.when(
        data: (clients) => financesState.when(
          data: (finances) {
            final calculationService = ref.read(dashboardCalculationServiceProvider);
            final summaryAsync = ref.watch(monthlyDashboardSummaryProvider);
            
            return summaryAsync.when(
              data: (summary) {
                // Convert CustomerSummary to CustomerAccount for credit calculation
                final customerAccounts = clients.customers
                    .map(
                      (c) => CustomerAccount(
                        id: c.id,
                        name: c.name,
                        outstandingCredit: c.totalCredit,
                        lastOrderDate: c.lastPurchaseDate ?? DateTime.now(),
                        phone: c.phone,
                      ),
                    )
                    .toList();
                
                final totalCredits = calculationService.calculateTotalCredits(customerAccounts);
                final creditCustomersCount = calculationService.countCreditCustomers(customerAccounts);

                final cards = [
                  DashboardKpiCard(
                    label: 'Chiffre d\'Affaires',
                    value: CurrencyFormatter.formatCFA(summary.revenue),
                    subtitle: '${summary.salesCount} ventes',
                    icon: Icons.trending_up,
                    iconColor: Colors.blue,
                    backgroundColor: Colors.blue,
                  ),
                  DashboardKpiCard(
                    label: 'Encaissé',
                    value: CurrencyFormatter.formatCFA(summary.collections),
                    subtitle: summary.revenue > 0 
                        ? '${(summary.collections / summary.revenue * 100).toStringAsFixed(0)}%'
                        : '0%',
                    icon: Icons.attach_money,
                    iconColor: Colors.green,
                    valueColor: Colors.green.shade700,
                    backgroundColor: Colors.green,
                  ),
                  DashboardKpiCard(
                    label: 'Crédits en Cours',
                    value: CurrencyFormatter.formatCFA(totalCredits),
                    subtitle: '$creditCustomersCount client${creditCustomersCount > 1 ? 's' : ''}',
                    icon: Icons.calendar_today,
                    iconColor: Colors.orange,
                    backgroundColor: Colors.orange,
                  ),
                  DashboardKpiCard(
                    label: 'Résultat',
                    value: CurrencyFormatter.formatCFA(summary.result),
                    subtitle: summary.result >= 0 ? 'Bénéfice' : 'Déficit',
                    icon: Icons.account_balance_wallet,
                    iconColor: summary.result >= 0 ? Colors.green : Colors.red,
                    valueColor: summary.result >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    backgroundColor: summary.result >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ];

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    
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
