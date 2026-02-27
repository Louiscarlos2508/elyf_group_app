import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import 'package:elyf_groupe_app/features/orange_money/application/controllers/orange_money_controller.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/orange_money_header.dart';

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

  Widget _buildData(BuildContext context, WidgetRef ref, OrangeMoneyState data) {
    final theme = Theme.of(context);
    final stats = data.statistics;
    final cashInTotal = stats['cashInTotal'] as int? ?? 0;
    final cashOutTotal = stats['cashOutTotal'] as int? ?? 0;
    final totalCommission = stats['totalCommission'] as int? ?? 0;
    final pendingTransactions = stats['pendingTransactions'] as int? ?? 0;
    
    // Checkpoint & Balances
    final todayCheckpoint = data.todayCheckpoint;
    final startSim = todayCheckpoint?.simAmount ?? todayCheckpoint?.morningSimAmount ?? 0;
    final startCash = todayCheckpoint?.cashAmount ?? todayCheckpoint?.morningCashAmount ?? 0;
    
    // Current Balance Calculation:
    // SIM = Start + CashOut (Customer gives SIM, Agent gets SIM?? NO. Agent sends SIM)
    // Agent SIM Balance decreases on CashIn (sends to customer)
    // Agent SIM Balance increases on CashOut (receives from customer)
    final currentSim = startSim - cashInTotal + cashOutTotal;
    
    // Agent Cash Balance increases on CashIn (receives cash)
    // Agent Cash Balance decreases on CashOut (gives cash)
    final currentCash = startCash + cashInTotal - cashOutTotal;

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: CustomScrollView(
        slivers: [
          OrangeMoneyHeader(
            title: 'Tableau de Bord',
            subtitle: 'Vue d\'ensemble de votre activité du jour.',
            asSliver: true,
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

        // 1. Pointage Alert (if missing)
        if (todayCheckpoint == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.access_time_filled, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pointage Matin Requis',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Effectuez votre pointage pour démarrer.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),

        // 2. Solde Actuel (SIM & Espèces)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildBalanceCard(
                    context, 
                    'Solde SIM (Estimé)', 
                    currentSim, 
                    Icons.sim_card, 
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBalanceCard(
                    context, 
                    'En Caisse', 
                    currentCash, 
                    Icons.account_balance_wallet, 
                    const Color(0xFF00C897),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // 3. Actions Rapides
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIONS RAPIDES',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Dépôt',
                        Icons.south_west_rounded,
                        theme.colorScheme.primary,
                        () {}, // TODO naviguer vers Dépôt
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Retrait',
                        Icons.north_east_rounded,
                        theme.colorScheme.secondary,
                        () {}, // TODO naviguer vers Retrait
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

         const SliverToBoxAdapter(child: SizedBox(height: 24)),

         // 4. Synthèse Commissions (Focus)
         SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
             child: ElyfStatsCard(
                label: 'Commissions du Jour',
                value: CurrencyFormatter.formatFCFA(totalCommission),
                icon: Icons.payments_rounded,
                color: theme.colorScheme.tertiary,
                isGlass: true,
             ),
          ),
         ),

        if (pendingTransactions > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ElyfCard(
                isGlass: true,
                backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                borderColor: theme.colorScheme.error.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
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
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, String label, int amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.formatFCFA(amount),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Outfit',
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            vertical: isKeyboardOpen ? 8 : 12, 
            horizontal: 16
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: isKeyboardOpen ? 18 : 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: isKeyboardOpen ? 13 : 15,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        ),
      ),
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
