import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../domain/entities/payment.dart';

/// Profit report content for immobilier.
class ProfitReportContent extends ConsumerWidget {
  const ProfitReportContent({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paymentsAsync = ref.watch(paymentsProvider);
    final expensesAsync = ref.watch(expensesProvider);

    return paymentsAsync.when(
      data: (payments) {
        final periodPayments = payments.where((p) {
          return p.paymentDate.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              p.paymentDate.isBefore(endDate.add(const Duration(days: 1))) &&
              p.status == PaymentStatus.paid;
        }).toList();

        final totalRevenue = periodPayments.fold(0, (sum, p) => sum + p.amount);

        return expensesAsync.when(
          data: (expenses) {
            final periodExpenses = expenses.where((e) {
              return e.expenseDate.isAfter(
                    startDate.subtract(const Duration(days: 1)),
                  ) &&
                  e.expenseDate.isBefore(endDate.add(const Duration(days: 1)));
            }).toList();

            final totalExpenses = periodExpenses.fold(
              0,
              (sum, e) => sum + e.amount,
            );
            final profit = totalRevenue - totalExpenses;

            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Résumé Financier',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Revenue
                  _buildFinancialRow(
                    theme,
                    label: 'Revenus Locatifs',
                    value: totalRevenue,
                    count: periodPayments.length,
                    countLabel: 'paiements',
                    color: const Color(0xFF10B981),
                    icon: Icons.trending_up,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),

                  // Expenses
                  _buildFinancialRow(
                    theme,
                    label: 'Dépenses',
                    value: totalExpenses,
                    count: periodExpenses.length,
                    countLabel: 'charges',
                    color: theme.colorScheme.error,
                    icon: Icons.trending_down,
                    isExpense: true,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(thickness: 2),
                  ),

                  // Profit
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (profit >= 0 ? const Color(0xFF10B981) : theme.colorScheme.error)
                          .withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (profit >= 0 ? const Color(0xFF10B981) : theme.colorScheme.error)
                            .withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          profit >= 0
                              ? Icons.account_balance_wallet
                              : Icons.warning,
                          color: profit >= 0 ? Colors.green : Colors.red,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profit >= 0 ? 'Bénéfice Net' : 'Déficit',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                profit >= 0
                                    ? 'Résultat positif pour la période'
                                    : 'Les dépenses dépassent les revenus',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatFCFA(profit),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: profit >= 0
                                ? const Color(0xFF059669)
                                : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFinancialRow(
    ThemeData theme, {
    required String label,
    required int value,
    required int count,
    required String countLabel,
    required Color color,
    required IconData icon,
    bool isExpense = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$count $countLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${isExpense ? '-' : '+'}${CurrencyFormatter.formatFCFA(value)}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color.shade700,
          ),
        ),
      ],
    );
  }
}

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }
}
