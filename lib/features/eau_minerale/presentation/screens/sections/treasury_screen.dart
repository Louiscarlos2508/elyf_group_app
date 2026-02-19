import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../domain/entities/treasury_movement.dart';
import '../../widgets/z_report_dialog.dart';
import './widgets/treasury_operation_dialog.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';

class TreasuryScreen extends ConsumerWidget {
  const TreasuryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailySummaryAsync = ref.watch(dailyDashboardSummaryProvider);
    final historyAsync = ref.watch(treasuryHistoryProvider);
    final sessionAsync = ref.watch(currentClosingSessionProvider);

    return CustomScrollView(
      slivers: [
        // App Bar / Header could be here or handled by shell.
        // But since other modules have headers, let's keep it consistent.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRÉSORERIE',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Suivi des flux de caisse et OM',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Balance Cards
        SliverToBoxAdapter(
          child: dailySummaryAsync.maybeWhen(
            data: (metrics) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _BalanceCard(
                      label: 'Caisse (Espèces)',
                      amount: metrics.cashCollections - metrics.cashExpenses,
                      icon: Icons.payments_outlined,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _BalanceCard(
                      label: 'Mobile Money',
                      amount: metrics.mobileMoneyCollections - metrics.mobileMoneyExpenses,
                      icon: Icons.smartphone_outlined,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
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
                sessionAsync.maybeWhen(
                  data: (session) => ActionChip(
                    avatar: Icon(session != null ? Icons.lock_clock : Icons.lock_open, size: 18),
                    label: Text(session != null ? 'Z-Report' : 'Ouvrir Session'),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => ZReportDialog(),
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
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
    required this.icon,
    required this.color,
  });

  final String label;
  final int amount;
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
          Icon(icon, color: color, size: 28),
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
