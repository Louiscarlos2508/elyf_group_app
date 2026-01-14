import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/entities/point_of_sale.dart';
import 'pos_associate_cylinders_dialog.dart';

/// Dialog pour afficher et gérer les types de bouteilles d'un point de vente.
class PosTypesDialog extends ConsumerWidget {
  const PosTypesDialog({
    super.key,
    required this.pointOfSale,
    required this.enterpriseId,
    required this.moduleId,
  });

  final PointOfSale pointOfSale;
  final String enterpriseId;
  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupérer uniquement les types de bouteilles pour ce point de vente
    final cylindersAsync = ref.watch(
      pointOfSaleCylindersProvider((
        pointOfSaleId: pointOfSale.id,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
      )),
    );
    final settingsAsync = ref.watch(
      gazSettingsProvider((enterpriseId: enterpriseId, moduleId: moduleId)),
    );

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: cylindersAsync.when(
          data: (cylinders) => settingsAsync.when(
            data: (settings) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Types - ${pointOfSale.name}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (cylinders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun type de bouteille',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Associez des types de bouteilles à ce point de vente',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      itemCount: cylinders.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final cylinder = cylinders[index];
                        final wholesalePrice = settings?.getWholesalePrice(
                          cylinder.weight,
                        );
                        return ListTile(
                          leading: const Icon(Icons.inventory_2),
                          title: Text('${cylinder.weight}kg'),
                          subtitle: Text(
                            wholesalePrice != null && wholesalePrice > 0
                                ? 'Détail: ${cylinder.sellPrice.toStringAsFixed(0)} FCFA | '
                                      'Gros: ${wholesalePrice.toStringAsFixed(0)} FCFA'
                                : 'Prix détail: ${cylinder.sellPrice.toStringAsFixed(0)} FCFA',
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await showDialog(
                      context: context,
                      builder: (dialogContext) => PosAssociateCylindersDialog(
                        pointOfSale: pointOfSale,
                        enterpriseId: enterpriseId,
                        moduleId: moduleId,
                        dialogContext: dialogContext,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Associer des types'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            loading: () => _buildLoadingState(context),
            error: (_, __) => _buildErrorState(context),
          ),
          loading: () => _buildLoadingState(context),
          error: (_, __) => _buildErrorState(context),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Types - ${pointOfSale.name}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Types - ${pointOfSale.name}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Erreur lors du chargement',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}
