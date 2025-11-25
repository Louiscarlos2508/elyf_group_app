import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/stock_item.dart';

/// Widget for selecting a stock item.
class StockItemSelector extends ConsumerWidget {
  const StockItemSelector({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
  });

  final StockItem? selectedItem;
  final ValueChanged<StockItem> onItemSelected;

  Future<void> _selectStockItem(BuildContext context, WidgetRef ref) async {
    final stockState = await ref.read(stockStateProvider.future);
    final items = stockState.items;

    if (items.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun produit en stock')),
      );
      return;
    }

    if (!context.mounted) return;
    final selected = await showDialog<StockItem>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sélectionner un produit'),
        children: items.map((item) {
          return ListTile(
            title: Text(item.name),
            subtitle: Text(
              'Stock: ${item.quantity} ${item.unit} • ${item.type == StockType.finishedGoods ? "Produit fini" : "Matière première"}',
            ),
            onTap: () => Navigator.of(context).pop(item),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      onItemSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _selectStockItem(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Produit',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedItem != null
                        ? '${selectedItem!.name} (${selectedItem!.quantity} ${selectedItem!.unit})'
                        : 'Sélectionner un produit',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: selectedItem != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                      color: selectedItem != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

