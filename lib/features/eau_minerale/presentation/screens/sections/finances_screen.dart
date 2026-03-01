import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../core/permissions/modules/eau_minerale_permissions.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/adapters/expense_balance_adapter.dart';
import '../../widgets/centralized_permission_guard.dart';
import '../../widgets/daily_expense_summary_card.dart';
import '../../widgets/expense_detail_dialog.dart';
import '../../widgets/expense_form.dart';
import '../../widgets/expenses_table.dart';
import '../../widgets/monthly_expense_summary.dart';

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
    return state.when(
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
      loading: () => const LoadingIndicator(),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        title: 'Charges indisponibles',
        message: 'Impossible de charger les dernières dépenses.',
        onRetry: () => ref.refresh(financesStateProvider),
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
        return CustomScrollView(
          slivers: [
            // Premium Header for Finances
            ElyfModuleHeader(
              title: "Dépenses & Charges",
              subtitle: "Gérez vos charges opérationnelles et suivez l'équilibre financier de votre production.",
              module: EnterpriseModule.eau,
              actions: [
                IconButton(
                  icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                  onPressed: onBalanceTap,
                  tooltip: 'Bilan',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => ref.invalidate(financesStateProvider),
                  tooltip: 'Actualiser',
                ),
              ],
              bottom: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: EauMineralePermissionGuard(
                  permission: EauMineralePermissions.createExpense,
                  child: FilledButton.icon(
                    onPressed: onNewExpense,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_card_rounded, size: 22),
                    label: const Text(
                      'Enregistrer une Dépense',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Daily Summary
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: DailyExpenseSummaryCard(
                  total: todayTotal,
                  formatCurrency: formatCurrency,
                ),
              ),
            ),

            // Today's Table
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 16, bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.today_rounded,
                            size: 18,
                            color: theme.colorScheme.primary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Dépenses du Jour',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ExpensesTable(
                      expenses: todayExpenses,
                      formatCurrency: formatCurrency,
                      onActionTap: onActionTap,
                    ),
                  ],
                ),
              ),
            ),

            // Monthly Summary
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: MonthlyExpenseSummary(expenses: state.expenses),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }
}
