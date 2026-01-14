import 'package:flutter/material.dart';

import '../../../core/domain/entities/expense_balance_data.dart';

/// Widget pour afficher un graphique des dépenses par catégorie.
class ExpenseBalanceChart extends StatelessWidget {
  const ExpenseBalanceChart({super.key, required this.expenses});

  final List<ExpenseBalanceData> expenses;

  Map<String, int> _getCategoryTotals() {
    final totals = <String, int>{};
    for (final expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _getCategoryTotals();
    if (categoryTotals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Aucune donnée à afficher')),
        ),
      );
    }

    final total = categoryTotals.values.fold<int>(
      0,
      (sum, amount) => sum + amount,
    );
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition par catégorie',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.map((entry) {
              final percentage = (entry.value / total * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${entry.value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA (${percentage.toStringAsFixed(1)}%)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
