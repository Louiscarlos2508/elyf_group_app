import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/gaz_button_styles.dart';
import '../../../application/providers.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/services/gaz_calculation_service.dart';
import '../../widgets/expense_form_dialog.dart';
import 'expenses/expense_detail_dialog.dart';
import 'expenses/expenses_category_tab.dart';
import 'expenses/expenses_header.dart';
import 'expenses/expenses_history_tab.dart';
import 'expenses/expenses_kpi_section.dart';
import 'expenses/expenses_tab_bar.dart';

/// Expenses screen - matches Figma design.
class GazExpensesScreen extends ConsumerStatefulWidget {
  const GazExpensesScreen({super.key});

  @override
  ConsumerState<GazExpensesScreen> createState() =>
      _GazExpensesScreenState();
}

class _GazExpensesScreenState extends ConsumerState<GazExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _showNewExpenseDialog() {
    try {
      showDialog(
        context: context,
        builder: (_) => const GazExpenseFormDialog(),
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture du dialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final expensesAsync = ref.watch(gazExpensesProvider);

    return Container(
      color: const Color(0xFFF9FAFB),
      child: expensesAsync.when(
        data: (expenses) {
          // Utiliser le service pour les calculs
          final todayExpenses =
              GazCalculationService.calculateTodayExpenses(expenses);
          final todayTotal =
              GazCalculationService.calculateTodayExpensesTotal(expenses);
          final totalExpenses =
              GazCalculationService.calculateTotalExpenses(expenses);

          return Column(
            children: [
              // Header
              ExpensesHeader(
                isMobile: isMobile,
                onNewExpense: _showNewExpenseDialog,
              ),
              // KPI Cards
              ExpensesKpiSection(
                todayTotal: todayTotal,
                todayCount: todayExpenses.length,
                totalExpenses: totalExpenses,
                totalCount: expenses.length,
              ),
              // Tabs and content
              Expanded(
                child: Column(
                  children: [
                    // Custom tab bar
                    ExpensesTabBar(tabController: _tabController),
                    // Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          ExpensesHistoryTab(
                            expenses: expenses,
                            onExpenseTap: _showExpenseDetail,
                          ),
                          ExpensesCategoryTab(expenses: expenses),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                style: GazButtonStyles.filledPrimary,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
