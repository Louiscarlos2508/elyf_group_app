import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orangeMoneyStateProvider);

    return state.when(
      data: (data) => _buildData(context, ref, data),
      loading: () => _buildLoading(),
      error: (error, stackTrace) => _buildError(ref, error),
    );
  }

  Widget _buildData(BuildContext context, WidgetRef ref, dynamic data) {
    final theme = Theme.of(context);
    final stats = data.statistics;
    final cashInTotal = stats['cashInTotal'] as int? ?? 0;
    final cashOutTotal = stats['cashOutTotal'] as int? ?? 0;
    final totalCommission = stats['totalCommission'] as int? ?? 0;
    final totalTransactions = stats['totalTransactions'] as int? ?? 0;
    final pendingTransactions = stats['pendingTransactions'] as int? ?? 0;

    return CustomScrollView(
      slivers: [
        OrangeMoneyHeader(
          title: 'Tableau de Bord',
          subtitle: 'Suivez vos flux et commissions en temps réel avec une précision maximale.',
          additionalActions: [
            if (stats['isNetworkView'] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hub_rounded, color: theme.colorScheme.secondary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'RÉSEAU',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48 - 16) / 2,
                  child: ElyfStatsCard(
                    label: 'Cash-In Total',
                    value: CurrencyFormatter.formatFCFA(cashInTotal),
                    icon: Icons.south_west_rounded,
                    color: theme.colorScheme.primary,
                    isGlass: true,
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48 - 16) / 2,
                  child: ElyfStatsCard(
                    label: 'Cash-Out Total',
                    value: CurrencyFormatter.formatFCFA(cashOutTotal),
                    icon: Icons.north_east_rounded,
                    color: theme.colorScheme.secondary,
                    isGlass: true,
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48 - 16) / 2,
                  child: ElyfStatsCard(
                    label: 'Commissions',
                    value: CurrencyFormatter.formatFCFA(totalCommission),
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF00C897), // Pro success green
                    isGlass: true,
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48 - 16) / 2,
                  child: ElyfStatsCard(
                    label: 'Transactions',
                    value: totalTransactions.toString(),
                    icon: Icons.receipt_long_rounded,
                    color: theme.colorScheme.tertiary,
                    isGlass: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (pendingTransactions > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ElyfCard(
                isGlass: true,
                backgroundColor: theme.colorScheme.warning.withValues(alpha: 0.1),
                borderColor: theme.colorScheme.warning.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: theme.colorScheme.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$pendingTransactions transaction(s) en attente',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }


  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ElyfShimmer(child: ElyfShimmer.card(height: 200, borderRadius: 40)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: ElyfShimmer(child: ElyfShimmer.card(height: 120, borderRadius: 24))),
              const SizedBox(width: 16),
              Expanded(child: ElyfShimmer(child: ElyfShimmer.card(height: 120, borderRadius: 24))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(WidgetRef ref, dynamic error) {
    return ErrorDisplayWidget(
      error: error,
      onRetry: () => ref.refresh(orangeMoneyStateProvider),
    );
  }
}
