import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../../boutique/presentation/screens/sections/widgets/treasury_operation_dialog.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';

class TreasuryScreen extends ConsumerWidget {
  const TreasuryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailySummaryAsync = ref.watch(dailyDashboardSummaryProvider);
    final historyAsync = ref.watch(treasuryHistoryProvider);
    final balancesAsync = ref.watch(absoluteTreasuryBalanceProvider);

    return CustomScrollView(
      slivers: [
        // Premium Header
        const ElyfModuleHeader(
          title: "Trésorerie",
          subtitle: "Suivi des flux de caisse et OM",
          module: EnterpriseModule.eau,
        ),

        // Balance Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _BalanceCard(
                    label: 'Solde Espèces',
                    amount: balancesAsync.maybeWhen(
                      data: (b) => b['cash'] ?? 0,
                      orElse: () => 0,
                    ),
                    todayDelta: dailySummaryAsync.maybeWhen(
                      data: (m) => m.cashCollections - m.cashExpenses,
                      orElse: () => 0,
                    ),
                    icon: Icons.payments_outlined,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _BalanceCard(
                    label: 'Solde Mobile Money',
                    amount: balancesAsync.maybeWhen(
                      data: (b) => b['mobileMoney'] ?? 0,
                      orElse: () => 0,
                    ),
                    todayDelta: dailySummaryAsync.maybeWhen(
                      data: (m) => m.mobileMoneyCollections - m.mobileMoneyExpenses,
                      orElse: () => 0,
                    ),
                    icon: Icons.smartphone_outlined,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Quick Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green),
                  label: const Text('Apport'),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const TreasuryOperationDialog(type: TreasuryOperationType.supply),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                  label: const Text('Retrait'),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const TreasuryOperationDialog(type: TreasuryOperationType.removal),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.swap_horiz, size: 18, color: Colors.blue),
                  label: const Text('Transfert'),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const TreasuryOperationDialog(type: TreasuryOperationType.transfer),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.tune, size: 18, color: Colors.orange),
                  label: const Text('Ajuster'),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const TreasuryOperationDialog(type: TreasuryOperationType.adjustment),
                  ),
                ),

              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'Derniers mouvements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // History List
        historyAsync.when(
          data: (movements) => movements.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Aucun mouvement aujourd\'hui')),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _MovementTile(movement: movements[index]),
                    childCount: movements.length,
                  ),
                ),
          loading: () => const SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            )),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Center(child: Text('Erreur: $e')),
          ),
        ),
        
        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.amount,
    required this.todayDelta,
    required this.icon,
    required this.color,
  });

  final String label;
  final int amount;
  final int todayDelta;
  final IconData icon;
  final Color color;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              if (todayDelta != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (todayDelta > 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${todayDelta > 0 ? "+" : ""}${NumberFormat('#,###').format(todayDelta)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: todayDelta > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat('#,###').format(amount)} CFA',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});
  final TreasuryMovement movement;

  @override
  Widget build(BuildContext context) {
    final color = movement.isIncome ? Colors.green : Colors.red;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(
          movement.isIncome ? Icons.add : Icons.remove,
          color: color,
          size: 20,
        ),
      ),
      title: Text(movement.label),
      subtitle: Text(
        '${DateFormat('HH:mm').format(movement.date)} • ${movement.category} • ${movement.method.label}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '${movement.isIncome ? "+" : "-"}${NumberFormat('#,###').format(movement.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
