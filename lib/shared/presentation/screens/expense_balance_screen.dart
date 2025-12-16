import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import '../../../core/domain/entities/expense_balance_data.dart';
import '../../../core/pdf/expense_balance_pdf_service.dart';
import '../../domain/adapters/expense_balance_adapter.dart';
import '../widgets/expense_balance_chart.dart';
import '../widgets/expense_balance_filters.dart';
import '../widgets/expense_balance_summary.dart';
import '../widgets/expense_balance_table.dart';

/// Écran générique pour le bilan effectif des dépenses.
class ExpenseBalanceScreen extends ConsumerStatefulWidget {
  const ExpenseBalanceScreen({
    super.key,
    required this.moduleName,
    required this.expensesProvider,
    required this.adapter,
  });

  final String moduleName;
  final dynamic expensesProvider; // Provider that returns AsyncValue<List<ExpenseBalanceData>>
  final ExpenseBalanceAdapter adapter;

  @override
  ConsumerState<ExpenseBalanceScreen> createState() =>
      _ExpenseBalanceScreenState();
}

class _ExpenseBalanceScreenState
    extends ConsumerState<ExpenseBalanceScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _selectedCategories = widget.adapter.getCategories().toSet();
  }

  List<ExpenseBalanceData> _filterExpenses(List<ExpenseBalanceData> expenses) {
    return expenses.where((expense) {
      final dateOk = expense.date.isAfter(_startDate.subtract(
            const Duration(days: 1),
          )) &&
          expense.date.isBefore(_endDate.add(const Duration(days: 1)));
      final categoryOk = _selectedCategories.isEmpty ||
          _selectedCategories.contains(expense.category);
      return dateOk && categoryOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(widget.expensesProvider) as AsyncValue<List<ExpenseBalanceData>>;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bilan des dépenses - ${widget.moduleName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadPdf(context, expensesAsync),
            tooltip: 'Télécharger PDF',
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (allExpenses) {
          final filteredExpenses = _filterExpenses(allExpenses);
          final totalAmount = filteredExpenses.fold<int>(
            0,
            (sum, expense) => sum + expense.amount,
          );

          return Column(
            children: [
              ExpenseBalanceFilters(
                startDate: _startDate,
                endDate: _endDate,
                selectedCategories: _selectedCategories,
                allCategories: widget.adapter.getCategories(),
                getCategoryLabel: widget.adapter.getCategoryLabel,
                onStartDateChanged: (date) {
                  setState(() => _startDate = date);
                },
                onEndDateChanged: (date) {
                  setState(() => _endDate = date);
                },
                onCategoriesChanged: (categories) {
                  setState(() => _selectedCategories = categories);
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExpenseBalanceSummary(
                        totalAmount: totalAmount,
                        expenseCount: filteredExpenses.length,
                        startDate: _startDate,
                        endDate: _endDate,
                      ),
                      const SizedBox(height: 24),
                      ExpenseBalanceChart(expenses: filteredExpenses),
                      const SizedBox(height: 24),
                      ExpenseBalanceTable(
                        expenses: filteredExpenses,
                        getCategoryLabel: widget.adapter.getCategoryLabel,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf(
    BuildContext context,
    AsyncValue<List<ExpenseBalanceData>> expensesAsync,
  ) async {
    expensesAsync.whenData((allExpenses) async {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final filteredExpenses = _filterExpenses(allExpenses);
        final pdfService = ExpenseBalancePdfService();
        final file = await pdfService.generateReport(
          moduleName: widget.moduleName,
          expenses: filteredExpenses,
          startDate: _startDate,
          endDate: _endDate,
          getCategoryLabel: widget.adapter.getCategoryLabel,
        );

        if (context.mounted) {
          Navigator.of(context).pop();
          final result = await OpenFile.open(file.path);
          if (result.type != ResultType.done && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF généré: ${file.path}'),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la génération PDF: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }
}

