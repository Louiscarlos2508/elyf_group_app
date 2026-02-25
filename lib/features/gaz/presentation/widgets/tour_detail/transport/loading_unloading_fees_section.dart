import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../../../shared/utils/currency_formatter.dart';
import '../../../../domain/entities/tour.dart';

/// Section des frais de chargement et déchargement.
class LoadingUnloadingFeesSection extends StatelessWidget {
  const LoadingUnloadingFeesSection({super.key, required this.tour});

  final Tour tour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final containerColor = isDark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frais de chargement
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Frais de chargement',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (!tour.applyLoadingFees)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'OFF',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (tour.emptyBottlesLoaded.values.any((v) => v > 0)) ...[
                const SizedBox(height: 8),
                ...tour.emptyBottlesLoaded.entries.where((e) => e.value > 0).map((e) {
                  final weight = e.key;
                  final qty = e.value;
                  final fee = tour.loadingFees[weight] ?? tour.loadingFeePerBottle;
                  return Opacity(
                    opacity: tour.applyLoadingFees ? 1.0 : 0.5,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$weight kg ($qty btl × ${fee.toInt()} F)', style: theme.textTheme.bodySmall),
                          Text('${qty * fee > 0 ? CurrencyFormatter.formatDouble(qty * fee) : "0"} F', 
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatDouble(tour.totalLoadingFees),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: tour.applyLoadingFees ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w900,
                      decoration: tour.applyLoadingFees ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Frais de déchargement
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Frais de déchargement',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (tour.fullBottlesReceived.values.any((v) => v > 0)) ...[
                const SizedBox(height: 8),
                ...tour.fullBottlesReceived.entries.where((e) => e.value > 0).map((e) {
                  final weight = e.key;
                  final qty = e.value;
                  final fee = tour.unloadingFees[weight] ?? tour.unloadingFeePerBottle;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$weight kg ($qty btl × ${fee.toInt()} F)', style: theme.textTheme.bodySmall),
                        Text('${qty * fee > 0 ? CurrencyFormatter.formatDouble(qty * fee) : "0"} F', 
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
              ],
              if (tour.fixedUnloadingFee > 0) ...[
                 Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Frais fixe déchargement', style: theme.textTheme.bodySmall),
                        Text('${CurrencyFormatter.formatDouble(tour.fixedUnloadingFee)} F', 
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatDouble(tour.totalUnloadingFees),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Divider
        Divider(height: 1, color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 16),
        // Total chargement/déchargement
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Manutention',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                CurrencyFormatter.formatDouble(
                  tour.totalLoadingFees + tour.totalUnloadingFees,
                ),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
