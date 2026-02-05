import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import 'wholesale_price/wholesale_price_header.dart';
import 'wholesale_price/wholesale_price_row.dart';

/// Carte de configuration des prix en gros dans les paramètres.
class WholesalePriceConfigCard extends ConsumerWidget {
  const WholesalePriceConfigCard({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  /// Récupère les poids disponibles depuis les bouteilles créées.
  List<int> _getAvailableWeights(WidgetRef ref) {
    final cylindersAsync = ref.watch(cylindersProvider);
    return cylindersAsync.when(
      data: (cylinders) {
        // Extraire les poids uniques des bouteilles existantes
        final weights = cylinders.map((c) => c.weight).toSet().toList();
        weights.sort();
        return weights;
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final availableWeights = _getAvailableWeights(ref);
    final settingsAsync = ref.watch(
      gazSettingsProvider((enterpriseId: enterpriseId, moduleId: moduleId)),
    );

    return settingsAsync.when(
      data: (settings) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
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
            child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const WholesalePriceHeader(),
                const SizedBox(height: 24),
                // Liste des prix par poids (basée sur les bouteilles créées)
                if (availableWeights.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 48,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune bouteille créée',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Créez d\'abord des types de bouteilles dans la section "Configuration des prix"',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...availableWeights.map((weight) {
                    final price = settings?.getWholesalePrice(weight) ?? 0.0;
                    return WholesalePriceRow(
                      weight: weight,
                      price: price,
                      settings: settings,
                      enterpriseId: enterpriseId,
                      moduleId: moduleId,
                      onPriceSaved: () {
                        // Le provider sera invalidé dans le widget
                      },
                    );
                  }),
              ],
            ),
          ),
        ),
      );
    },
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Erreur lors du chargement des paramètres',
                style: theme.textTheme.bodyLarge?.copyWith(color: colors.error),
              ),
              const SizedBox(height: 8),
              Text(error.toString(), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
