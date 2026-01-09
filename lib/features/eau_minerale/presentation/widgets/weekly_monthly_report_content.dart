import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/expense_record.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/salary_payment.dart';
import 'production_period_formatter.dart';

/// Widget pour afficher les rapports hebdomadaires et mensuels avec graphiques.
class WeeklyMonthlyReportContent extends ConsumerWidget {
  const WeeklyMonthlyReportContent({
    super.key,
    required this.period,
  });

  final ReportPeriod period;

  bool get isWeekly {
    final days = period.endDate.difference(period.startDate).inDays;
    return days <= 7;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Récupérer les données
    final sessionsAsync = ref.watch(productionSessionsStateProvider);
    final expensesAsync = ref.watch(financesStateProvider);
    final salariesAsync = ref.watch(salaryStateProvider);

    return sessionsAsync.when(
      data: (allSessions) {
        // Filtrer les sessions dans la période
        final sessions = allSessions.where((s) {
          return s.date.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
              s.date.isBefore(period.endDate.add(const Duration(days: 1)));
        }).toList();

        final expenses = expensesAsync.maybeWhen(
          data: (data) => data.expenses.where((e) {
            return e.date.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
                e.date.isBefore(period.endDate.add(const Duration(days: 1)));
          }).toList(),
          orElse: () => <ExpenseRecord>[],
        );

        final salaries = salariesAsync.maybeWhen(
          data: (data) => data.monthlySalaryPayments.where((s) {
            return s.date.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
                s.date.isBefore(period.endDate.add(const Duration(days: 1)));
          }).toList(),
          orElse: () => <SalaryPayment>[],
        );

        // Calculs
        final totalProduction = sessions.length;
        final totalQuantity = sessions.fold<int>(
          0,
          (sum, s) => sum + s.quantiteProduite,
        );
        final totalConsumption = sessions.fold<double>(
          0.0,
          (sum, s) => sum + s.consommationCourant,
        );
        final totalExpenses = expenses.fold<int>(
          0,
          (sum, e) => sum + e.amountCfa,
        );
        final totalSalaries = salaries.fold<int>(
          0,
          (sum, s) => sum + s.amount,
        );
        final totalCosts = totalExpenses + totalSalaries;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isWeekly ? 'Rapport Hebdomadaire' : 'Rapport Mensuel',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${ProductionPeriodFormatter.formatDate(period.startDate)} - '
                '${ProductionPeriodFormatter.formatDate(period.endDate)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              
              // KPIs
              _KpiGrid(
                items: [
                  _KpiItem(
                    label: 'Productions',
                    value: '$totalProduction',
                    icon: Icons.factory,
                    color: Colors.blue,
                  ),
                  _KpiItem(
                    label: 'Quantité produite',
                    value: '$totalQuantity unités',
                    icon: Icons.inventory_2,
                    color: Colors.green,
                  ),
                  _KpiItem(
                    label: 'Consommation électrique',
                    value: '${totalConsumption.toStringAsFixed(2)} kWh',
                    icon: Icons.bolt,
                    color: Colors.orange,
                  ),
                  _KpiItem(
                    label: 'Dépenses',
                    value: CurrencyFormatter.formatFCFA(totalExpenses),
                    icon: Icons.receipt_long,
                    color: Colors.red,
                  ),
                  _KpiItem(
                    label: 'Salaires',
                    value: CurrencyFormatter.formatFCFA(totalSalaries),
                    icon: Icons.payments,
                    color: Colors.purple,
                  ),
                  _KpiItem(
                    label: 'Coûts totaux',
                    value: CurrencyFormatter.formatFCFA(totalCosts),
                    icon: Icons.account_balance,
                    color: Colors.red.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Graphique des dépenses par catégorie
              if (expenses.isNotEmpty) ...[
                _SectionTitle(title: 'Dépenses par Catégorie'),
                const SizedBox(height: 16),
                _ExpenseCategoryChart(expenses: expenses),
                const SizedBox(height: 24),
              ],
              
              // Détail des productions
              _SectionTitle(title: 'Détail des Productions'),
              const SizedBox(height: 16),
              if (sessions.isEmpty)
                Center(
                  child: Text(
                    'Aucune production pour cette période',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...sessions.map((session) => _ProductionSummaryCard(
                      session: session,
                      formatCurrency: _formatCurrency,
                    )),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.items});

  final List<_KpiItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          );
        } else {
          return Column(
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: item,
            )).toList(),
          );
        }
      },
    );
  }
}

class _KpiItem extends StatelessWidget {
  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCategoryChart extends StatelessWidget {
  const _ExpenseCategoryChart({required this.expenses});

  final List<ExpenseRecord> expenses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Grouper par catégorie
    final byCategory = <String, int>{};
    for (final expense in expenses) {
      final category = expense.category.label;
      byCategory[category] = (byCategory[category] ?? 0) + expense.amountCfa;
    }

    final total = expenses.fold<int>(0, (sum, e) => sum + e.amountCfa);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: byCategory.entries.map((entry) {
          final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${entry.value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProductionSummaryCard extends StatelessWidget {
  const _ProductionSummaryCard({
    required this.session,
    required this.formatCurrency,
  });

  final ProductionSession session;
  final String Function(int) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Production du ${ProductionPeriodFormatter.formatDate(session.date)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${session.quantiteProduite} ${session.quantiteProduiteUnite}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.precision_manufacturing,
                  label: '${session.machinesUtilisees.length} machine(s)',
                ),
                _InfoChip(
                  icon: Icons.rotate_right,
                  label: '${session.bobinesUtilisees.length} bobine(s)',
                ),
                if (session.consommationCourant > 0)
                  _InfoChip(
                    icon: Icons.bolt,
                    label: '${session.consommationCourant.toStringAsFixed(2)} kWh',
                  ),
                if (session.coutTotalPersonnel > 0)
                  _InfoChip(
                    icon: Icons.people,
                    label: 'Personnel: ${formatCurrency(session.coutTotalPersonnel)}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
