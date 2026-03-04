import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import '../../../domain/entities/liquidity_checkpoint.dart';

/// Section affichant l'activité journalière (dépôts, retraits, transactions).
class LiquidityDailyActivitySection extends StatelessWidget {
  const LiquidityDailyActivitySection({
    super.key,
    required this.checkpoint,
    required this.stats,
  });

  final LiquidityCheckpoint? checkpoint;
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deposits = stats['deposits'] as int? ?? 0;
    final withdrawals = stats['withdrawals'] as int? ?? 0;
    final transactionCount = stats['transactionCount'] as int? ?? 0;

    final morningCash = checkpoint?.morningCashAmount ?? 0;
    final morningSim = checkpoint?.morningSimAmount ?? 0;

    return Column(
      children: [
        // Activité de la journée
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Activité de la journée',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildStatItem('Dépôts', deposits, theme, theme.colorScheme.primary)),
                  _buildDivider(theme),
                  Expanded(child: _buildStatItem('Retraits', withdrawals, theme, theme.colorScheme.error)),
                  _buildDivider(theme),
                  Expanded(child: _buildStatItem('Transactions', transactionCount, theme, theme.colorScheme.onSurface, showCurrency: false)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Solde disponible (basé sur le pointage du matin)
        if (checkpoint != null && (checkpoint!.morningCashAmount != null || checkpoint!.morningSimAmount != null))
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Solde d\'ouverture (Matin)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBalanceRow('Cash Opening', checkpoint!.morningCashAmount ?? 0, theme, theme.colorScheme.onSurface),
                const SizedBox(height: 10),
                _buildBalanceRow('SIM Opening', checkpoint!.morningSimAmount ?? 0, theme, theme.colorScheme.primary),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL OUVERTURE',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatFCFA(morningCash + morningSim),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(String label, dynamic value, ThemeData theme, Color valueColor, {bool showCurrency = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          showCurrency ? CurrencyFormatter.formatShort(value as int) : value.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }

  Widget _buildBalanceRow(String label, int amount, ThemeData theme, Color amountColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          CurrencyFormatter.formatFCFA(amount),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}
