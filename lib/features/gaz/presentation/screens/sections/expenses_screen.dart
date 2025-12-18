import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/presentation/widgets/refresh_button.dart';
import '../../../application/controllers/expense_controller.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/expense.dart';
import '../../widgets/daily_expense_summary_card.dart';
import '../../widgets/expense_form_dialog.dart';
import '../../widgets/expenses_table.dart';
import '../../widgets/monthly_expense_summary.dart';

/// Expenses screen with professional UI - style boutique.
class GazExpensesScreen extends ConsumerWidget {
  const GazExpensesScreen({super.key});

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) +
        ' F';
  }

  List<GazExpense> _getTodayExpenses(List<GazExpense> expenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expenses.where((e) {
      final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
      return expenseDate.isAtSameMomentAs(today);
    }).toList();
  }

  double _getTodayTotal(List<GazExpense> expenses) {
    return _getTodayExpenses(expenses).fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(gazExpensesProvider);

    return Scaffold(
      body: expensesAsync.when(
        data: (expenses) {
          final todayExpenses = _getTodayExpenses(expenses);
          final todayTotal = _getTodayTotal(expenses);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        24,
                        24,
                        isWide ? 24 : 16,
                      ),
                      child: isWide
                          ? Row(
                              children: [
                                Text(
                                  'Dépenses',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                RefreshButton(
                                  onRefresh: () =>
                                      ref.invalidate(gazExpensesProvider),
                                  tooltip: 'Actualiser les dépenses',
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) =>
                                            const GazExpenseFormDialog(),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Nouvelle Dépense'),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Dépenses',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    RefreshButton(
                                      onRefresh: () =>
                                          ref.invalidate(gazExpensesProvider),
                                      tooltip: 'Actualiser les dépenses',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) =>
                                            const GazExpenseFormDialog(),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Nouvelle Dépense'),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // Daily summary card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GazDailyExpenseSummaryCard(
                        total: todayTotal,
                        formatCurrency: _formatCurrency,
                      ),
                    ),
                  ),

                  // Today's expenses table
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dépenses du Jour',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: GazExpensesTable(
                              expenses: todayExpenses,
                              formatCurrency: _formatCurrency,
                              onActionTap: (expense, action) {
                                if (action == 'delete') {
                                  _confirmDelete(context, ref, expense);
                                } else if (action == 'view') {
                                  _showExpenseDetail(context, expense);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Monthly summary
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GazMonthlyExpenseSummary(expenses: expenses),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(gazExpensesProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseDetail(BuildContext context, GazExpense expense) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense.description),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              theme,
              'Montant',
              _formatCurrency(expense.amount),
            ),
            _buildDetailRow(
              theme,
              'Catégorie',
              expense.category.label,
            ),
            _buildDetailRow(
              theme,
              'Date',
              '${expense.date.day}/${expense.date.month}/${expense.date.year}',
            ),
            if (expense.notes != null)
              _buildDetailRow(theme, 'Notes', expense.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    GazExpense expense,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la dépense ?'),
        content: Text('Voulez-vous vraiment supprimer "${expense.description}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(expenseControllerProvider).deleteExpense(expense.id);
              ref.invalidate(gazExpensesProvider);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dépense supprimée'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
