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
            final isWide = constraints.maxWidth > 700;
            final isTablet = constraints.maxWidth > 450 && constraints.maxWidth <= 700;

            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    child: _SalarySummaryCard(
                      label: 'Employés Fixes',
                      value: '${data.fixedEmployeesCount}',
                      icon: Icons.people_alt_rounded,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SalarySummaryCard(
                      label: 'Paiements Production',
                      value: '${data.productionPaymentsCount}',
                      icon: Icons.receipt_long_rounded,
                      color: Colors.deepPurpleAccent,
                      subtitle:
                          '${data.uniqueProductionWorkers} intervenant(s)',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SalarySummaryCard(
                      label: 'Total du Mois',
                      value: CurrencyFormatter.formatFCFA(
                        data.currentMonthTotal,
                      ),
                      icon: Icons.payments_rounded,
                      color: Colors.green,
                      subtitle: 'Budget Salarial',
                    ),
                  ),
                ],
              );
            }

            if (isTablet) {
              return Column(
                children: [
                   Row(
                    children: [
                      Expanded(
                        child: _SalarySummaryCard(
                          label: 'Employés',
                          value: '${data.fixedEmployeesCount}',
                          icon: Icons.people_alt_rounded,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SalarySummaryCard(
                          label: 'Paiements',
                          value: '${data.productionPaymentsCount}',
                          icon: Icons.receipt_long_rounded,
                          color: Colors.deepPurpleAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SalarySummaryCard(
                    label: 'Total Mois en Cours',
                    value: CurrencyFormatter.formatFCFA(
                      data.currentMonthTotal,
                    ),
                    icon: Icons.payments_rounded,
                    color: Colors.green,
                    subtitle: 'Budget Salarial',
                  ),
                ],
              );
            }

            return Column(
              children: [
                _SalarySummaryCard(
                  label: 'Employés Fixes',
                  value: '${data.fixedEmployeesCount}',
                  icon: Icons.people_alt_rounded,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 12),
                _SalarySummaryCard(
                  label: 'Paiements Production',
                  value: '${data.productionPaymentsCount}',
                  icon: Icons.receipt_long_rounded,
                  color: Colors.deepPurpleAccent,
                ),
                const SizedBox(height: 12),
                _SalarySummaryCard(
                  label: 'Total Mois en Cours',
                  value: CurrencyFormatter.formatFCFA(
                    data.currentMonthTotal,
                  ),
                  icon: Icons.payments_rounded,
                  color: Colors.green,
                  subtitle: 'Budget Salarial',
                ),
              ],
            );
          },
        );
      },
      loading: () => const _LoadingSummary(),
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
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      height: 140,
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.1 : 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: 80,
              color: color.withValues(alpha: 0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingSummary extends StatelessWidget {
  const _LoadingSummary();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 140,
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
