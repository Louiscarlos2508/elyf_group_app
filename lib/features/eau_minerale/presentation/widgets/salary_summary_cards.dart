import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';

/// Summary cards for salaries module.
class SalarySummaryCards extends ConsumerWidget {
  const SalarySummaryCards({super.key, this.onNewPayment});

  final VoidCallback? onNewPayment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salaryStateProvider);
    return state.when(
      data: (data) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            return isWide
                ? Row(
                    children: [
                      Expanded(
                        child: _SalarySummaryCard(
                          label: 'Employés Fixes',
                          value: '${data.fixedEmployeesCount}',
                          icon: Icons.business_center,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SalarySummaryCard(
                          label: 'Paiements Production',
                          value: '${data.productionPaymentsCount}',
                          icon: Icons.factory,
                          color: Colors.purple,
                          subtitle:
                              '${data.uniqueProductionWorkers} personne(s) unique(s)',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SalarySummaryCard(
                          label: 'Total Mois en Cours',
                          value: CurrencyFormatter.formatFCFA(
                            data.currentMonthTotal,
                          ),
                          icon: Icons.trending_up,
                          color: Colors.green,
                          subtitle: 'FCFA',
                          valueColor: Colors.green,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _SalarySummaryCard(
                        label: 'Employés Fixes',
                        value: '${data.fixedEmployeesCount}',
                        icon: Icons.business_center,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _SalarySummaryCard(
                        label: 'Paiements Production',
                        value: '${data.productionPaymentsCount}',
                        icon: Icons.factory,
                        color: Colors.purple,
                        subtitle:
                            '${data.uniqueProductionWorkers} personne(s) unique(s)',
                      ),
                      const SizedBox(height: 16),
                      _SalarySummaryCard(
                        label: 'Total Mois en Cours',
                        value: CurrencyFormatter.formatFCFA(
                          data.currentMonthTotal,
                        ),
                        icon: Icons.trending_up,
                        color: Colors.green,
                        subtitle: 'FCFA',
                        valueColor: Colors.green,
                      ),
                    ],
                  );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SalarySummaryCard extends StatelessWidget {
  const _SalarySummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      height: 150, // Fixed height for consistent dashboard look
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
