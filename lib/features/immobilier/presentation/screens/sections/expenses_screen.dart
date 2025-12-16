import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/domain/adapters/expense_balance_adapter.dart';
import '../../../../../shared/presentation/screens/expense_balance_screen.dart';
import '../../../application/providers.dart';
import '../../../domain/adapters/expense_balance_adapter.dart';
import '../../../domain/entities/expense.dart';
import '../../widgets/expense_card.dart';
import '../../widgets/expense_filters.dart';
import '../../widgets/expense_form_dialog.dart';
import '../../widgets/property_search_bar.dart';

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

  List<PropertyExpense> _filterAndSort(List<PropertyExpense> expenses) {
    var filtered = expenses;

    // Filtrage par recherche
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((e) {
        return e.description.toLowerCase().contains(query) ||
            (e.property?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filtrage par catégorie
    if (_selectedCategory != null) {
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }

    // Tri par date (plus récents en premier)
    filtered.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    return filtered;
  }

  void _showExpenseForm() {
    showDialog(
      context: context,
      builder: (context) => const ExpenseFormDialog(),
    );
  }

  void _showExpenseDetails(PropertyExpense expense) {
    // TODO: Ouvrir le dialog de détails
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ExpenseBalanceScreen(
                    moduleName: 'Immobilier',
                    expensesProvider: immobilierExpenseBalanceProvider,
                    adapter: ImmobilierExpenseBalanceAdapter(),
                  ),
                ),
              );
            },
            tooltip: 'Bilan des dépenses',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerRight,
              child: IntrinsicWidth(
                child: FilledButton.icon(
                  onPressed: _showExpenseForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle Dépense'),
                ),
              ),
            ),
          ),
          PropertySearchBar(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            onClear: () => setState(() {}),
          ),
          ExpenseFilters(
            selectedCategory: _selectedCategory,
            onCategoryChanged: (category) => setState(() => _selectedCategory = category),
            onClear: () => setState(() => _selectedCategory = null),
          ),
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                final filtered = _filterAndSort(expenses);
                
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          expenses.isEmpty ? Icons.receipt_long_outlined : Icons.search_off,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          expenses.isEmpty
                              ? 'Aucune dépense enregistrée'
                              : 'Aucun résultat trouvé',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (expenses.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              _selectedCategory = null;
                              setState(() {});
                            },
                            child: const Text('Réinitialiser les filtres'),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(expensesProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final expense = filtered[index];
                      return ExpenseCard(
                        expense: expense,
                        onTap: () => _showExpenseDetails(expense),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
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
                      'Erreur: $error',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        ref.invalidate(expensesProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
