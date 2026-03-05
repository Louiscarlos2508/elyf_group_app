import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/agent.dart' as entity;
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

class AgentDetailModal extends ConsumerWidget {
  final entity.Agent agent;

  const AgentDetailModal({super.key, required this.agent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(agentStatisticsProvider(agent.id));
    final historyAsync = ref.watch(agentTreasuryHistoryProvider(agent.id));
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,###');

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 32),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      Text(
                        '${agent.phoneNumber} • SIM: ${agent.simNumber}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${fmt.format(agent.liquidity)} CFA',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Content
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
              children: [
                // Stats Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: statsAsync.when(
                    data: (stats) => GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.6,
                      children: [
                        _StatCard(
                          label: 'Total Rechargé',
                          amount: stats['totalRecharged'] ?? 0,
                          icon: Icons.add_circle_outline_rounded,
                          color: Colors.blue,
                        ),
                        _StatCard(
                          label: 'Total Retiré',
                          amount: stats['totalWithdrawn'] ?? 0,
                          icon: Icons.remove_circle_outline_rounded,
                          color: Colors.orange,
                        ),
                        _StatCard(
                          label: 'Commissions',
                          amount: stats['totalCommission'] ?? 0,
                          icon: Icons.monetization_on_outlined,
                          color: Colors.amber,
                        ),
                        _StatCard(
                          label: 'Transactions',
                          amount: stats['transactionCount'] ?? 0,
                          icon: Icons.receipt_long_outlined,
                          color: theme.colorScheme.primary,
                          isCount: true,
                        ),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erreur stats: $e')),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // History Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Historique des Recharges',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Tout voir'),
                      ),
                    ],
                  ),
                ),

                historyAsync.when(
                  data: (history) => history.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.history_rounded, size: 48, color: theme.colorScheme.outlineVariant),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Aucun historique disponible',
                                  style: TextStyle(color: theme.colorScheme.outline),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: history.length > 5 ? 5 : history.length,
                          itemBuilder: (context, index) => _HistoryTile(operation: history[index]),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur historique: $e')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int amount;
  final IconData icon;
  final Color color;
  final bool isCount;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isCount ? amount.toString() : '${fmt.format(amount)} CFA',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TreasuryOperation operation;

  const _HistoryTile({required this.operation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,###');
    final isRecharge = operation.fromAccount == PaymentMethod.cash;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isRecharge ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isRecharge ? Icons.add_rounded : Icons.remove_rounded,
            color: isRecharge ? Colors.blue : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          isRecharge ? 'Recharge' : 'Retrait',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(operation.date),
          style: theme.textTheme.labelSmall,
        ),
        trailing: Text(
          '${isRecharge ? "+" : "-"}${fmt.format(operation.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            color: isRecharge ? Colors.blue : Colors.orange,
          ),
        ),
      ),
    );
  }
}
