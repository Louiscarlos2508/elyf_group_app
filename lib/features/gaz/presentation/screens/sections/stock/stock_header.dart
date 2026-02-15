import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../widgets/gaz_header.dart';
import 'stock_transfer_screen.dart';

/// En-tête de l'écran de stock.
class StockHeader extends StatelessWidget {
  const StockHeader({
    super.key,
    required this.isMobile,
    required this.onAdjustStock,
  });

  final bool isMobile;
  final VoidCallback onAdjustStock;

  @override
  Widget build(BuildContext context) {
    return GazHeader(
      title: 'STOCK',
      subtitle: 'Stock des points de vente',
      asSliver: false,
      additionalActions: [
        ElyfButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const StockTransferScreen()),
            );
          },
          icon: Icons.swap_horiz,
          variant: ElyfButtonVariant.outlined,
          child: const Text('Transferts'),
        ),
        const SizedBox(width: 8),
        ElyfButton(
          onPressed: onAdjustStock,
          icon: Icons.add,
          variant: ElyfButtonVariant.outlined,
          child: const Text('Ajuster le stock'),
        ),
      ],
    );
  }
}
