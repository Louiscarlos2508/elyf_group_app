import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

/// Net balance card for reports screen.
class ReportNetBalanceCard extends StatelessWidget {
  const ReportNetBalanceCard({super.key, required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final cashInTotal = stats['cashInTotal'] as int? ?? 0;
    final cashOutTotal = stats['cashOutTotal'] as int? ?? 0;
    final netBalance = cashInTotal - cashOutTotal;
    final theme = Theme.of(context);

    return ElyfCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.success.withValues(alpha: 0.1),
      borderColor: AppColors.success.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          children: [
            Text(
              'Solde net de la période',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '${netBalance >= 0 ? '+' : ''}${CurrencyFormatter.formatFCFA(netBalance)}',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w900,
                fontFamily: 'Outfit',
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Dépôts - Retraits = ${CurrencyFormatter.formatFCFA(cashInTotal)} - ${CurrencyFormatter.formatFCFA(cashOutTotal)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
