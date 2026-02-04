import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../widgets/stock_adjustment_dialog.dart';
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
  String? _moduleId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Récupérer l'entreprise active depuis le tenant provider
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    activeEnterpriseAsync.whenData((enterprise) {
      if (_enterpriseId == null && enterprise != null) {
        _enterpriseId = enterprise.id;
        _moduleId = 'gaz';
      }
    });
    
    if (_enterpriseId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stock')),
        body: const Center(
          child: Text('Aucune entreprise active disponible'),
        ),
      );
    }

    // Récupérer les points de vente depuis le provider
    final pointsOfSaleAsync = ref.watch(
      pointsOfSaleProvider((
        enterpriseId: _enterpriseId!,
        moduleId: _moduleId!,
      )),
    );

    // Get all stocks
    final allStocksAsync = ref.watch(
      cylinderStocksProvider((
        enterpriseId: _enterpriseId!,
        status: null, // Get all statuses
        siteId: null,
      )),
    );

    return pointsOfSaleAsync.when(
      data: (pointsOfSale) {
        final activePointsOfSale = pointsOfSale
            .where((pos) => pos.isActive)
            .toList();

        return CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: StockHeader(
                isMobile: isMobile,
                onAdjustStock: () {
                  showDialog(
                    context: context,
                    builder: (context) => StockAdjustmentDialog(
                      enterpriseId: _enterpriseId!,
                      moduleId: _moduleId!,
                    ),
                  );
                },
              ),
            ),

            // KPI Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: allStocksAsync.when(
                  data: (allStocks) => StockKpiSection(
                    allStocks: allStocks,
                    activePointsOfSale: activePointsOfSale,
                    pointsOfSale: pointsOfSale,
                  ),
                  loading: () => AppShimmers.statsGrid(context),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Tab section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECECF0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
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
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              sliver: allStocksAsync.when(
                data: (allStocks) => StockPosList(
                  activePointsOfSale: activePointsOfSale,
                  allStocks: allStocks,
                ),
                loading: () => SliverFillRemaining(
                  child: AppShimmers.list(context),
                ),
                error: (error, stackTrace) => SliverFillRemaining(
                  child: ErrorDisplayWidget(
                    error: error,
                    title: 'Erreur de chargement',
                    message: 'Impossible de charger le stock.',
                    onRetry: () => ref.refresh(
                      cylinderStocksProvider((
                        enterpriseId: _enterpriseId!,
                        status: null,
                        siteId: null,
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => AppShimmers.list(context),
      error: (error, stackTrace) => ErrorDisplayWidget(
        error: error,
        title: 'Erreur de chargement',
        message: 'Impossible de charger les points de vente.',
        onRetry: () => ref.refresh(
          pointsOfSaleProvider((
            enterpriseId: _enterpriseId!,
            moduleId: _moduleId!,
          )),
        ),
      ),
    );
  }
}
