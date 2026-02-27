import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/notification_service.dart';
import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/app_shimmers.dart';
import 'cylinder_form_dialog.dart';

/// Tableau des tarifs des bouteilles selon le design Figma.
class BottlePriceTable extends ConsumerWidget {
  const BottlePriceTable({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  Future<void> _deleteCylinder(
    BuildContext context,
    WidgetRef ref,
    Cylinder cylinder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le type de bouteille'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la bouteille de ${cylinder.weight}kg ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final controller = ref.read(cylinderControllerProvider);
      final stockRepo = ref.read(cylinderStockRepositoryProvider);

      // Delete the cylinder
      await controller.deleteCylinder(cylinder.id);

      // Cascade delete associated stocks for this enterprise
      final allStocks = await stockRepo.getAllForEnterprise(enterpriseId);
      final relatedStocks = allStocks
          .where((s) => s.cylinderId == cylinder.id)
          .toList();
      for (final stock in relatedStocks) {
        await stockRepo.deleteStock(stock.id);
      }

      if (!context.mounted) return;

      // Small delay to allow Drift stream to propagate the soft-delete internally
      await Future<void>.delayed(const Duration(milliseconds: 300));

      ref.invalidate(cylindersProvider);
      ref.invalidate(gazStocksProvider);
      ref.invalidate(cylinderStocksProvider);

      NotificationService.showSuccess(
        context,
        'Type de bouteille supprimé avec succès',
      );
    } catch (e) {
      if (!context.mounted) return;
      NotificationService.showError(
        context,
        'Erreur lors de la suppression: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cylindersAsync = ref.watch(cylindersProvider);
    final settingsAsync = ref.watch(
      gazSettingsProvider((enterpriseId: enterpriseId, moduleId: moduleId)),
    );

    return settingsAsync.when(
      data: (settings) {
        // Derive weights from settings price keys — always complete, even on new devices
        final weightsFromSettings = {
          ...?settings?.retailPrices.keys,
          ...?settings?.wholesalePrices.keys,
          ...?settings?.purchasePrices.keys,
        }.toList()..sort();

        // Build a lookup map from weight -> Cylinder (for edit/delete actions)
        final cylinders = cylindersAsync.value ?? [];
        final cylinderByWeight = {
          for (final c in cylinders) c.weight: c,
        };

        // Use settings weights as source of truth; supplement with any cylinder weights not in settings
        final allWeights = {
          ...weightsFromSettings,
          ...cylinders.map((c) => c.weight),
        }.toList()..sort();

        if (allWeights.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun type de bouteille configuré',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez un type de bouteille pour commencer',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header du tableau
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'FORMAT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'DÉTAIL',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'GROS',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'ACHAT',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Column(
              children: List.generate(allWeights.length, (index) {
                final weight = allWeights[index];
                final cylinder = cylinderByWeight[weight]; // may be null on new device

                // Priorité aux réglages (Settings), fallback sur l'entité Cylinder
                final retailPrice =
                    settings?.getRetailPrice(weight) ??
                    cylinder?.sellPrice ?? 0.0;
                final wholesalePrice =
                    settings?.getWholesalePrice(weight) ??
                    cylinder?.sellPrice ?? 0.0;
                final purchasePrice =
                    settings?.getPurchasePrice(weight) ??
                    cylinder?.buyPrice ?? 0.0;

                return Column(
                  children: [
                    if (index > 0)
                      Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: index % 2 == 0
                            ? Colors.transparent
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.propane_tank_outlined,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$weight kg',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              CurrencyFormatter.formatDouble(retailPrice),
                              textAlign: TextAlign.right,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              CurrencyFormatter.formatDouble(
                                wholesalePrice,
                              ),
                              textAlign: TextAlign.right,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              CurrencyFormatter.formatDouble(purchasePrice),
                              textAlign: TextAlign.right,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 32,
                            // Only show edit/delete if cylinder object is available
                            child: cylinder != null
                                ? PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    padding: EdgeInsets.zero,
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              CylinderFormDialog(
                                                cylinder: cylinder,
                                                enterpriseId: enterpriseId,
                                                moduleId: moduleId,
                                              ),
                                        );
                                      } else if (value == 'delete') {
                                        _deleteCylinder(context, ref, cylinder);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) =>
                                        <PopupMenuEntry<String>>[
                                          const PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 12),
                                                Text('Modifier'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Supprimer',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        );
      },
      loading: () => AppShimmers.table(context, rows: 3),
      error: (e, _) => Center(child: Text('Erreur réglages: $e')),
    );
  }
}

