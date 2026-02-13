import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/product.dart';
import 'package:elyf_groupe_app/features/boutique/application/providers.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/stock_movement.dart';

class PriceHistoryDialog extends ConsumerWidget {
  final Product product;

  const PriceHistoryDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(stockMovementsProvider(product.id));

    return AlertDialog(
      title: Text('Historique de ${product.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: movementsAsync.when(
          data: (movements) {
            if (movements.isEmpty) {
              return const Center(child: Text('Aucun mouvement enregistré.'));
            }
            // Sort by date desc
            final sortedMovements = List<StockMovement>.from(movements)
              ..sort((a, b) => b.date.compareTo(a.date));

            return ListView.separated(
              itemCount: sortedMovements.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final move = sortedMovements[index];
                return ListTile(
                  title: Text(move.type.name.toUpperCase()),
                  subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(move.date)),
                  trailing: Text(
                    '${move.quantity > 0 ? "+" : ""}${move.quantity}',
                    style: TextStyle(
                      color: move.quantity > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Erreur: $e')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
