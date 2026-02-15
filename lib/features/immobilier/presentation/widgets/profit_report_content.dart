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
    this.endDate,
  });

  final DateTime startDate;
  final DateTime? endDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paymentsAsync = ref.watch(paymentsWithRelationsProvider);
    final expensesAsync = ref.watch(expensesProvider);

    return paymentsAsync.when(
      data: (payments) {
        final periodPayments = payments.where((p) {
          return p.paymentDate.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              (endDate == null ||
                  p.paymentDate
                      .isBefore(endDate!.add(const Duration(days: 1)))) &&
              (p.status == PaymentStatus.paid || p.status == PaymentStatus.partial);
        }).toList();

        final totalRevenue = periodPayments.fold(0, (sum, p) => sum + p.paidAmount);

        return expensesAsync.when(
          data: (expenses) {
            final periodExpenses = expenses.where((e) {
              return e.expenseDate.isAfter(
                    startDate.subtract(const Duration(days: 1)),
                  ) &&
                  (endDate == null ||
                      e.expenseDate
                          .isBefore(endDate!.add(const Duration(days: 1))));
            }).toList();

            final totalExpenses = periodExpenses.fold(
              0,
              (sum, e) => sum + e.amount,
            );
            final profit = totalRevenue - totalExpenses;

            // Group by property
            final propertyStats = <String, ({int revenue, int expenses, int profit})>{};
            
            for (final p in periodPayments) {
              final propId = p.contract?.propertyId ?? '';
              if (propId.isEmpty) continue;

              final current = propertyStats[propId] ?? (revenue: 0, expenses: 0, profit: 0);
              propertyStats[propId] = (
                revenue: current.revenue + p.paidAmount,
                expenses: current.expenses,
                profit: current.profit + p.paidAmount,
              );
            }

            for (final e in periodExpenses) {
              final propId = e.propertyId;
              final current = propertyStats[propId] ?? (revenue: 0, expenses: 0, profit: 0);
              propertyStats[propId] = (
                revenue: current.revenue,
                expenses: current.expenses + e.amount,
                profit: current.profit - e.amount,
              );
            }

            return Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Résumé Global',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildFinancialRow(
                        theme,
                        label: 'Revenus Totaux',
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
                      _buildFinancialRow(
                        theme,
                        label: 'Dépenses Totales',
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
                              profit >= 0 ? Icons.account_balance_wallet : Icons.warning,
                              color: profit >= 0 ? Colors.green : Colors.red,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                profit >= 0 ? 'Bénéfice Net' : 'Déficit',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatFCFA(profit),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: profit >= 0 ? const Color(0xFF059669) : theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Rentabilité par Propriété',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ref.watch(propertiesProvider).when(
                  data: (properties) {
                    if (properties.isEmpty) return const Center(child: Text('Aucune propriété'));
                    
                    return Column(
                      children: properties.map((property) {
                        final stats = propertyStats[property.id] ?? (revenue: 0, expenses: 0, profit: 0);
                        return _buildPropertyProfitCard(theme, property, stats);
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Erreur: $e'),
                ),
              ],
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

  Widget _buildPropertyProfitCard(
    ThemeData theme,
    dynamic property,
    ({int revenue, int expenses, int profit}) stats,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.home, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    property.address,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  CurrencyFormatter.formatFCFA(stats.profit),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: stats.profit >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(theme, 'Revenus', stats.revenue, Colors.green),
                ),
                Expanded(
                  child: _buildMiniStat(theme, 'Charges', stats.expenses, Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(ThemeData theme, String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Text(
          CurrencyFormatter.formatFCFA(value),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
