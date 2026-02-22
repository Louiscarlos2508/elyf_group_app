import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/tour.dart';

/// Carte de récapitulatif final d'un tour d'approvisionnement.
///
/// Affiche le résumé des dépenses liées au réapprovisionnement chez le fournisseur.
class TourSummaryCard extends StatelessWidget {
  const TourSummaryCard({super.key, required this.tour});

  final Tour tour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total dépenses
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.1)),
          ),
          color: theme.colorScheme.error.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dépenses totales',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatDouble(tour.totalExpenses),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Récapitulatif détaillé
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Détails du réapprovisionnement',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRow(theme, 'Vides envoyés :', '${tour.totalBottlesToLoad} bouteilles'),
                _buildRow(theme, 'Pleins reçus :', '${tour.totalBottlesReceived} bouteilles'),
                const Divider(height: 24),
                _buildRow(
                  theme,
                  'Frais de transport :',
                  CurrencyFormatter.formatDouble(tour.totalTransportExpenses),
                ),
                _buildRow(
                  theme,
                  'Frais de chargement :',
                  CurrencyFormatter.formatDouble(tour.totalLoadingFees),
                ),
                _buildRow(
                  theme,
                  'Frais de déchargement :',
                  CurrencyFormatter.formatDouble(tour.totalUnloadingFees),
                ),
                if (tour.gasPurchaseCost != null && tour.gasPurchaseCost! > 0)
                  _buildRow(
                    theme,
                    'Achat gaz :',
                    CurrencyFormatter.formatDouble(tour.gasPurchaseCost!),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
