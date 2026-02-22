import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';

/// Widget displaying monthly expense summary.
class MonthlyExpenseSummary extends ConsumerWidget {
  const MonthlyExpenseSummary({super.key, required this.expenses});

  final List<ExpenseRecord> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Utiliser le service de calcul pour extraire la logique métier
    final calculationService = ref.watch(dashboardCalculationServiceProvider);
    final now = DateTime.now();
    final monthStart = calculationService.getMonthStart(now);
    final salaryState = ref.watch(salaryStateProvider);
    final sessions = ref.watch(productionSessionsStateProvider).value ?? [];

    final monthlyTotal = calculationService.calculateMonthlyExpensesFromRecords(
      expenses: expenses,
      salaryPayments: salaryState.value?.monthlySalaryPayments ?? [],
      productionPayments: salaryState.value?.productionPayments ?? [],
      sessions: sessions, // Include session costs (bobines + elec)
      monthStart: monthStart,
    );

    return ElyfCard(
      isGlass: true,
      borderColor: Colors.red.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 20,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Résumé Mensuel',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (monthlyTotal == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Aucune dépense ce mois-ci',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${monthlyTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} CFA',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total cumulé pour le mois en cours',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
