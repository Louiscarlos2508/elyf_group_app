import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';

import '../../domain/entities/stock_item.dart';

/// Widget displaying finished goods stock list.
class DashboardStockList extends ConsumerWidget {
  const DashboardStockList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stockStateAsync = ref.watch(stockStateProvider);

    return stockStateAsync.when(
      data: (stockState) {
        final finishedGoods = stockState.items
            .where((StockItem item) => item.type == StockType.finishedGoods)
            .toList();

        return DefaultTabController(
          length: 2,
          child: ElyfCard(
            isGlass: true,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'STOCK',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                          indicatorColor: theme.colorScheme.primary,
                          indicatorSize: TabBarIndicatorSize.label,
                          dividerColor: Colors.transparent,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                          labelStyle: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          unselectedLabelStyle: theme.textTheme.titleSmall,
                          tabs: const [
                            Tab(text: 'Produits Finis'),
                            Tab(text: 'Matières 1ères'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 0, endIndent: 0, color: Colors.transparent),
                SizedBox(
                  height: 220,
                  child: TabBarView(
                    children: [
                      _buildProductList(context, finishedGoods),
                      _buildRawMaterialsList(context, stockState),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Column(
        children: [
          ElyfShimmer(child: ElyfShimmer.listTile()),
          const SizedBox(height: 8),
          ElyfShimmer(child: ElyfShimmer.listTile()),
        ],
      ),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        title: 'Stock indisponible',
        message: 'Impossible de charger le stock.',
        onRetry: () => ref.refresh(stockStateProvider),
      ),
    );
  }

  Widget _buildProductList(BuildContext context, List<StockItem> items) {
    if (items.isEmpty) {
      return const _EmptyStock(message: 'Aucun produit fini');
    }
    return _ScrollableList(
      children: items.asMap().entries.map((entry) {
        return _StockListTile(
          name: entry.value.name,
          quantity: entry.value.quantity,
          unit: entry.value.unit,
          isLowStock: entry.value.quantity < 100,
          isLast: entry.key == items.length - 1,
        );
      }).toList(),
    );
  }

  Widget _buildRawMaterialsList(BuildContext context, StockState state) {
    final List<Widget> children = [];

    // Bobines
    for (final bobine in state.bobineStocks) {
      children.add(
        _StockListTile(
          name: 'Bobine: ${bobine.type}',
          quantity: bobine.quantity.toDouble(),
          unit: 'unité',
          isLowStock: bobine.quantity < 5,
          isLast: false,
        ),
      );
    }

    // Packaging
    for (var i = 0; i < state.packagingStocks.length; i++) {
        final packaging = state.packagingStocks[i];
        children.add(
          _StockListTile(
            name: 'Emballage: ${packaging.type}',
            quantity: packaging.quantity.toDouble(),
            unit: 'unité',
            isLowStock: packaging.quantity < 500,
            isLast: i == state.packagingStocks.length - 1 && state.bobineStocks.isEmpty,
          ),
        );
    }

    if (children.isEmpty) {
      return const _EmptyStock(message: 'Aucune matière première');
    }

    return _ScrollableList(children: children);
  }
}

class _ScrollableList extends StatelessWidget {
  const _ScrollableList({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: children,
    );
  }
}

class _StockListTile extends StatelessWidget {
  const _StockListTile({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.isLowStock,
    this.isLast = false,
  });

  final String name;
  final double quantity;
  final String unit;
  final bool isLowStock;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              )
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: isLowStock
            ? Text(
                'Stock faible',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade700,
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isLowStock
                ? Colors.orange.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${quantity.toInt()} $unit',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isLowStock
                  ? Colors.orange.shade900
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStock extends StatelessWidget {
  const _EmptyStock({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
