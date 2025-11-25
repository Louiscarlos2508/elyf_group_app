import 'package:flutter/material.dart';

import '../../domain/entities/purchase.dart';
import 'purchase_item_form.dart';
import 'purchase_item_row.dart';

class PurchaseItemsList extends StatelessWidget {
  const PurchaseItemsList({
    super.key,
    required this.items,
    required this.onRemoveItem,
    required this.onCalculateTotal,
  });

  final List<PurchaseItemForm> items;
  final void Function(int index) onRemoveItem;
  final int Function() onCalculateTotal;

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return PurchaseItemRow(
            item: item,
            onRemove: () => onRemoveItem(index),
          );
        }),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatCurrency(onCalculateTotal()),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

