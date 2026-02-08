import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/presentation/widgets/elyf_ui/atoms/elyf_icon_button.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';

/// Widget pour afficher une bouteille dans la liste des paramètres.
class CylinderListItem extends ConsumerWidget {
  const CylinderListItem({
    super.key,
    required this.cylinder,
    required this.onEdit,
    required this.onDelete,
  });

  final Cylinder cylinder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _getStockColor(BuildContext context, int stock) {
    if (stock <= 5) return Theme.of(context).colorScheme.error;
    if (stock <= 15) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFF10B981); // Emerald
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Récupérer le stock disponible (pleines) pour ce cylinder
    final stocksAsync = ref.watch(
      cylinderStocksProvider((
        enterpriseId: cylinder.enterpriseId,
        status: CylinderStatus.full,
        siteId: null,
      )),
    );

    // Récupérer les settings pour le prix en gros
    final settingsAsync = ref.watch(
      gazSettingsProvider((
        enterpriseId: cylinder.enterpriseId,
        moduleId: cylinder.moduleId,
      )),
    );

    return stocksAsync.when(
      data: (allStocks) {
        final fullStock = allStocks
            .where((s) => s.weight == cylinder.weight)
            .fold<int>(0, (sum, stock) => sum + stock.quantity);
        final stockColor = _getStockColor(context, fullStock);

        return settingsAsync.when(
          data: (settings) {
            final wholesalePrice = settings?.getWholesalePrice(cylinder.weight);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 500;

                    if (isCompact) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.local_fire_department,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${cylinder.weight} kg',
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: stockColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Stock: $fullStock',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: stockColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Détail: ${CurrencyFormatter.formatDouble(cylinder.sellPrice)} FCFA',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        'Gros: ${wholesalePrice != null && wholesalePrice > 0 ? CurrencyFormatter.formatDouble(wholesalePrice) : "-"} FCFA',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElyfButton(
                                  onPressed: onEdit,
                                  variant: ElyfButtonVariant.text,
                                  size: ElyfButtonSize.small,
                                  icon: Icons.edit,
                                  child: const Text('Modifier'),
                                ),
                                const SizedBox(width: 8),
                                ElyfButton(
                                  onPressed: onDelete,
                                  variant: ElyfButtonVariant.text,
                                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                                  textColor: theme.colorScheme.error,
                                  size: ElyfButtonSize.small,
                                  icon: Icons.delete,
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.local_fire_department,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${cylinder.weight} kg',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: stockColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Stock: $fullStock',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: stockColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Détail: ${CurrencyFormatter.formatDouble(cylinder.sellPrice)} FCFA | '
                                  'Gros: ${wholesalePrice != null && wholesalePrice > 0 ? CurrencyFormatter.formatDouble(wholesalePrice) : "-"} FCFA',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElyfIconButton(
                                icon: Icons.edit,
                                onPressed: onEdit,
                                tooltip: 'Modifier',
                                iconColor: theme.colorScheme.primary,
                                size: 36,
                                iconSize: 20,
                                useGlassEffect: false,
                              ),
                              const SizedBox(width: 4),
                              ElyfIconButton(
                                icon: Icons.delete,
                                onPressed: onDelete,
                                tooltip: 'Supprimer',
                                iconColor: theme.colorScheme.error,
                                size: 36,
                                iconSize: 20,
                                useGlassEffect: false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ),
          );
        },
          loading: () => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, __) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Erreur de chargement des paramètres'),
            ),
          ),
        );
      },
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Erreur de chargement du stock'),
        ),
      ),
    );
  }
}
