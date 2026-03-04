import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';
import '../../../domain/entities/liquidity_checkpoint.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';

/// Widget affichant la liste des pointages de liquidité.
class LiquidityCheckpointsList extends StatelessWidget {
  const LiquidityCheckpointsList({super.key, required this.checkpoints});

  final List<LiquidityCheckpoint> checkpoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMMM yyyy', 'fr');

    return Column(
      children: checkpoints.map<Widget>((checkpoint) {
        final hasMorning = checkpoint.hasMorningCheckpoint;
        final hasEvening = checkpoint.hasEveningCheckpoint;

        return ElyfCard(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(checkpoint.date),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        // Display enterprise name if in network view
                        Consumer(
                          builder: (context, ref, _) {
                            final enterprisesMap = ref.watch(networkEnterprisesProvider).value ?? {};
                            final enterpriseName = enterprisesMap[checkpoint.enterpriseId];
                            
                            if (enterpriseName != null) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    enterpriseName,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadges(hasMorning, hasEvening, theme),
                ],
              ),
              if (hasMorning || hasEvening) ...[
                const SizedBox(height: 20),
                if (hasMorning && (checkpoint.morningCashAmount != null || checkpoint.morningSimAmount != null))
                  _PeriodCard(
                    title: '🌅 MATIN',
                    accentColor: const Color(0xFFF54900),
                    cashAmount: checkpoint.morningCashAmount ?? 0,
                    simAmount: checkpoint.morningSimAmount ?? 0,
                  ),
                if (hasMorning && hasEvening) const SizedBox(height: 12),
                if (hasEvening && (checkpoint.eveningCashAmount != null || checkpoint.eveningSimAmount != null))
                  _PeriodCard(
                    title: '🌙 SOIR',
                    accentColor: const Color(0xFF7C3AED),
                    cashAmount: checkpoint.eveningCashAmount ?? 0,
                    simAmount: checkpoint.eveningSimAmount ?? 0,
                    theoreticalCash: checkpoint.theoreticalCash,
                    theoreticalSim: checkpoint.theoreticalSim,
                    requiresJustification: checkpoint.requiresJustification,
                    discrepancyPercentage: checkpoint.discrepancyPercentage,
                  ),
                if (hasMorning && hasEvening) ...[
                  const SizedBox(height: 16),
                  _buildVariancesCard(checkpoint, theme),
                ],
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadges(bool hasMorning, bool hasEvening, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasMorning)
          _buildTinyBadge(
            icon: Icons.wb_sunny_rounded,
            label: 'Matin',
            color: const Color(0xFFF54900),
            theme: theme,
          ),
        if (hasMorning && hasEvening) const SizedBox(width: 8),
        if (hasEvening)
          _buildTinyBadge(
            icon: Icons.nights_stay_rounded,
            label: 'Soir',
            color: const Color(0xFF7C3AED),
            theme: theme,
          ),
      ],
    );
  }

  Widget _buildTinyBadge({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariancesCard(LiquidityCheckpoint checkpoint, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'ÉCARTS DE LA JOURNÉE',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVarianceRow(
            'Cash Variation',
            (checkpoint.eveningCashAmount ?? 0) - (checkpoint.morningCashAmount ?? 0),
            theme,
          ),
          const SizedBox(height: 8),
          _buildVarianceRow(
            'SIM Variation',
            (checkpoint.eveningSimAmount ?? 0) - (checkpoint.morningSimAmount ?? 0),
            theme,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VARIATION TOTALE',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Builder(
                builder: (context) {
                  final morningTotal = (checkpoint.morningCashAmount ?? 0) + (checkpoint.morningSimAmount ?? 0);
                  final eveningTotal = (checkpoint.eveningCashAmount ?? 0) + (checkpoint.eveningSimAmount ?? 0);
                  final diff = eveningTotal - morningTotal;
                  final isPositive = diff >= 0;
                  
                  return Text(
                    '${isPositive ? '+' : ''}${CurrencyFormatter.formatShort(diff)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isPositive ? theme.colorScheme.primary : theme.colorScheme.error,
                      fontFamily: 'Outfit',
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVarianceRow(String label, int diff, ThemeData theme) {
    final isPositive = diff >= 0;
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
          '${isPositive ? '+' : ''}${CurrencyFormatter.formatShort(diff)}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isPositive ? theme.colorScheme.primary : theme.colorScheme.error,
          ),
        ),
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.title,
    required this.accentColor,
    required this.cashAmount,
    required this.simAmount,
    this.theoreticalCash,
    this.theoreticalSim,
    this.requiresJustification = false,
    this.discrepancyPercentage,
  });

  final String title;
  final Color accentColor;
  final int cashAmount;
  final int simAmount;
  final int? theoreticalCash;
  final int? theoreticalSim;
  final bool requiresJustification;
  final double? discrepancyPercentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: requiresJustification 
              ? theme.colorScheme.error.withValues(alpha: 0.3)
              : accentColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  letterSpacing: 1.0,
                ),
              ),
              if (requiresJustification)
                Icon(Icons.warning_amber_rounded, size: 16, color: theme.colorScheme.error),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (cashAmount > 0 || theoreticalCash != null)
                Expanded(
                  child: _buildDetail('💵 Cash', cashAmount, theoreticalCash, theme, theme.colorScheme.onSurface),
                ),
              if ((cashAmount > 0 || theoreticalCash != null) && (simAmount > 0 || theoreticalSim != null))
                const SizedBox(width: 16),
              if (simAmount > 0 || theoreticalSim != null)
                Expanded(
                  child: _buildDetail('📱 SIM', simAmount, theoreticalSim, theme, theme.colorScheme.primary),
                ),
            ],
          ),
          if (requiresJustification && discrepancyPercentage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 14, color: theme.colorScheme.error),
                  const SizedBox(width: 6),
                  Text(
                    'Écart de ${discrepancyPercentage!.toStringAsFixed(1)}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetail(String label, int amount, int? theoretical, ThemeData theme, Color amountColor) {
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
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.formatShort(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: amountColor,
            fontFamily: 'Outfit',
          ),
        ),
        if (theoretical != null)
          Text(
            'Attendu: ${CurrencyFormatter.formatShort(theoretical)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
      ],
    );
  }
}
