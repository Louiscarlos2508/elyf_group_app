import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart' show activeEnterpriseProvider;
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import '../../../widgets/stock_adjustment_dialog.dart';
import '../../../widgets/cylinder_filling_dialog.dart';
import '../stock/stock_kpi_section.dart';
import '../stock/stock_pos_list.dart';
import '../stock/stock_transfer_screen.dart';

class StockStatusTab extends ConsumerWidget {
  const StockStatusTab({super.key, required this.enterpriseId, required this.moduleId});

  final String enterpriseId;
  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    final pointsOfSaleAsync = ref.watch(
      enterprisesByParentAndTypeProvider((
        parentId: enterpriseId,
        type: EnterpriseType.gasPointOfSale,
      )),
    );

    final allStocksAsync = ref.watch(gazStocksProvider);

    return pointsOfSaleAsync.when(
      data: (pointsOfSale) {
        final activePointsOfSale = pointsOfSale
            .where((pos) => pos.isActive)
            .toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    ElyfButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => StockTransferScreen()),
                        );
                      },
                      icon: Icons.swap_horiz,
                      variant: ElyfButtonVariant.outlined,
                      size: ElyfButtonSize.small,
                      child: const Text('Transferts'),
                    ),


                  ],
                ),
              ),
            ),

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
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'INVENTAIRE DÉPÔT PRINCIPAL',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

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
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Suivi Points de vente (${activePointsOfSale.length})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),

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
                        enterpriseId: enterpriseId,
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
          enterprisesByParentAndTypeProvider((
            parentId: enterpriseId,
            type: EnterpriseType.gasPointOfSale,
          )),
        ),
      ),
    );
  }
}
