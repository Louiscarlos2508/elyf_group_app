import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';

import '../../application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'point_of_sale_table/pos_table_row.dart';

/// Tableau des points de vente selon le design Figma.
class PointOfSaleTable extends ConsumerWidget {
  const PointOfSaleTable({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pointsOfSaleAsync = ref.watch(
      pointsOfSaleProvider((enterpriseId: enterpriseId, moduleId: moduleId)),
    );

    return pointsOfSaleAsync.when(
      data: (pointsOfSale) {
        if (pointsOfSale.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun point de vente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez votre premier point de vente pour commencer',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                // Debug info only shown if needed
                if (enterpriseId.isEmpty || moduleId.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Debug: enterpriseId=$enterpriseId, moduleId=$moduleId',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pointsOfSale.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          itemBuilder: (context, index) => PosTableRow(
            pointOfSale: pointsOfSale[index],
            enterpriseId: enterpriseId,
            moduleId: moduleId,
          ),
        );
      },
      loading: () => AppShimmers.table(context, rows: 3),
      error: (error, stack) {
        AppLogger.error(
          'Erreur lors du chargement des points de vente: $error',
          name: 'gaz.point_of_sale',
          error: error,
          stackTrace: stack,
        );
        
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Impossible de charger les points de vente',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
