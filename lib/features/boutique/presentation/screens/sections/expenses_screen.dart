import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/permissions/modules/boutique_permissions.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import '../../../domain/adapters/expense_balance_adapter.dart';
import '../../../domain/entities/expense.dart';
import '../../widgets/daily_expense_summary_card.dart';
import '../../widgets/expense_form_dialog.dart' as boutique;
import '../../widgets/expenses_table.dart';
import '../../widgets/monthly_expense_summary.dart';
import '../../widgets/permission_guard.dart';
import '../../widgets/boutique_header.dart';
import 'package:open_file/open_file.dart';

/// Expenses screen with professional UI - style eau_minerale.
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  List<Expense> _getTodayExpenses(List<Expense> expenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expenses.where((e) {
      final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
      return expenseDate.isAtSameMomentAs(today);
    }).toList();
  }

  int _getTodayTotal(List<Expense> expenses) {
    return _getTodayExpenses(expenses).fold(0, (sum, e) => sum + e.amountCfa);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      body: expensesAsync.when(
        data: (expenses) {
          final todayExpenses = _getTodayExpenses(expenses);
          final todayTotal = _getTodayTotal(expenses);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;

              return CustomScrollView(
                slivers: [
                  // Header
                  BoutiqueHeader(
                    title: "GESTION FINANCIÈRE",
                    subtitle: "Dépenses & Charges",
                    gradientColors: [
                      const Color(0xFFDC2626), // Red 600
                      const Color(0xFFB91C1C), // Red 700
                    ],
                    shadowColor: const Color(0xFFDC2626),
                    additionalActions: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () => ref.invalidate(expensesProvider),
                          tooltip: 'Actualiser les dépenses',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.analytics, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ExpenseBalanceScreen(
                                  moduleName: 'Boutique',
                                  expensesProvider:
                                      boutiqueExpenseBalanceProvider,
                                  adapter: BoutiqueExpenseBalanceAdapter(),
                                ),
                              ),
                            );
                          },
                          tooltip: 'Bilan des dépenses',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.download, color: Colors.white),
                          onPressed: () => _exportData(context, ref, expenses),
                          tooltip: 'Exporter CSV',
                        ),
                      ),
                      if (isWide) ...[
                        const SizedBox(width: 8),
                        BoutiquePermissionGuard(
                          permission: BoutiquePermissions.createExpense,
                          child: FilledButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    const boutique.ExpenseFormDialog(),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Nouvelle Dépense'),
                          ),
                        ),
                      ],
                    ],
                    bottom: isWide
                        ? null
                        : BoutiquePermissionGuard(
                            permission: BoutiquePermissions.createExpense,
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) =>
                                        const boutique.ExpenseFormDialog(),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text('Nouvelle Dépense'),
                              ),
                            ),
                          ),
                  ),

                  // Daily summary card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.horizontalPadding,
                      child: DailyExpenseSummaryCard(
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
                            child: ExpensesTable(
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
                      padding: AppSpacing.horizontalPadding,
                      child: Builder(
                        builder: (context) {
                          final calculationService = ref.read(
                            boutiqueCalculationServiceProvider,
                          );
                          final metrics = calculationService
                              .calculateMonthlyExpenseMetrics(expenses);
                          return MonthlyExpenseSummary(
                            metrics: metrics,
                            calculationService: calculationService,
                          );
                        },
                      ),
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
        loading: () => AppShimmers.table(context),
        error: (error, stackTrace) => ErrorDisplayWidget(
          error: error,
          title: 'Erreur de chargement',
          message: 'Impossible de charger les dépenses.',
          onRetry: () => ref.refresh(expensesProvider),
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref, List<Expense> expenses) async {
    final exportService = ref.read(boutiqueExportServiceProvider);
    try {
      final file = await exportService.exportExpenses(expenses);
      if (context.mounted) {
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, 'Erreur lors de l\'export: $e');
      }
    }
  }

  void _showExpenseDetail(BuildContext context, Expense expense) {
    final theme = Theme.of(context);
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(expense.label),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                theme,
                'Montant',
                CurrencyFormatter.formatFCFA(expense.amountCfa),
              ),
              _buildDetailRow(
                theme,
                'Cat\u00e9gorie',
                _getCategoryLabel(expense.category),
              ),
              _buildDetailRow(
                theme,
                'Date',
                '${expense.date.day}/${expense.date.month}/${expense.date.year}',
              ),
              if (expense.notes != null)
                _buildDetailRow(theme, 'Notes', expense.notes!),
              if (expense.receiptPath != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Re\u00e7u',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(expense.receiptPath!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ],
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
      case ExpenseCategory.stock:
        return 'Stock/Achats';
      case ExpenseCategory.rent:
        return 'Loyer';
      case ExpenseCategory.utilities:
        return 'Services publics';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.other:
        return 'Autres';
    }
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    // Vérifier la permission avant d'afficher le dialogue
    final adapter = ref.read(boutiquePermissionAdapterProvider);
    final hasPermission = await adapter.hasPermission(
      BoutiquePermissions.deleteExpense.id,
    );

    if (!hasPermission) {
      if (context.mounted) {
        NotificationService.showError(
          context,
          'Vous n\'avez pas la permission de supprimer des dépenses.',
        );
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la dépense ?'),
        content: Text('Voulez-vous vraiment supprimer "${expense.label}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(storeControllerProvider).deleteExpense(expense.id);
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
}
