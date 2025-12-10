import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/application/providers/treasury_providers.dart';
import '../../../../../shared/domain/adapters/expense_balance_adapter.dart';
import '../../../../../shared/presentation/screens/expense_balance_screen.dart';
import '../../../../../shared/presentation/screens/treasury_dashboard_screen.dart';
import '../../../application/controllers/finances_controller.dart';
import '../../../application/providers.dart';
import '../../../domain/adapters/expense_balance_adapter.dart';
import '../../../domain/entities/expense_record.dart';
import '../../../domain/permissions/eau_minerale_permissions.dart';
import '../../widgets/centralized_permission_guard.dart';
import '../../widgets/daily_expense_summary_card.dart';
import '../../widgets/expense_detail_dialog.dart';
import '../../widgets/expense_form.dart';
import '../../widgets/expenses_table.dart';
import '../../widgets/form_dialog.dart';
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

  String _formatCurrency(int amount) {
    final amountStr = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < amountStr.length; i++) {
      if (i > 0 && (amountStr.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(amountStr[i]);
    }
    return '${buffer.toString()} CFA';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financesStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TreasuryDashboardScreen(
                    moduleId: 'eau_minerale',
                    moduleName: 'Eau Minérale',
                  ),
                ),
              );
            },
            tooltip: 'Trésorerie',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
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
            tooltip: 'Bilan des dépenses',
          ),
        ],
      ),
      body: state.when(
        data: (data) => _ExpensesContent(
          state: data,
          onNewExpense: () => _showForm(context),
          formatCurrency: _formatCurrency,
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
    required this.onNewExpense,
    required this.formatCurrency,
    required this.onActionTap,
  });

  final FinancesState state;
  final VoidCallback onNewExpense;
  final String Function(int) formatCurrency;
  final void Function(ExpenseRecord expense, String action) onActionTap;

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
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  isWide ? 24 : 16,
                ),
                child: Row(
                  children: [
                    Text(
                      'Gestion des Dépenses',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    EauMineralePermissionGuard(
                      permission: EauMineralePermissions.createExpense,
                      child: IntrinsicWidth(
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
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        );
      },
    );
  }
}
