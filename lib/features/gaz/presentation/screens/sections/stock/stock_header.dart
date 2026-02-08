import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../widgets/gaz_header.dart';

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
          onPressed: onAdjustStock,
          icon: Icons.add,
          variant: ElyfButtonVariant.outlined,
          child: const Text('Ajuster le stock'),
        ),
      ],
    );
  }
}
