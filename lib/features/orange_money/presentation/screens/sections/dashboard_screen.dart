import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/atoms/elyf_shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orangeMoneyStateProvider);
    final theme = Theme.of(context);

    return state.when(
      data: (data) {
        final stats = data.statistics;
        final cashInTotal = stats['cashInTotal'] as int? ?? 0;
        final cashOutTotal = stats['cashOutTotal'] as int? ?? 0;
        final totalCommission = stats['totalCommission'] as int? ?? 0;
        final totalTransactions = stats['totalTransactions'] as int? ?? 0;
        final pendingTransactions = stats['pendingTransactions'] as int? ?? 0;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFF97316), // Orange
                      const Color(0xFFFB923C),
                      const Color(0xFFF59E0B), // Amber
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orange Money',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tableau de Bord',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Suivi des flux, commissions et transactions en temps réel.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.horizontalPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: ElyfStatsCard(
                        label: 'Cash-In Total',
                        value: CurrencyFormatter.formatFCFA(cashInTotal),
                        icon: Icons.arrow_downward_rounded,
                        color: const Color(0xFFF97316),
                        isGlass: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElyfStatsCard(
                        label: 'Cash-Out Total',
                        value: CurrencyFormatter.formatFCFA(cashOutTotal),
                        icon: Icons.arrow_upward_rounded,
                        color: Colors.orange,
                        isGlass: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.horizontalPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: ElyfStatsCard(
                        label: 'Commission',
                        value: CurrencyFormatter.formatFCFA(totalCommission),
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.blue,
                        isGlass: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElyfStatsCard(
                        label: 'Transactions',
                        value: totalTransactions.toString(),
                        icon: Icons.history_rounded,
                        color: Colors.purple,
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
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: ElyfCard(
                    isGlass: true,
                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                    borderColor: Colors.orange.withValues(alpha: 0.2),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$pendingTransactions transaction(s) en attente',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
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
      },
      loading: () => Padding(
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
      ),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        onRetry: () => ref.refresh(orangeMoneyStateProvider),
      ),
    );
  }


}
