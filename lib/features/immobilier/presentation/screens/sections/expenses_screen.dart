import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../../domain/adapters/expense_balance_adapter.dart';
import '../../../domain/entities/expense.dart';
import '../../widgets/daily_expense_summary_card_v2.dart';
import '../../widgets/expense_form_dialog.dart' as immobilier_widgets;
import '../../widgets/expenses_table_v2.dart';
import '../../widgets/monthly_expense_summary_v2.dart';

/// Expenses screen with professional UI - style Boutique/Eau Minérale.
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  List<PropertyExpense> _getTodayExpenses(
    List<PropertyExpense> expenses,
    WidgetRef ref,
  ) {
    // Utiliser le service de filtrage pour extraire la logique métier
    final filterService = ref.read(expenseFilterServiceProvider);
    return filterService.filterTodayExpenses(expenses);
  }

  int _getTodayTotal(List<PropertyExpense> expenses, WidgetRef ref) {
    // Utiliser le service de filtrage pour extraire la logique métier
    final filterService = ref.read(expenseFilterServiceProvider);
    return filterService.calculateTodayTotal(expenses);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      body: expensesAsync.when(
        data: (expenses) {
          final todayExpenses = _getTodayExpenses(expenses, ref);
          final todayTotal = _getTodayTotal(expenses, ref);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        isWide ? AppSpacing.lg : AppSpacing.md,
                      ),
                      child: isWide
                          ? Row(
                              children: [
                                Text(
                                  'Dépenses',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                RefreshButton(
                                  onRefresh: () =>
                                      ref.invalidate(expensesProvider),
                                  tooltip: 'Actualiser les dépenses',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.analytics),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ExpenseBalanceScreen(
                                          moduleName: 'Immobilier',
                                          expensesProvider:
                                              immobilierExpenseBalanceProvider,
                                          adapter:
                                              ImmobilierExpenseBalanceAdapter(),
                                        ),
                                      ),
                                    );
                                  },
                                  tooltip: 'Bilan des dépenses',
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) =>
                                            const immobilier_widgets.ExpenseFormDialog(),
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
                                          ref.invalidate(expensesProvider),
                                      tooltip: 'Actualiser les dépenses',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.analytics),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => ExpenseBalanceScreen(
                                              moduleName: 'Immobilier',
                                              expensesProvider:
                                                  immobilierExpenseBalanceProvider,
                                              adapter:
                                                  ImmobilierExpenseBalanceAdapter(),
                                            ),
                                          ),
                                        );
                                      },
                                      tooltip: 'Bilan des dépenses',
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
                                            const immobilier_widgets.ExpenseFormDialog(),
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
                      child: DailyExpenseSummaryCardV2(
                        total: todayTotal,
                        formatCurrency: CurrencyFormatter.formatFCFA,
                      ),
                    ),
                  ),

                  // Today's expenses table
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
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
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: ExpensesTableV2(
                              expenses: todayExpenses,
                              formatCurrency: CurrencyFormatter.formatFCFA,
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
                      child: MonthlyExpenseSummaryV2(expenses: expenses),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.lg),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorDisplayWidget(
          error: error,
          title: 'Erreur de chargement',
          message: 'Impossible de charger les dépenses.',
          onRetry: () => ref.refresh(expensesProvider),
        ),
      ),
    );
  }

  void _showExpenseDetail(BuildContext context, PropertyExpense expense) {
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
              CurrencyFormatter.formatFCFA(expense.amount),
            ),
            _buildDetailRow(
              theme,
              'Catégorie',
              _getCategoryLabel(expense.category),
            ),
            _buildDetailRow(
              theme,
              'Date',
              '${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}',
            ),
            if (expense.property != null)
              _buildDetailRow(theme, 'Propriété', expense.property!),
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

  String _getCategoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.repair:
        return 'Réparation';
      case ExpenseCategory.utilities:
        return 'Services publics';
      case ExpenseCategory.insurance:
        return 'Assurance';
      case ExpenseCategory.taxes:
        return 'Taxes';
      case ExpenseCategory.cleaning:
        return 'Nettoyage';
      case ExpenseCategory.other:
        return 'Autres';
    }
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PropertyExpense expense,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la dépense ?'),
        content: Text(
          'Voulez-vous vraiment supprimer "${expense.description}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(expenseControllerProvider)
                  .deleteExpense(expense.id);
              ref.invalidate(expensesProvider);
              if (context.mounted) {
                Navigator.of(context).pop();
                NotificationService.showSuccess(context, 'Dépense supprimée');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
