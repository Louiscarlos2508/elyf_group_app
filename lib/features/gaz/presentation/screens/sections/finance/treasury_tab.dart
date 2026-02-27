import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/features/gaz/presentation/widgets/treasury_operation_dialog.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

class TreasuryTab extends ConsumerWidget {
  const TreasuryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    if (activeEnterprise == null)
      return const Center(child: CircularProgressIndicator());

    final isPOS = activeEnterprise.isPointOfSale;
    final balancesAsync = ref.watch(
      gazTreasuryBalanceProvider(activeEnterprise.id),
    );
    final operationsAsync = ref.watch(
      gazTreasuryOperationsStreamProvider(activeEnterprise.id),
    );
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // ── Synthèse automatique ──────────────────────────────────────────────
        if (!isPOS)
          SliverToBoxAdapter(
            child: _AutoSynthesisSection(enterpriseId: activeEnterprise.id),
          ),

        // ── Soldes de caisse ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Caisse (Opérations manuelles)',
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
                      label: 'Caisse (Espèces)',
                      amount: balances['cash'] ?? 0,
                      color: theme.colorScheme.primary,
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _BalanceCard(
                      label: 'Mobile Money',
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
                  label: Text(isPOS ? 'Versement à la mère' : 'Apport'),
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
      builder: (context) => GazTreasuryOperationDialog(type: type),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Synthèse automatique (lecture seule)
// ─────────────────────────────────────────────────────────────────────────────

class _AutoSynthesisSection extends ConsumerWidget {
  const _AutoSynthesisSection({required this.enterpriseId});

  final String enterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(gazHqSalesProvider);
    final toursAsync = ref.watch(gazClosedToursProvider);
    final expensesAsync = ref.watch(gazExpensesProvider);
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,###');

    final sales = salesAsync.value ?? [];
    final tours = toursAsync.value ?? [];
    final expenses = expensesAsync.value ?? [];

    final totalSalesRevenue = sales.fold<double>(
      0,
      (s, v) => s + v.totalAmount,
    );
    final totalTourExpenses = tours.fold<double>(
      0,
      (s, t) => s + t.totalExpenses,
    );
    final totalManualExpenses = expenses.fold<double>(
      0,
      (s, e) => s + e.amount,
    );
    final estimatedBalance =
        totalSalesRevenue - totalTourExpenses - totalManualExpenses;

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
                  'Synthèse automatique',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message:
                      'Calculé depuis les ventes dépôt, dépenses de tournées et dépenses manuelles. '
                      'Non lié directement à la caisse réelle.',
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _SynthesisRow(
            label: 'Recettes dépôt (ventes)',
            amount: totalSalesRevenue,
            color: Colors.green,
            icon: Icons.trending_up,
          ),
          _SynthesisRow(
            label: 'Dépenses tournées',
            amount: -totalTourExpenses,
            color: theme.colorScheme.error,
            icon: Icons.local_shipping_outlined,
          ),
          _SynthesisRow(
            label: 'Dépenses opérationnelles',
            amount: -totalManualExpenses,
            color: theme.colorScheme.error,
            icon: Icons.receipt_long_outlined,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Solde estimé',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${estimatedBalance >= 0 ? "+" : ""}${fmt.format(estimatedBalance.round())} CFA',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: estimatedBalance >= 0
                        ? Colors.green
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Les opérations de caisse réelles sont enregistrées via Apport / Retrait ci-dessous.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Balance Card
// ─────────────────────────────────────────────────────────────────────────────

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
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Operation Tile
// ─────────────────────────────────────────────────────────────────────────────

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
