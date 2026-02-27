import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/treasury_operation_dialog.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/orange_money_enterprise_extensions.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/agent.dart' show AgentStatus;

class TreasuryTab extends ConsumerWidget {
  const TreasuryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    if (activeEnterprise == null)
      return const Center(child: CircularProgressIndicator());

    final isPOS = activeEnterprise.isPointOfSale;
    final balancesAsync = ref.watch(
      orangeMoneyTreasuryBalanceProvider(activeEnterprise.id),
    );
    final operationsAsync = ref.watch(
      orangeMoneyTreasuryOperationsStreamProvider(activeEnterprise.id),
    );
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // ── Synthèse automatique ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _AutoSynthesisSection(enterpriseId: activeEnterprise.id),
        ),

        // ── Soldes de caisse ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Caisse & Float Principal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: balancesAsync.when(
              data: (balances) => Row(
                children: [
                  Expanded(
                    child: _BalanceCard(
                      label: 'Espèces en main',
                      amount: balances['cash'] ?? 0,
                      color: theme.colorScheme.primary,
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _BalanceCard(
                      label: 'Float Principal (SIM)',
                      amount: balances['mobileMoney'] ?? 0,
                      color: theme.colorScheme.secondary,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Text('Erreur: $e'),
            ),
          ),
        ),

        // ── Actions rapides ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text(isPOS ? 'Approvisionnement' : 'Apport'),
                  onPressed: () => _showOperationDialog(
                    context,
                    TreasuryOperationType.supply,
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.remove, size: 16),
                  label: const Text('Retrait'),
                  onPressed: () => _showOperationDialog(
                    context,
                    TreasuryOperationType.removal,
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Transfert'),
                  onPressed: () => _showOperationDialog(
                    context,
                    TreasuryOperationType.transfer,
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.tune, size: 16),
                  label: const Text('Ajustement'),
                  onPressed: () => _showOperationDialog(
                    context,
                    TreasuryOperationType.adjustment,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Opérations Récentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // ── Liste des opérations ──────────────────────────────────────────────
        operationsAsync.when(
          data: (ops) => ops.isEmpty
              ? const SliverFillRemaining(
                  child: Center(child: Text('Aucune opération enregistrée')),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _OperationTile(operation: ops[index]),
                    childCount: ops.length,
                  ),
                ),
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, __) =>
              SliverFillRemaining(child: Center(child: Text('Erreur: $e'))),
        ),
      ],
    );
  }

  void _showOperationDialog(BuildContext context, TreasuryOperationType type) {
    showDialog(
      context: context,
      builder: (context) => OrangeMoneyTreasuryOperationDialog(type: type),
    );
  }
}

class _AutoSynthesisSection extends ConsumerWidget {
  const _AutoSynthesisSection({required this.enterpriseId});

  final String enterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Collecte les données de différentes sources pour une vue d'ensemble
    final agentsAsync = ref.watch(agentAccountsProvider('$enterpriseId||'));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final statsKey = '$enterpriseId|${today.millisecondsSinceEpoch}';
    final dailyStatsAsync = ref.watch(dailyTransactionStatsProvider(statsKey));
    final commissionsAsync = ref.watch(commissionsStatisticsProvider(enterpriseId));
    
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,###');

    final agents = agentsAsync.value ?? [];
    final dailyStats = dailyStatsAsync.value ?? {};
    final commStats = commissionsAsync.value ?? {};

    final totalFloatWithAgents = agents.fold<int>(
      0,
      (sum, agent) => sum + agent.liquidity,
    );

    final totalDepositsToday = dailyStats['deposits'] as int? ?? 0;
    final totalWithdrawalsToday = dailyStats['withdrawals'] as int? ?? 0;
    final totalCommissions = commStats['totalAmount'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.auto_graph,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Vue d\'ensemble Réseau',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _SynthesisRow(
            label: 'Float chez les agents',
            amount: totalFloatWithAgents.toDouble(),
            color: theme.colorScheme.secondary,
            icon: Icons.people_outline,
          ),
          _SynthesisRow(
            label: 'Total Dépôts (SIM)',
            amount: totalDepositsToday.toDouble(),
            color: Colors.green,
            icon: Icons.arrow_upward,
          ),
          _SynthesisRow(
            label: 'Total Retraits (CASH)',
            amount: -totalWithdrawalsToday.toDouble(),
            color: theme.colorScheme.error,
            icon: Icons.arrow_downward,
          ),
          _SynthesisRow(
            label: 'Commissions gagnées',
            amount: totalCommissions.toDouble(),
            color: Colors.blue,
            icon: Icons.account_balance_wallet_outlined,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Impact Cash net du jour',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(totalDepositsToday - totalWithdrawalsToday) >= 0 ? "+" : ""}${fmt.format(totalDepositsToday - totalWithdrawalsToday)} CFA',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: (totalDepositsToday - totalWithdrawalsToday) >= 0
                        ? Colors.green
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SynthesisRow extends StatelessWidget {
  const _SynthesisRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: color),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      trailing: Text(
        '${amount >= 0 ? "+" : ""}${fmt.format(amount.round())} CFA',
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  const _BalanceCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              '${NumberFormat('#,###').format(amount)} CFA',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationTile extends StatelessWidget {
  final TreasuryOperation operation;

  const _OperationTile({required this.operation});

  @override
  Widget build(BuildContext context) {
    final isNegative =
        operation.type == TreasuryOperationType.removal ||
        (operation.type == TreasuryOperationType.transfer &&
            operation.fromAccount != null &&
            operation.toAccount == null);

    IconData icon;
    Color color;
    switch (operation.type) {
      case TreasuryOperationType.supply:
        icon = Icons.add_circle_outline;
        color = Colors.green;
        break;
      case TreasuryOperationType.removal:
        icon = Icons.remove_circle_outline;
        color = Colors.red;
        break;
      case TreasuryOperationType.transfer:
        icon = Icons.swap_horiz;
        color = Colors.blue;
        break;
      case TreasuryOperationType.adjustment:
        icon = Icons.tune;
        color = Colors.grey;
        break;
    }

    final String accountInfo;
    if (operation.type == TreasuryOperationType.transfer) {
      accountInfo =
          '${operation.fromAccount?.label ?? "?"} ➔ ${operation.toAccount?.label ?? "?"}';
    } else {
      accountInfo =
          operation.fromAccount?.label ?? operation.toAccount?.label ?? '';
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(operation.reason ?? operation.type.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (accountInfo.isNotEmpty)
            Text(
              accountInfo,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(operation.date),
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
      trailing: Text(
        '${isNegative ? "-" : "+"}${NumberFormat('#,###').format(operation.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isNegative ? Colors.red : Colors.green,
          fontSize: 15,
        ),
      ),
    );
  }
}
