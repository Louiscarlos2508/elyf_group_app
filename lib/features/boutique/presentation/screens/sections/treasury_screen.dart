import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/screens/sections/widgets/treasury_operation_dialog.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/boutique_header.dart';

class TreasuryScreen extends ConsumerWidget {
  const TreasuryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(treasuryBalancesProvider);
    final operationsAsync = ref.watch(treasuryOperationsProvider);

    return CustomScrollView(
      slivers: [
        BoutiqueHeader(
          title: "TRÉSORERIE",
          subtitle: "Gestion des Comptes & Flux",
          gradientColors: const [
            Color(0xFF059669), // Emerald 600
            Color(0xFF047857), // Emerald 700
          ],
          shadowColor: const Color(0xFF059669),
          additionalActions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => ref.invalidate(treasuryBalancesProvider),
            ),
          ],
        ),
        // Balance Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _BalanceCard(
                    label: 'Caisse (Espèces)',
                    amount: balancesAsync.value?['cash'] ?? 0,
                    icon: Icons.money,
                    color: Colors.green,
                    loading: balancesAsync.isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _BalanceCard(
                    label: 'Mobile Money',
                    amount: balancesAsync.value?['mobileMoney'] ?? 0,
                    icon: Icons.phone_android,
                    color: Colors.blue,
                    loading: balancesAsync.isLoading,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Apport'),
                  onPressed: () =>
                      _showOperationDialog(context, ref, TreasuryOperationType.supply),
                ),
                ActionChip(
                  avatar: const Icon(Icons.remove, size: 18),
                  label: const Text('Retrait'),
                  onPressed: () =>
                      _showOperationDialog(context, ref, TreasuryOperationType.removal),
                ),
                ActionChip(
                  avatar: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Transfert'),
                  onPressed: () =>
                      _showOperationDialog(context, ref, TreasuryOperationType.transfer),
                ),
                ActionChip(
                  avatar: const Icon(Icons.tune, size: 18),
                  label: const Text('Ajustement'),
                  onPressed: () =>
                      _showOperationDialog(context, ref, TreasuryOperationType.adjustment),
                ),
              ],
            ),
          ),
        ),

        const SliverPadding(
          padding: EdgeInsets.all(16.0),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Historique des mouvements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Operations List
        operationsAsync.when(
          data: (ops) => ops.isEmpty
              ? const SliverFillRemaining(
                  child: Center(child: Text('Aucun mouvement enregistré')),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final op = ops[index];
                      return _OperationListTile(operation: op);
                    },
                    childCount: ops.length,
                  ),
                ),
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) => SliverFillRemaining(
            child: Center(child: Text('Erreur: $e')),
          ),
        ),
      ],
    );
  }

  void _showOperationDialog(
      BuildContext context, WidgetRef ref, TreasuryOperationType type) {
    showDialog(
      context: context,
      builder: (context) => TreasuryOperationDialog(type: type),
    ).then((_) {
      // Re-fetch balances after dialog closes
      ref.invalidate(treasuryBalancesProvider);
    });
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final int amount;
  final IconData icon;
  final Color color;
  final bool loading;

  const _BalanceCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          if (loading)
            const SizedBox(
                height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else
            Text(
              '${NumberFormat('#,###').format(amount)} CFA',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

class _OperationListTile extends StatelessWidget {
  final TreasuryOperation operation;

  const _OperationListTile({required this.operation});

  @override
  Widget build(BuildContext context) {
    final isNegative = operation.type == TreasuryOperationType.removal ||
        (operation.type == TreasuryOperationType.transfer &&
            operation.fromAccount != null);

    IconData icon = Icons.help_outline;
    Color color = Colors.grey;
    String typeLabel = '';

    switch (operation.type) {
      case TreasuryOperationType.supply:
        icon = Icons.add_circle_outline;
        color = Colors.green;
        typeLabel = 'Apport';
        break;
      case TreasuryOperationType.removal:
        icon = Icons.remove_circle_outline;
        color = Colors.red;
        typeLabel = 'Retrait';
        break;
      case TreasuryOperationType.transfer:
        icon = Icons.swap_horiz;
        color = Colors.blue;
        typeLabel = 'Transfert';
        break;
      case TreasuryOperationType.adjustment:
        icon = Icons.tune;
        color = Colors.orange;
        typeLabel = 'Ajustement';
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(operation.reason ?? operation.notes ?? typeLabel),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('dd MMM yyyy, HH:mm').format(operation.date)} • ${operation.number ?? ""}',
            style: const TextStyle(fontSize: 12),
          ),
          if (operation.recipient != null && operation.recipient!.isNotEmpty)
            Text(
              'Bénéficiaire: ${operation.recipient}',
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isNegative ? "-" : "+"}${NumberFormat('#,###').format(operation.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.red : Colors.green,
            ),
          ),
          Text(
            operation.toAccount?.name ?? operation.fromAccount?.name ?? "N/A",
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
