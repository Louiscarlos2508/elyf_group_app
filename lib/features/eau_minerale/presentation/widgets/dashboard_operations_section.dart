import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/finances_controller.dart'
    show FinancesState;
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'dashboard_kpi_card.dart';

/// Section displaying operations KPIs.
class DashboardOperationsSection extends ConsumerWidget {
  const DashboardOperationsSection({
    super.key,
    required this.financesState,
  });

  final AsyncValue<FinancesState> financesState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupérer les sessions de production et les salaires depuis les providers
    final productionSessionsAsync = ref.watch(productionSessionsStateProvider);
    final salaryStateAsync = ref.watch(salaryStateProvider);

    return financesState.when(
      data: (finances) {
        return productionSessionsAsync.when(
          data: (sessions) {
            return salaryStateAsync.when(
              data: (salaryState) {
                final calculationService = ref.read(
                  dashboardCalculationServiceProvider,
                );
                final now = DateTime.now();
                final monthStart = calculationService.getMonthStart(now);

                // Calculer la production du mois avec les sessions
                final monthSessions = sessions
                    .where((s) => s.date.isAfter(monthStart))
                    .toList();
                final monthProduction = monthSessions.fold<int>(
                  0,
                  (sum, s) => sum + s.quantiteProduite,
                );

                // Calculer les dépenses du mois
                final monthExpenses = calculationService
                    .calculateMonthlyExpensesFromRecords(
                      finances.expenses,
                      monthStart,
                    );
                final expensesCount = calculationService
                    .countMonthlyExpensesFromRecords(
                      finances.expenses,
                      monthStart,
                    );

                // Calculer les salaires du mois
                final monthSalaryPayments = salaryState.monthlySalaryPayments
                    .where((p) => p.date.isAfter(monthStart))
                    .toList();
                final monthProductionPayments = salaryState.productionPayments
                    .where((p) => p.paymentDate.isAfter(monthStart))
                    .toList();
                final monthSalaries = monthSalaryPayments.fold<int>(
                      0,
                      (sum, p) => sum + p.amount,
                    ) +
                    monthProductionPayments.fold<int>(
                      0,
                      (sum, p) => sum + p.totalAmount,
                    );
                final salariesCount =
                    monthSalaryPayments.length + monthProductionPayments.length;

                final cards = [
                  DashboardKpiCard(
                    label: 'Production',
                    value: monthProduction.toString(),
                    subtitle: '${monthSessions.length} session${monthSessions.length > 1 ? 's' : ''}',
                    icon: Icons.factory,
                    iconColor: Colors.purple,
                    backgroundColor: Colors.purple,
                  ),
                  DashboardKpiCard(
                    label: 'Dépenses',
                    value: CurrencyFormatter.formatFCFA(monthExpenses),
                    subtitle: '$expensesCount transaction${expensesCount > 1 ? 's' : ''}',
                    icon: Icons.receipt_long,
                    iconColor: Colors.red,
                    backgroundColor: Colors.red,
                  ),
                  DashboardKpiCard(
                    label: 'Salaires',
                    value: CurrencyFormatter.formatFCFA(monthSalaries),
                    subtitle: '$salariesCount paiement${salariesCount > 1 ? 's' : ''}',
                    icon: Icons.people,
                    iconColor: Colors.indigo,
                    backgroundColor: Colors.indigo,
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
                  ],
                ),
              );
            }

                    return Column(
                      children: [
                        cards[0],
                        const SizedBox(height: 16),
                        cards[1],
                        const SizedBox(height: 16),
                        cards[2],
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
            );
          },
          loading: () => const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
