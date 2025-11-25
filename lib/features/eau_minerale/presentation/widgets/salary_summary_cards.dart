import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';

/// Summary cards for salaries module.
class SalarySummaryCards extends ConsumerWidget {
  const SalarySummaryCards({
    super.key,
    this.onNewPayment,
  });

  final VoidCallback? onNewPayment;

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

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
                          subtitle: '${data.uniqueProductionWorkers} personne(s) unique(s)',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SalarySummaryCard(
                          label: 'Total Mois en Cours',
                          value: _formatCurrency(data.currentMonthTotal),
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
                        subtitle: '${data.uniqueProductionWorkers} personne(s) unique(s)',
                      ),
                      const SizedBox(height: 16),
                      _SalarySummaryCard(
                        label: 'Total Mois en Cours',
                        value: _formatCurrency(data.currentMonthTotal),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(icon, color: color, size: 32),
        ],
      ),
    );
  }
}

