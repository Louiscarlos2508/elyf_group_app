import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/gaz_settings.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final settingsAsync = ref.watch(
      gazSettingsProvider(
        (enterpriseId: enterpriseId, moduleId: moduleId),
      ),
    );

    return settingsAsync.when(
      data: (settings) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colors.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const WholesalePriceHeader(),
                const SizedBox(height: 24),
                // Liste des prix par poids
                ...CylinderWeight.availableWeights.map((weight) {
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
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
