import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/product.dart';
import '../../../../domain/entities/purchase.dart';
import '../../../../application/providers.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

class PriceHistoryDialog extends ConsumerWidget {
  final Product product;

  const PriceHistoryDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text('Historique des prix : ${product.name}'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: FutureBuilder<List<PurchaseItem>>(
          future: ref.read(storeControllerProvider).getProductPurchaseHistory(product.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }
            final history = snapshot.data ?? [];
            if (history.isEmpty) {
              return const Center(child: Text('Aucun historique d\'achat trouvé'));
            }

            return ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return ListTile(
                  title: Text(CurrencyFormatter.formatFCFA(item.purchasePrice)),
                  subtitle: Text('Quantité: ${item.quantity}'),
                  trailing: const Icon(Icons.history_outlined),
                );
              },
            );
          },
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
