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
import '../../widgets/expense_filters.dart';
import '../../widgets/immobilier_header.dart';
import '../../widgets/property_search_bar.dart'; // Import correct

/// Expenses screen with professional UI - style Boutique/Eau Minérale.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _searchController = TextEditingController();
  ExpenseCategory? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PropertyExpense> _filterExpenses(List<PropertyExpense> expenses) {
    var filtered = expenses;
    
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((e) => 
        e.description.toLowerCase().contains(query) ||
        (e.property?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    if (_selectedCategory != null) {
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }

    filtered.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return filtered;
  }

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const immobilier_widgets.ExpenseFormDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle'),
      ),
      body: expensesAsync.when(
        data: (expenses) {
          final filteredExpenses = _filterExpenses(expenses);
          final todayExpenses = _getTodayExpenses(expenses, ref);
          final todayTotal = _getTodayTotal(expenses, ref);
          final archiveFilter = ref.watch(archiveFilterProvider);
          final hasFilters = _selectedCategory != null || _searchController.text.isNotEmpty || archiveFilter != ArchiveFilter.active;

          return LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                slivers: [
                  // Header
                  ImmobilierHeader(
                    title: 'DÉPENSES',
                    subtitle: 'Gestion des charges',
                    actions: [
                      Semantics(
                        label: 'Actualiser',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () => ref.invalidate(expensesProvider),
                          tooltip: 'Actualiser',
                        ),
                      ),
                      Semantics(
                        label: 'Bilan des dépenses',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.analytics, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ExpenseBalanceScreen(
                                  moduleName: 'Immobilier',
                                  expensesProvider:
                                      immobilierExpenseBalanceProvider,
                                  adapter: ImmobilierExpenseBalanceAdapter(),
                                ),
                              ),
                            );
                          },
                          tooltip: 'Bilan des dépenses',
                        ),
                      ),
                    ],
                  ),

                  // Filters & Search
                  SliverToBoxAdapter(
                    child: PropertySearchBar(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      onClear: () => setState(() {}),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ExpenseFilters(
                      selectedCategory: _selectedCategory,
                      selectedArchiveFilter: archiveFilter,
                      onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
                      onArchiveFilterChanged: (filter) => ref.read(archiveFilterProvider.notifier).set(filter),
                      onClear: () {
                        setState(() {
                          _selectedCategory = null;
                          _searchController.clear();
                        });
                        ref.read(archiveFilterProvider.notifier).set(ArchiveFilter.active);
                      },
                    ),
                  ),

                  if (!hasFilters) ...[
                    // Daily summary card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                          AppSpacing.md,
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
                            _buildExpensesTable(theme, todayExpenses),
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
                  ] else ...[
                    // Filtered results
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                        child: Text(
                          'Résultats du filtrage (${filteredExpenses.length})',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: _buildExpensesTable(theme, filteredExpenses),
                      ),
                    ),
                  ],

                  SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl),
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
    final isDeleted = expense.deletedAt != null;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDeleted ? 'Restaurer la dépense ?' : 'Supprimer la dépense ?'),
        content: Text(
          isDeleted 
            ? 'Voulez-vous restaurer "${expense.description}" ?'
            : 'Voulez-vous vraiment supprimer "${expense.description}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final controller = ref.read(expenseControllerProvider);
              if (expense.deletedAt == null) {
                await controller.deleteExpense(expense.id);
              } else {
                await controller.restoreExpense(expense.id);
              }
              ref.invalidate(expensesProvider);
              if (context.mounted) {
                Navigator.of(context).pop();
                NotificationService.showSuccess(context, 'Dépense mise à jour');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isDeleted ? 'Restaurer' : 'Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTable(ThemeData theme, List<PropertyExpense> expenses) {
    return Container(
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
        expenses: expenses,
        formatCurrency: CurrencyFormatter.formatFCFA,
        onActionTap: (expense, action) {
          if (action == 'delete') {
            _confirmDelete(context, ref, expense);
          } else if (action == 'view') {
            _showExpenseDetail(context, expense);
          }
        },
      ),
    );
  }
}
