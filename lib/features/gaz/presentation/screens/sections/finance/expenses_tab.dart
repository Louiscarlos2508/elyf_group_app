import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../../domain/entities/expense.dart';
import '../../../widgets/expense_form_dialog.dart';
import '../expenses/expense_detail_dialog.dart';
import '../expenses/expenses_category_tab.dart';
import '../expenses/expenses_history_tab.dart';
import '../expenses/expenses_kpi_section.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_financial_calculation_service.dart';
import 'tour_expenses_tab.dart';

class ExpensesTab extends ConsumerStatefulWidget {
  const ExpensesTab({super.key});

  @override
  ConsumerState<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<ExpensesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _showNewExpenseDialog() {
    try {
      showDialog(
        context: context,
        builder: (_) => const GazExpenseFormDialog(),
      );
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'ouverture du dialog de dépense: $e',
        name: 'gaz.finance.expenses',
        error: e,
      );
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    }
  }

  void _showExpenseDetail(GazExpense expense) {
    showDialog(
      context: context,
      builder: (context) => ExpenseDetailDialog(expense: expense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(gazExpensesProvider);

    return expensesAsync.when(
      data: (expenses) {
        final todayTotal =
            GazFinancialCalculationService.calculateTodayExpensesTotal(
              expenses,
            );
        final todayExpenses =
            GazFinancialCalculationService.calculateTodayExpenses(expenses);
        final totalExpenses =
            GazFinancialCalculationService.calculateTotalExpenses(expenses);

        return Column(
          children: [
            // KPI Cards
            ExpensesKpiSection(
              todayTotal: todayTotal,
              todayCount: todayExpenses.length,
              totalExpenses: totalExpenses,
              totalCount: expenses.length,
            ),

            // Nested Tabs: Historique | Tournées | Par catégorie
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Dépenses'),
                  Tab(text: 'Tournées'),
                  Tab(text: 'Par catégorie'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ExpensesHistoryTab(
                    expenses: expenses,
                    onExpenseTap: _showExpenseDetail,
                  ),
                  const TourExpensesTab(),
                  ExpensesCategoryTab(expenses: expenses),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => AppShimmers.list(context),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        title: 'Erreur de chargement des dépenses',
        onRetry: () => ref.refresh(gazExpensesProvider),
      ),
    );
  }
}
