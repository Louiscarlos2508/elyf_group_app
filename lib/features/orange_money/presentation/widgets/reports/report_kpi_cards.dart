import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';

/// KPI cards row for reports screen.
class ReportKpiCards extends StatelessWidget {
  const ReportKpiCards({super.key, required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final cashInTotal = stats['totalCashIn'] as int? ?? 0;
    final cashOutTotal = stats['totalCashOut'] as int? ?? 0;
    final totalTransactions = stats['totalTransactions'] as int? ?? 0;
    final depositsCount = stats['depositsCount'] as int? ?? 0;
    final withdrawalsCount = stats['withdrawalsCount'] as int? ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ModernKpiCard(
                label: 'Transactions',
                value: totalTransactions.toString(),
                icon: Icons.sync_alt_rounded,
                color: AppColors.primary,
                subtitle: 'Volume total',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModernKpiCard(
                label: 'Commissions',
                value: CurrencyFormatter.formatFCFA(stats['totalCommission'] as int? ?? 0),
                icon: Icons.account_balance_wallet,
                color: const Color(0xFF6C5CE7),
                subtitle: stats['isCommissionDeclared'] == true ? 'Montant Déclaré' : 'Non déclaré',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ModernKpiCard(
                label: 'Dépôts',
                value: depositsCount.toString(),
                icon: Icons.arrow_downward_rounded,
                color: const Color(0xFFFF6B00),
                subtitle: CurrencyFormatter.formatFCFA(cashInTotal),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModernKpiCard(
                label: 'Retraits',
                value: withdrawalsCount.toString(),
                icon: Icons.arrow_upward_rounded,
                color: AppColors.danger,
                subtitle: CurrencyFormatter.formatFCFA(cashOutTotal),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModernKpiCard extends StatelessWidget {
  const _ModernKpiCard({
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
    
    return ElyfCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
      elevation: isDark ? 0 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual KPI card for reports.
