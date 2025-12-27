import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/tour.dart';

/// Carte de récapitulatif final d'un tour.
class TourSummaryCard extends StatelessWidget {
  const TourSummaryCard({
    super.key,
    required this.tour,
  });

  final Tour tour;


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total encaissé
        Card(
          color: Colors.green.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total encaissé',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatDouble(tour.totalCollected),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Total dépenses
        Card(
          color: Colors.red.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total dépenses',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatDouble(tour.totalExpenses),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Bénéfice net
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bénéfice net',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatDouble(tour.netProfit),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tour.netProfit >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Récapitulatif
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Récapitulatif',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bouteilles collectées:'),
                    Text(
                      '${tour.totalBottlesToLoad}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Frais de transport:'),
                    Text(CurrencyFormatter.formatDouble(tour.totalTransportExpenses)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Frais de chargement:'),
                    Text(CurrencyFormatter.formatDouble(tour.totalLoadingFees)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Frais de déchargement:'),
                    Text(CurrencyFormatter.formatDouble(tour.totalUnloadingFees)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

