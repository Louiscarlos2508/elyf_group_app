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
import 'package:elyf_groupe_app/features/orange_money/domain/entities/agent.dart' show AgentStatus, Agent;
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';

class TreasuryTab extends ConsumerWidget {
  const TreasuryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    if (activeEnterprise == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isPOS = activeEnterprise.isPointOfSale;
    final balancesAsync = ref.watch(
      orangeMoneyTreasuryBalanceProvider(activeEnterprise.id),
    );
    final operationsAsync = ref.watch(
      orangeMoneyTreasuryOperationsStreamProvider(activeEnterprise.id),
    );
    final theme = Theme.of(context);

    return Column(
      children: [
        ElyfModuleHeader(
          title: 'Trésorerie',
          subtitle: 'Suivi des flux de caisse et float principal',
          module: EnterpriseModule.mobileMoney,
          enterpriseName: activeEnterprise.name,
          asSliver: false,
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              // ── Synthèse automatique ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _AutoSynthesisSection(enterpriseId: activeEnterprise.id),
              ),

              // ── Soldes de caisse ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                  child: Text(
                    'Caisse & Float Principal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
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
                        const SizedBox(width: AppSpacing.md),
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _QuickActionButton(
                          icon: Icons.add_rounded,
                          label: isPOS ? 'Approvisionnement' : 'Apport',
                          color: Colors.green,
                          onPressed: () => _showOperationDialog(
                            context,
                            TreasuryOperationType.supply,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _QuickActionButton(
                          icon: Icons.remove_rounded,
                          label: 'Retrait',
                          color: theme.colorScheme.error,
                          onPressed: () => _showOperationDialog(
                            context,
                            TreasuryOperationType.removal,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _QuickActionButton(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Transfert',
                          color: theme.colorScheme.primary,
                          onPressed: () => _showOperationDialog(
                            context,
                            TreasuryOperationType.transfer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _QuickActionButton(
                          icon: Icons.tune_rounded,
                          label: 'Ajustement',
                          color: Colors.grey,
                          onPressed: () => _showOperationDialog(
                            context,
                            TreasuryOperationType.adjustment,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Opérations Récentes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ),
              ),

              // ── Liste des opérations ──────────────────────────────────────────────
              operationsAsync.when(
                data: (ops) => ops.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text('Aucune opération enregistrée')),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _OperationTile(operation: ops[index]),
                          childCount: ops.length,
                        ),
                      ),
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, __) =>
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Erreur: $e')),
                    ),
              ),
            ],
          ),
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
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final isPOS = activeEnterprise?.isPointOfSale ?? false;

    final agentsAsync = isPOS ? const AsyncValue.data(<Agent>[]) : ref.watch(agentAccountsProvider('$enterpriseId||'));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final statsKey = '$enterpriseId|${today.millisecondsSinceEpoch}';
    final dailyStatsAsync = ref.watch(dailyTransactionStatsProvider(statsKey));
    
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,###');

    final agents = agentsAsync.value ?? [];
    final dailyStats = dailyStatsAsync.value ?? {};

    final operationsAsync = ref.watch(orangeMoneyTreasuryOperationsStreamProvider(enterpriseId));
    final operations = operationsAsync.value ?? [];

    int treasuryDeposits = 0;
    int treasuryWithdrawals = 0;

    for (final op in operations) {
      if (op.date.year == today.year && op.date.month == today.month && op.date.day == today.day) {
        if (op.type == TreasuryOperationType.supply) {
          treasuryDeposits += op.amount;
        } else if (op.type == TreasuryOperationType.removal) {
          treasuryWithdrawals += op.amount;
        } else if (op.type == TreasuryOperationType.transfer && op.referenceEntityType == 'agent_account') {
          if (op.fromAccount == PaymentMethod.mobileMoney && op.toAccount == PaymentMethod.cash) {
            treasuryDeposits += op.amount;
          } else if (op.fromAccount == PaymentMethod.cash && op.toAccount == PaymentMethod.mobileMoney) {
            treasuryWithdrawals += op.amount;
          }
        }
      }
    }

    final totalFloatWithAgents = agents.fold<int>(
      0,
      (sum, agent) => sum + agent.liquidity,
    );

    final totalDepositsToday = (dailyStats['deposits'] as int? ?? 0) + treasuryDeposits;
    final totalWithdrawalsToday = (dailyStats['withdrawals'] as int? ?? 0) + treasuryWithdrawals;
    final netImpact = totalDepositsToday - totalWithdrawalsToday;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPOS ? Icons.analytics_rounded : Icons.auto_graph_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isPOS ? 'Performance du jour' : 'Vue d\'ensemble Réseau',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              if (!isPOS)
                _SynthesisRow(
                  label: 'Float chez les agents',
                  amount: totalFloatWithAgents.toDouble(),
                  color: theme.colorScheme.secondary,
                  icon: Icons.people_outline_rounded,
                ),
              _SynthesisRow(
                label: 'Dépôts',
                amount: totalDepositsToday.toDouble(),
                color: Colors.green,
                icon: Icons.arrow_upward_rounded,
              ),
              _SynthesisRow(
                label: 'Retraits',
                amount: -totalWithdrawalsToday.toDouble(),
                color: theme.colorScheme.error,
                icon: Icons.arrow_downward_rounded,
              ),
              Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Impact Cash net du jour',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${netImpact >= 0 ? "+" : ""}${fmt.format(netImpact)} CFA',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                        color: netImpact >= 0
                            ? Colors.green
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label, 
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            '${amount >= 0 ? "+" : ""}${fmt.format(amount.round())} CFA',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
              color: color,
            ),
          ),
        ],
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              '${NumberFormat('#,###').format(amount)} CFA',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationTile extends StatelessWidget {
  final TreasuryOperation operation;

  const _OperationTile({required this.operation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNegative =
        operation.type == TreasuryOperationType.removal ||
        (operation.type == TreasuryOperationType.transfer &&
            operation.fromAccount != null &&
            operation.toAccount == null);

    IconData icon;
    Color color;
    switch (operation.type) {
      case TreasuryOperationType.supply:
        icon = Icons.add_circle_outline_rounded;
        color = Colors.green;
        break;
      case TreasuryOperationType.removal:
        icon = Icons.remove_circle_outline_rounded;
        color = theme.colorScheme.error;
        break;
      case TreasuryOperationType.transfer:
        icon = Icons.swap_horiz_rounded;
        color = theme.colorScheme.primary;
        break;
      case TreasuryOperationType.adjustment:
        icon = Icons.tune_rounded;
        color = theme.colorScheme.outline;
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          operation.reason ?? operation.type.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (accountInfo.isNotEmpty)
              Text(
                accountInfo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(
              DateFormat('dd MMMM yyyy, HH:mm', 'fr_FR').format(operation.date),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${isNegative ? "-" : "+"}${NumberFormat('#,###').format(operation.amount)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            color: isNegative ? theme.colorScheme.error : Colors.green,
          ),
        ),
      ),
    );
  }
}
