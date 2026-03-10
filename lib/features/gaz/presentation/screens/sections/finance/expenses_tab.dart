import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/tour.dart';
import '../../../../domain/entities/expense.dart';
import '../../../widgets/expense_form_dialog.dart';
import '../expenses/expense_detail_dialog.dart';
import '../expenses/expenses_kpi_section.dart';
import 'widgets/unified_expense_item.dart';

class ExpensesTab extends ConsumerStatefulWidget {
  const ExpensesTab({super.key});

  @override
  ConsumerState<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<ExpensesTab> {
  
  void _showExpenseDetail(GazExpense expense) {
    showDialog(
      context: context,
      builder: (context) => ExpenseDetailDialog(expense: expense),
    );
  }

  void _showTourDetail(Tour tour) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,###');
    final dateFmt = DateFormat('dd/MM/yyyy');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Détails Tournée',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Date', dateFmt.format(tour.tourDate), theme),
              _buildInfoRow('Fournisseur', tour.supplierName ?? "Inconnu", theme),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(),
              ),
              if (tour.totalGasPurchaseCost > 0)
                _buildAmountRow('Achat gaz', tour.totalGasPurchaseCost, theme, fmt),
              if (tour.totalTransportExpenses > 0)
                _buildAmountRow('Transport', tour.totalTransportExpenses, theme, fmt),
              if (tour.totalLoadingFees > 0)
                _buildAmountRow('Frais chargement', tour.totalLoadingFees, theme, fmt),
              if (tour.totalUnloadingFees > 0)
                _buildAmountRow('Frais déchargement', tour.totalUnloadingFees, theme, fmt),
              if (tour.totalExchangeFees > 0)
                _buildAmountRow('Frais d\'échange', tour.totalExchangeFees, theme, fmt),
              if (tour.additionalInvoiceFees > 0)
                _buildAmountRow('Autres frais', tour.additionalInvoiceFees, theme, fmt),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    '${fmt.format(tour.totalExpenses.round())} CFA',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, ThemeData theme, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            '${fmt.format(amount.round())} CFA',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final enterpriseId = activeEnterprise?.id ?? '';
    final isPOS = activeEnterprise?.isPointOfSale ?? true;

    final expensesAsync = ref.watch(gazExpensesProvider);
    final toursAsync = isPOS 
        ? const AsyncValue.data(<Tour>[]) 
        : ref.watch(toursStreamProvider((enterpriseId: enterpriseId, status: TourStatus.closed)));

    return expensesAsync.when(
      data: (expenses) => toursAsync.when(
        data: (tours) {
          // Filtrer et trier
          final now = DateTime.now();
          final startOfToday = DateTime(now.year, now.month, now.day);

          final todayExpenses = expenses.where((e) => e.date.isAfter(startOfToday)).toList();
          final todayTours = tours.where((t) => t.tourDate.isAfter(startOfToday)).toList();

          final double todayTotal = todayExpenses.fold(0.0, (sum, e) => sum + e.amount) +
                                   todayTours.fold(0.0, (sum, t) => sum + t.totalExpenses);
          final int todayCount = todayExpenses.length + todayTours.length;

          final double totalExpensesVal = expenses.fold(0.0, (sum, e) => sum + e.amount) +
                                       tours.fold(0.0, (sum, t) => sum + t.totalExpenses);
          final int totalCount = expenses.length + tours.length;

          // Unified list
          final List<dynamic> unifiedList = [...expenses, ...tours];
          unifiedList.sort((a, b) {
            final dateA = a is GazExpense ? a.date : (a as Tour).tourDate;
            final dateB = b is GazExpense ? b.date : (b as Tour).tourDate;
            return dateB.compareTo(dateA);
          });

          return Column(
            children: [
              ExpensesKpiSection(
                todayTotal: todayTotal,
                todayCount: todayCount,
                totalExpenses: totalExpensesVal,
                totalCount: totalCount,
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Historique unifié',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => GazExpenseFormDialog(),
                              );
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Ajouter une dépense'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (unifiedList.isEmpty)
                        const Expanded(child: Center(child: Text('Aucune dépense enregistrée')))
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: unifiedList.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                            itemBuilder: (context, index) {
                              final item = unifiedList[index];
                              if (item is GazExpense) {
                                return UnifiedExpenseItem(
                                  expense: item,
                                  onTap: () => _showExpenseDetail(item),
                                );
                              } else {
                                return UnifiedExpenseItem(
                                  tour: item as Tour,
                                  onTap: () => _showTourDetail(item),
                                );
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => AppShimmers.list(context),
        error: (error, stack) => ErrorDisplayWidget(error: error),
      ),
      loading: () => AppShimmers.list(context),
      error: (error, stack) => ErrorDisplayWidget(error: error),
    );
  }
}
