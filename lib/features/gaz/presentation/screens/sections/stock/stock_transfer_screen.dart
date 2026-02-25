import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/stock_transfer.dart';
import 'package:elyf_groupe_app/features/gaz/presentation/widgets/stock_transfer_dialog.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

class StockTransferScreen extends ConsumerWidget {
  const StockTransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    if (activeEnterprise == null) return const Scaffold(body: Center(child: Text('Aucune entreprise active')));

    final transfersAsync = ref.watch(stockTransfersProvider(activeEnterprise.id));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transferts de Stock'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'En cours'),
              Tab(text: 'Historique'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => ref.invalidate(stockTransfersProvider(activeEnterprise.id)),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: transfersAsync.when(
          data: (transfers) {
            // Sort by date (newest first)
            final sortedTransfers = [...transfers]..sort((a, b) {
              final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return dateB.compareTo(dateA);
            });

            final active = sortedTransfers.where((t) => 
              t.status == StockTransferStatus.pending || 
              t.status == StockTransferStatus.shipped
            ).toList();

            final history = sortedTransfers.where((t) => 
              t.status == StockTransferStatus.received || 
              t.status == StockTransferStatus.cancelled
            ).toList();

            return TabBarView(
              children: [
                _TransferList(transfers: active, currentEnterpriseId: activeEnterprise.id, emptyMessage: 'Aucun transfert en cours'),
                _TransferList(transfers: history, currentEnterpriseId: activeEnterprise.id, emptyMessage: 'Historique vide'),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showDialog(
            context: context,
            builder: (context) => StockTransferDialog(fromEnterpriseId: activeEnterprise.id),
          ),
          label: const Text('Nouveau Transfert'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _TransferList extends StatelessWidget {
  const _TransferList({required this.transfers, required this.currentEnterpriseId, required this.emptyMessage});
  final List<StockTransfer> transfers;
  final String currentEnterpriseId;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transfers.length,
      itemBuilder: (context, index) {
        return _TransferCard(transfer: transfers[index], currentEnterpriseId: currentEnterpriseId);
      },
    );
  }
}

class _TransferCard extends ConsumerWidget {
  const _TransferCard({required this.transfer, required this.currentEnterpriseId});

  final StockTransfer transfer;
  final String currentEnterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOutgoing = transfer.fromEnterpriseId == currentEnterpriseId;
    final userId = ref.watch(currentUserIdProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusBadge(transfer: transfer, isOutgoing: isOutgoing),
                Text(
                  _formatDate(transfer.createdAt ?? DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isOutgoing ? Icons.upload : Icons.download,
                  color: isOutgoing ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOutgoing 
                      ? 'Vers destination ID: ${transfer.toEnterpriseId}' 
                      : 'Depuis source ID: ${transfer.fromEnterpriseId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...transfer.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${item.weight}kg (${item.status.label}) x ${item.quantity}'),
            )),
            if (transfer.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${transfer.notes}',
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isOutgoing && transfer.status == StockTransferStatus.pending)
                   ElyfButton(
                    onPressed: () => _handleShip(context, ref, userId),
                    variant: ElyfButtonVariant.filled,
                    child: const Text('Expédier'),
                  ),
                if (!isOutgoing && transfer.status == StockTransferStatus.shipped)
                   ElyfButton(
                    onPressed: () => _handleReceive(context, ref, userId),
                    variant: ElyfButtonVariant.filled,
                    child: const Text('Recevoir'),
                  ),
                if (transfer.status == StockTransferStatus.pending || 
                    (isOutgoing && transfer.status == StockTransferStatus.shipped))
                  const SizedBox(width: 8),
                if (transfer.status == StockTransferStatus.pending || 
                    (isOutgoing && transfer.status == StockTransferStatus.shipped))
                   ElyfButton(
                    onPressed: () => _handleCancel(context, ref, userId),
                    variant: ElyfButtonVariant.outlined,
                    child: const Text('Annuler'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, "0")}';
  }

  Future<void> _handleShip(BuildContext context, WidgetRef ref, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer l\'expédition'),
        content: const Text('Le stock sera déduit de votre inventaire actuel.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(stockTransferControllerProvider).shipTransfer(transfer.id, userId);
        ref.invalidate(stockTransfersProvider(currentEnterpriseId));
        ref.invalidate(cylinderStocksProvider((enterpriseId: currentEnterpriseId, status: null, siteId: null)));
      } catch (e) {
        if (context.mounted) NotificationService.showError(context, e.toString());
      }
    }
  }

  Future<void> _handleReceive(BuildContext context, WidgetRef ref, String userId) async {
    try {
      await ref.read(stockTransferControllerProvider).receiveTransfer(transfer.id, userId);
      ref.invalidate(stockTransfersProvider(currentEnterpriseId));
      ref.invalidate(cylinderStocksProvider((enterpriseId: currentEnterpriseId, status: null, siteId: null)));
      if (context.mounted) NotificationService.showSuccess(context, 'Stock reçu avec succès');
    } catch (e) {
      if (context.mounted) NotificationService.showError(context, e.toString());
    }
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref, String userId) async {
     final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler le transfert'),
        content: const Text('Cette action est irréversible. Si le stock a été expédié, il sera réintégré.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Retour')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Annuler le transfert')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(stockTransferControllerProvider).cancelTransfer(transfer.id, userId);
        ref.invalidate(stockTransfersProvider(currentEnterpriseId));
        ref.invalidate(cylinderStocksProvider((enterpriseId: currentEnterpriseId, status: null, siteId: null)));
      } catch (e) {
        if (context.mounted) NotificationService.showError(context, e.toString());
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.transfer, required this.isOutgoing});
  final StockTransfer transfer;
  final bool isOutgoing;

  Color _getStatusColor(StockTransferStatus status) {
    switch (status) {
      case StockTransferStatus.pending: return Colors.orange;
      case StockTransferStatus.shipped: return Colors.blue;
      case StockTransferStatus.received: return Colors.green;
      case StockTransferStatus.cancelled: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(transfer.status);
    final isActionRequired = (isOutgoing && transfer.status == StockTransferStatus.pending) ||
                             (!isOutgoing && transfer.status == StockTransferStatus.shipped);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActionRequired ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: isActionRequired ? [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActionRequired) ...[
            const Icon(Icons.notifications_active, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            isActionRequired 
              ? (isOutgoing ? 'ACTION : À EXPÉDIER' : 'ACTION : À RECEVOIR')
              : transfer.status.label.toUpperCase(),
            style: TextStyle(
              color: isActionRequired ? Colors.white : color, 
              fontWeight: FontWeight.bold, 
              fontSize: 11
            ),
          ),
        ],
      ),
    );
  }
}
