import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/point_of_sale.dart';
import '../../widgets/point_of_sale_stock_card.dart';
import 'stock/stock_header.dart';
import 'stock/stock_kpi_section.dart';
import 'stock/stock_pos_list.dart';

/// Écran de gestion du stock de bouteilles par point de vente - matches Figma design.
class GazStockScreen extends ConsumerStatefulWidget {
  const GazStockScreen({super.key});

  @override
  ConsumerState<GazStockScreen> createState() => _GazStockScreenState();
}

class _GazStockScreenState extends ConsumerState<GazStockScreen> {
  String? _enterpriseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    // TODO: Récupérer enterpriseId depuis le contexte/tenant
    _enterpriseId ??= 'default_enterprise';

    // Mock points of sale for now
    final pointsOfSale = [
      PointOfSale(
        id: 'pos_1',
        name: 'Point de vente 1',
        address: '123 Rue de la Gaz',
        contact: '0123456789',
        enterpriseId: _enterpriseId!,
        moduleId: 'gaz',
        isActive: true,
      ),
      PointOfSale(
        id: 'pos_2',
        name: 'Point de vente 2',
        address: '456 Rue de la Gaz',
        contact: '0987654321',
        enterpriseId: _enterpriseId!,
        moduleId: 'gaz',
        isActive: true,
      ),
    ];

    final activePointsOfSale = pointsOfSale.where((pos) => pos.isActive).toList();

    // Get all stocks
    final allStocksAsync = ref.watch(
      cylinderStocksProvider(
        (
          enterpriseId: _enterpriseId!,
          status: null, // Get all statuses
          siteId: null,
        ),
      ),
    );

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: StockHeader(
            isMobile: isMobile,
            onAdjustStock: () {
              // TODO: Show stock adjustment dialog
            },
          ),
        ),

        // KPI Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: allStocksAsync.when(
              data: (allStocks) => StockKpiSection(
                allStocks: allStocks,
                activePointsOfSale: activePointsOfSale,
                pointsOfSale: pointsOfSale,
              ),
              loading: () => const SizedBox(
                height: 169,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Tab section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFECECF0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Points de vente actifs (${activePointsOfSale.length})',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF0A0A0A),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Points of sale cards
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          sliver: allStocksAsync.when(
            data: (allStocks) => StockPosList(
              activePointsOfSale: activePointsOfSale,
              allStocks: allStocks,
            ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Erreur: $e')),
            ),
          ),
        ),
      ],
    );
  }
}
