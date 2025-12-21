import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/cylinder.dart';
import '../../../domain/entities/cylinder_stock.dart';
import '../../widgets/cylinder_stock_status_card.dart';

/// Écran de gestion du stock de bouteilles avec statuts.
class GazStockScreen extends ConsumerStatefulWidget {
  const GazStockScreen({super.key});

  @override
  ConsumerState<GazStockScreen> createState() => _GazStockScreenState();
}

class _GazStockScreenState extends ConsumerState<GazStockScreen> {
  String? _enterpriseId;
  CylinderStatus _selectedStatus = CylinderStatus.full;
  int? _selectedWeight;

  final List<int> _availableWeights = [3, 6, 10, 12];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    // TODO: Récupérer enterpriseId depuis le contexte/tenant
    _enterpriseId ??= 'default_enterprise';

    final stocksAsync = ref.watch(
      cylinderStocksProvider(
        (
          enterpriseId: _enterpriseId!,
          status: _selectedStatus,
          siteId: null,
        ),
      ),
    );

    return DefaultTabController(
      length: CylinderStatus.values.length,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        color: theme.colorScheme.primary,
                        size: isMobile ? 24 : 28,
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      Expanded(
                        child: Text(
                          'Gestion du Stock',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 20 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Filtrer par format:',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Tous'),
                        selected: _selectedWeight == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedWeight = null);
                          }
                        },
                      ),
                      ..._availableWeights.map((weight) {
                        return FilterChip(
                          label: Text('$weight kg'),
                          selected: _selectedWeight == weight,
                          onSelected: (selected) {
                            setState(() {
                              _selectedWeight = selected ? weight : null;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          stocksAsync.when(
            data: (stocks) {
              // Filtrer par poids si sélectionné
              final filteredStocks = _selectedWeight != null
                  ? stocks.where((s) => s.weight == _selectedWeight).toList()
                  : stocks;

              // Grouper par poids pour affichage, agréger toutes les quantités par statut
              final Map<int, Map<CylinderStatus, int>> grouped = {};
              for (final stock in filteredStocks) {
                grouped.putIfAbsent(stock.weight, () => {});
                final currentQty = grouped[stock.weight]![stock.status] ?? 0;
                grouped[stock.weight]![stock.status] = currentQty + stock.quantity;
              }

              if (grouped.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun stock',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                sliver: SliverList.separated(
                  itemCount: grouped.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final weight = grouped.keys.elementAt(index);
                    final statusMap = grouped[weight]!;

                    return CylinderStockStatusCard(
                      weight: weight,
                      fullQuantity: statusMap[CylinderStatus.full] ?? 0,
                      emptyAtStoreQuantity:
                          statusMap[CylinderStatus.emptyAtStore] ?? 0,
                      emptyInTransitQuantity:
                          statusMap[CylinderStatus.emptyInTransit] ?? 0,
                      defectiveQuantity:
                          statusMap[CylinderStatus.defective] ?? 0,
                      leakQuantity: statusMap[CylinderStatus.leak] ?? 0,
                    );
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Erreur: $e')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}