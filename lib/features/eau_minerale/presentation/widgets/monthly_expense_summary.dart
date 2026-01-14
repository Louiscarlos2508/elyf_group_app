import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/expense_record.dart';

/// Widget displaying monthly expense summary.
class MonthlyExpenseSummary extends ConsumerWidget {
  const MonthlyExpenseSummary({super.key, required this.expenses});

  final List<ExpenseRecord> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Utiliser le service de calcul pour extraire la logique métier
    final calculationService = ref.read(dashboardCalculationServiceProvider);
    final now = DateTime.now();
    final monthStart = calculationService.getMonthStart(now);
    final monthlyTotal = calculationService.calculateMonthlyExpensesFromRecords(
      expenses,
      monthStart,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé Mensuel',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (monthlyTotal == 0)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Text(
                  'Aucune dépense ce mois-ci',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '${monthlyTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
