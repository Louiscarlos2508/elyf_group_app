import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/finances_controller.dart' show FinancesState;
import 'dashboard_kpi_card.dart';

/// Section displaying operations KPIs.
/// TODO: Réimplémenter avec productionSessionsStateProvider
class DashboardOperationsSection extends StatelessWidget {
  const DashboardOperationsSection({
    super.key,
    required this.productionState,
    required this.financesState,
  });

  final AsyncValue<dynamic> productionState; // TODO: Remplacer par productionSessionsStateProvider
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
    // TODO: Réimplémenter avec les sessions de production
    return financesState.when(
      data: (finances) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        // TODO: Calculer avec les sessions de production
        final monthProduction = 0;
        final monthProductions = <dynamic>[];
          final monthExpenses = finances.expenses
              .where((e) => e.date.isAfter(monthStart))
              .fold(0, (sum, e) => sum + e.amountCfa);
          final monthSalaries = 0; // TODO: Add salaries

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

