import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/features/gaz/domain/services/gaz_stock_calculation_service.dart';

/// Widget affichant le bilan de conservation du parc bouteilles.
/// Affiché uniquement pour les managers de l'entreprise parente (non-POS).
class BottleConservationCard extends ConsumerWidget {
  const BottleConservationCard({super.key, required this.enterpriseId});

  final String enterpriseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final cylindersAsync = ref.watch(cylindersProvider);
    final allStocksAsync = ref.watch(gazStocksProvider);
    final transfersAsync = ref.watch(stockTransfersProvider(enterpriseId));

    final cylinders = cylindersAsync.value ?? [];
    final allStocks = allStocksAsync.value ?? [];
    final transfers = transfersAsync.value ?? [];

    // Seulement si au moins un cylinder a un parc déclaré
    final tracked = cylinders.where((c) => c.registeredTotal > 0);
    if (tracked.isEmpty) {
      return _NoTrackingBanner(theme: theme);
    }
    final result = GazStockCalculationService.calculateConservation(
      cylinders: cylinders,
      allStocks: allStocks,
      transfers: transfers,
    );

    final hasAlert = result.hasAnyDiscrepancy;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: hasAlert
              ? theme.colorScheme.error.withAlpha(180)
              : theme.colorScheme.outline.withAlpha(60),
          width: hasAlert ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasAlert ? Icons.warning_amber_rounded : Icons.verified_outlined,
                  color: hasAlert
                      ? theme.colorScheme.error
                      : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Conservation du Parc Bouteilles',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasAlert
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (!hasAlert)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Équilibré',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...result.items
                .where((i) => i.isTracked)
                .map((item) => _ConservationRow(item: item, theme: theme)),
            if (!result.isFullyTracked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '⚠ Certains types n\'ont pas de parc déclaré (modifier le type pour l\'ajouter).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoTrackingBanner extends StatelessWidget {
  const _NoTrackingBanner({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Conservation non configurée. Ajoutez un "Parc Total" dans les paramètres de chaque type de bouteille.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConservationRow extends StatelessWidget {
  const _ConservationRow({required this.item, required this.theme});
  final BottleConservationItem item;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final hasLoss = item.discrepancy > 0;
    final hasSurplus = item.discrepancy < 0;
    final color = hasLoss
        ? theme.colorScheme.error
        : hasSurplus
            ? Colors.orange
            : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${item.weight}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.weight}kg — Parc: ${item.registeredTotal} | Comptabilisé: ${item.accounted}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Pleines: ${item.full} • Vides: ${item.empty} • Fuites/Déf: ${item.issues}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (item.hasDiscrepancy)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withAlpha(100)),
                  ),
                  child: Text(
                    hasLoss
                        ? '-${item.discrepancy} perdu'
                        : '+${item.discrepancy.abs()} surplus',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
            ],
          ),
          if (item.hasDiscrepancy) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: item.accounted / item.registeredTotal,
              backgroundColor: color.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ],
      ),
    );
  }
}
