import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../application/providers.dart';
import '../stock/stock_pos_list.dart';
import '../../../widgets/gaz_kpi_card.dart';
import '../../../widgets/stock_summary_card.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';

/// Onglet de distribution pour les managers.
/// Affiche la liste des points de vente triés par urgence de stock.
class DistributionTab extends ConsumerWidget {
  const DistributionTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeEnterpriseId = ref.watch(activeEnterpriseIdProvider).value;

    if (activeEnterpriseId == null) {
      return const Center(child: Text('Aucune entreprise sélectionnée'));
    }

    final pointsOfSaleAsync = ref.watch(
      enterprisesByParentAndTypeProvider((
        parentId: activeEnterpriseId,
        type: EnterpriseType.gasPointOfSale,
      )),
    );

    final allStocksAsync = ref.watch(
      cylinderStocksProvider((
        enterpriseId: activeEnterpriseId,
        status: null,
        siteId: null,
      )),
    );

    final cylindersAsync = ref.watch(cylindersProvider);

    return pointsOfSaleAsync.when(
      data: (pointsOfSale) {
        final activePointsOfSale = pointsOfSale
            .where((pos) => pos.isActive)
            .toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logistique & Distribution',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Optimisez le ravitaillement de vos points de vente en temps réel.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Depot Stock Summary Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.business, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'DISPONIBLE AU DÉPÔT PRINCIPAL',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    cylindersAsync.when(
                      data: (cylinders) => StockSummaryCard(cylinders: cylinders),
                      loading: () => AppShimmers.statsGrid(context),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text(
                      'Points de Vente Prioritaires',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDV classés par urgence de stock (Pleines)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            allStocksAsync.when(
              data: (allStocks) => StockPosList(
                activePointsOfSale: activePointsOfSale,
                allStocks: allStocks,
              ),
              loading: () => SliverFillRemaining(
                child: AppShimmers.list(context),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Erreur stocks: $e')),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur POS: $e')),
    );
  }
}
