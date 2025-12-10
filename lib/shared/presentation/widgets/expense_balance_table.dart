import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/domain/entities/expense_balance_data.dart';

/// Widget pour afficher un tableau des dépenses.
class ExpenseBalanceTable extends StatelessWidget {
  const ExpenseBalanceTable({
    super.key,
    required this.expenses,
    required this.getCategoryLabel,
  });

  final List<ExpenseBalanceData> expenses;
  final String Function(String) getCategoryLabel;

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Aucune dépense trouvée'),
          ),
        ),
      );
    }

    final sortedExpenses = List<ExpenseBalanceData>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Détail des dépenses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Libellé')),
                DataColumn(label: Text('Catégorie')),
                DataColumn(label: Text('Montant'), numeric: true),
              ],
              rows: sortedExpenses.map((expense) {
                return DataRow(
                  cells: [
                    DataCell(Text(_formatDate(expense.date))),
                    DataCell(Text(expense.label)),
                    DataCell(Text(getCategoryLabel(expense.category))),
                    DataCell(Text(
                      _formatCurrency(expense.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

