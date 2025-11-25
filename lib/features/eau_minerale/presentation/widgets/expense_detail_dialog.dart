import 'package:flutter/material.dart';

import '../../domain/entities/expense_record.dart';

/// Dialog showing expense details.
class ExpenseDetailDialog extends StatelessWidget {
  const ExpenseDetailDialog({
    super.key,
    required this.expense,
  });

  final ExpenseRecord expense;

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' CFA';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getCategoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.logistics:
        return 'Logistique';
      case ExpenseCategory.payroll:
        return 'Salaires';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.utility:
        return 'Services publics';
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.logistics:
        return Icons.local_shipping;
      case ExpenseCategory.payroll:
        return Icons.payments;
      case ExpenseCategory.maintenance:
        return Icons.build;
      case ExpenseCategory.utility:
        return Icons.bolt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Détails de la Dépense',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _DetailRow(
                  label: 'Libellé',
                  value: expense.label,
                  icon: Icons.receipt_long,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DetailRow(
                        label: 'Catégorie',
                        value: _getCategoryLabel(expense.category),
                        icon: _getCategoryIcon(expense.category),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DetailRow(
                        label: 'Montant',
                        value: _formatCurrency(expense.amountCfa),
                        icon: Icons.attach_money,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: 'Date',
                  value: _formatDate(expense.date),
                  icon: Icons.calendar_today,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

