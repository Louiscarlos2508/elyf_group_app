import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared.dart';
import '../../application/providers.dart';
import '../../domain/entities/stock_movement.dart';

class GazStockHistoryContent extends ConsumerWidget {
  const GazStockHistoryContent({
    super.key,
    required this.enterpriseId,
    required this.startDate,
    required this.endDate,
    this.siteId,
  });

  final String enterpriseId;
  final DateTime startDate;
  final DateTime endDate;
  final String? siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(
      gazStockHistoryProvider((
        enterpriseId: enterpriseId,
        startDate: startDate,
        endDate: endDate,
        siteId: siteId,
      )),
    );

    return historyAsync.when(
      data: (movements) {
        if (movements.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('Aucun mouvement de stock sur cette période'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Historique des Mouvements',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movements.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final move = movements[index];
                return ListTile(
                  leading: _buildLeadingIcon(move.type),
                  title: Text(
                    '${move.type.label} - ${move.weight}kg (${move.status.label})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(move.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (move.notes != null)
                        Text(
                          move.notes!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                    ],
                  ),
                  trailing: Text(
                    '${move.quantityDelta > 0 ? "+" : ""}${move.quantityDelta}',
                    style: TextStyle(
                      color: move.quantityDelta > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => AppShimmers.list(context),
      error: (error, _) => Text('Erreur: $error'),
    );
  }

  Widget _buildLeadingIcon(StockMovementType type) {
    switch (type) {
      case StockMovementType.sale:
        return CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: const Icon(Icons.shopping_cart, color: Colors.blue, size: 20),
        );
      case StockMovementType.replenishment:
        return CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: const Icon(Icons.download, color: Colors.green, size: 20),
        );
      case StockMovementType.leak:
        return CircleAvatar(
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          child: const Icon(Icons.water_drop, color: Colors.orange, size: 20),
        );
      case StockMovementType.exchange:
        return CircleAvatar(
          backgroundColor: Colors.purple.withValues(alpha: 0.1),
          child: const Icon(Icons.sync_alt, color: Colors.purple, size: 20),
        );
      case StockMovementType.adjustment:
        return CircleAvatar(
          backgroundColor: Colors.grey.withValues(alpha: 0.1),
          child: const Icon(Icons.edit, color: Colors.grey, size: 20),
        );
      case StockMovementType.defective:
        return CircleAvatar(
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          child: const Icon(Icons.warning, color: Colors.red, size: 20),
        );
    }
  }
}
