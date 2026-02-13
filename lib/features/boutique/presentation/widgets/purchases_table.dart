
import 'package:flutter/material.dart';
import '../../domain/entities/purchase.dart';

class PurchasesTable extends StatelessWidget {
  const PurchasesTable({
    super.key,
    required this.purchases,
    required this.formatCurrency,
    this.onActionTap,
  });

  final List<Purchase> purchases;
  final String Function(int) formatCurrency;
  final void Function(Purchase purchase, String action)? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (purchases.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        child: Text(
          "Aucun achat enregistré",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return _buildDesktopTable(theme);
        }
        return _buildMobileList(theme);
      },
    );
  }

  Widget _buildDesktopTable(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerHighest,
        ),
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('N°')),
          DataColumn(label: Text('Fournisseur')),
          DataColumn(label: Text('Articles')),
          DataColumn(label: Text('Total'), numeric: true),
          DataColumn(label: Text('Actions')),
        ],
        rows: purchases.map((purchase) {
          final itemsSummary = purchase.items.length == 1 
            ? purchase.items.first.productName 
            : '${purchase.items.length} produits';
            
          return DataRow(
            cells: [
              DataCell(Text('${purchase.date.day}/${purchase.date.month}/${purchase.date.year}')),
              DataCell(Text(purchase.number ?? '-')),
              DataCell(Text(purchase.supplierId ?? '-')),
              DataCell(Text(itemsSummary)),
              DataCell(
                Text(
                  formatCurrency(purchase.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 18),
                      onPressed: () => onActionTap?.call(purchase, 'view'),
                      tooltip: 'Voir détails',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () => onActionTap?.call(purchase, 'delete'),
                      tooltip: 'Supprimer',
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(ThemeData theme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: purchases.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        final itemsSummary = purchase.items.length == 1 
          ? purchase.items.first.productName 
          : '${purchase.items.length} produits';

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: theme.colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          title: Text(
            purchase.number ?? purchase.supplierId ?? 'Achat Stock',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${purchase.date.day}/${purchase.date.month} • ${purchase.supplierId ?? "Stock"} • $itemsSummary',
            style: theme.textTheme.bodySmall,
          ),
          trailing: Text(
            formatCurrency(purchase.totalAmount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () => onActionTap?.call(purchase, 'view'),
        );
      },
    );
  }
}
