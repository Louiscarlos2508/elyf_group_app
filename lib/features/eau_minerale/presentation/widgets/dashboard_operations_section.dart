import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/finances_controller.dart' show FinancesState;
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/services/dashboard_calculation_service.dart';
import 'dashboard_kpi_card.dart';

/// Section displaying operations KPIs.
/// TODO: Réimplémenter avec productionSessionsStateProvider
class DashboardOperationsSection extends ConsumerWidget {
  const DashboardOperationsSection({
    super.key,
    required this.productionState,
    required this.financesState,
  });

  final AsyncValue<dynamic> productionState; // TODO: Remplacer par productionSessionsStateProvider
  final AsyncValue<FinancesState> financesState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Réimplémenter avec les sessions de production
    return financesState.when(
      data: (finances) {
        final calculationService = ref.read(dashboardCalculationServiceProvider);
        final now = DateTime.now();
        final monthStart = calculationService.getMonthStart(now);
        // TODO: Calculer avec les sessions de production
        final monthProduction = 0;
        final monthProductions = <dynamic>[];
        final monthExpenses = calculationService.calculateMonthlyExpensesFromRecords(
          finances.expenses,
          monthStart,
        );
        final monthSalaries = 0; // TODO: Add salaries
        final expensesCount = calculationService.countMonthlyExpensesFromRecords(
          finances.expenses,
          monthStart,
        );

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              
              final cards = [
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
                  value: CurrencyFormatter.formatFCFA(monthExpenses),
                  subtitle: '$expensesCount transaction',
                  icon: Icons.receipt_long,
                  iconColor: Colors.red,
                  backgroundColor: Colors.red,
                ),
                DashboardKpiCard(
                  label: 'Salaires',
                  value: CurrencyFormatter.formatFCFA(monthSalaries),
                  subtitle: '0 paiement',
                  icon: Icons.people,
                  iconColor: Colors.indigo,
                  backgroundColor: Colors.indigo,
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
  }
}

