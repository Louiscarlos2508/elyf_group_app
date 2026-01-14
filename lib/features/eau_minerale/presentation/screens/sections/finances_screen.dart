import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../../core/permissions/modules/eau_minerale_permissions.dart';
import '../../../application/controllers/finances_controller.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/adapters/expense_balance_adapter.dart';
import '../../../domain/entities/expense_record.dart';
import '../../widgets/centralized_permission_guard.dart';
import '../../widgets/daily_expense_summary_card.dart';
import '../../widgets/expense_detail_dialog.dart';
import '../../widgets/expense_form.dart';
import '../../widgets/expenses_table.dart';
import '../../widgets/monthly_expense_summary.dart';
import '../../widgets/section_placeholder.dart';

class FinancesScreen extends ConsumerWidget {
  const FinancesScreen({super.key});

  void _showForm(BuildContext context) {
    final formKey = GlobalKey<ExpenseFormState>();
    showDialog(
      context: context,
      builder: (context) => FormDialog(
        title: 'Nouvelle dépense',
        child: ExpenseForm(key: formKey),
        onSave: () async {
          final state = formKey.currentState;
          if (state != null) {
            await state.submit();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financesStateProvider);
    return Scaffold(
      body: state.when(
        data: (data) => _ExpensesContent(
          state: data,
          ref: ref,
          onNewExpense: () => _showForm(context),
          formatCurrency: CurrencyFormatter.formatCFA,
          onActionTap: (expense, action) {
            if (action == 'view') {
              showDialog(
                context: context,
                builder: (context) => ExpenseDetailDialog(expense: expense),
              );
            } else if (action == 'edit') {
              final formKey = GlobalKey<ExpenseFormState>();
              showDialog(
                context: context,
                builder: (context) => FormDialog(
                  title: 'Modifier la dépense',
                  child: ExpenseForm(key: formKey, expense: expense),
                  onSave: () async {
                    final state = formKey.currentState;
                    if (state != null) {
                      await state.submit();
                    }
                  },
                ),
              );
            }
          },
          onBalanceTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ExpenseBalanceScreen(
                  moduleName: 'Eau Minérale',
                  expensesProvider: eauMineraleExpenseBalanceProvider,
                  adapter: EauMineraleExpenseBalanceAdapter(),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => SectionPlaceholder(
          icon: Icons.account_balance,
          title: 'Charges indisponibles',
          subtitle: 'Impossible de charger les dernières dépenses.',
          primaryActionLabel: 'Réessayer',
          onPrimaryAction: () => ref.invalidate(financesStateProvider),
        ),
      ),
    );
  }
}

class _ExpensesContent extends StatelessWidget {
  const _ExpensesContent({
    required this.state,
    required this.ref,
    required this.onNewExpense,
    required this.formatCurrency,
    required this.onActionTap,
    required this.onBalanceTap,
  });

  final FinancesState state;
  final WidgetRef ref;
  final VoidCallback onNewExpense;
  final String Function(int) formatCurrency;
  final void Function(ExpenseRecord expense, String action) onActionTap;
  final VoidCallback onBalanceTap;

  List<ExpenseRecord> _getTodayExpenses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return state.expenses.where((e) {
      final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
      return expenseDate.isAtSameMomentAs(today);
    }).toList();
  }

  int _getTodayTotal() {
    return _getTodayExpenses().fold(0, (sum, e) => sum + e.amountCfa);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayExpenses = _getTodayExpenses();
    final todayTotal = _getTodayTotal();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, isWide ? 24 : 16),
                child: isWide
                    ? Row(
                        children: [
                          Text(
                            'Dépenses',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          RefreshButton(
                            onRefresh: () =>
                                ref.invalidate(financesStateProvider),
                            tooltip: 'Actualiser les dépenses',
                          ),
                          IconButton(
                            icon: const Icon(Icons.analytics),
                            onPressed: onBalanceTap,
                            tooltip: 'Bilan des dépenses',
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: EauMineralePermissionGuard(
                              permission: EauMineralePermissions.createExpense,
                              child: FilledButton.icon(
                                onPressed: onNewExpense,
                                icon: const Icon(Icons.add),
                                label: const Text('Nouvelle Dépense'),
                              ),
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
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              RefreshButton(
                                onRefresh: () =>
                                    ref.invalidate(financesStateProvider),
                                tooltip: 'Actualiser les dépenses',
                              ),
                              IconButton(
                                icon: const Icon(Icons.analytics),
                                onPressed: onBalanceTap,
                                tooltip: 'Bilan des dépenses',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          EauMineralePermissionGuard(
                            permission: EauMineralePermissions.createExpense,
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: onNewExpense,
                                icon: const Icon(Icons.add),
                                label: const Text('Nouvelle Dépense'),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: DailyExpenseSummaryCard(
                  total: todayTotal,
                  formatCurrency: formatCurrency,
                ),
              ),
            ),
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
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: ExpensesTable(
                        expenses: todayExpenses,
                        formatCurrency: formatCurrency,
                        onActionTap: onActionTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: MonthlyExpenseSummary(expenses: state.expenses),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}
