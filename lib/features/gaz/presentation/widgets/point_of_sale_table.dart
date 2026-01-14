import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import 'point_of_sale_table/pos_table_header.dart';
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
          return Container(
            padding: const EdgeInsets.all(25.285),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1.305,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun point de vente',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez votre premier point de vente',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(25.285, 25.285, 1.305, 1.305),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.1),
              width: 1.305,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de la carte
              Row(
                children: [
                  const Icon(Icons.store, size: 20, color: Color(0xFF0A0A0A)),
                  const SizedBox(width: 8),
                  Text(
                    'Points de vente',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 42),
              // Tableau
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.1),
                    width: 1.305,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    // En-tête du tableau
                    const PosTableHeader(),
                    // Corps du tableau
                    ...pointsOfSale.map(
                      (pos) => PosTableRow(
                        pointOfSale: pos,
                        enterpriseId: enterpriseId,
                        moduleId: moduleId,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(25.285),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.1),
            width: 1.305,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(25.285),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.1),
            width: 1.305,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
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
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
