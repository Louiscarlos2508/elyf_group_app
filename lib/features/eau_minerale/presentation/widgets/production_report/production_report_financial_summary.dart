import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/production_session.dart';
import 'production_report_components.dart';
import 'production_report_helpers.dart';

/// Résumé financier du rapport.
class ProductionReportFinancialSummary extends ConsumerWidget {
  const ProductionReportFinancialSummary({
    super.key,
    required this.session,
    required this.linkedExpenses,
  });

  final ProductionSession session;
  final List<ExpenseRecord> linkedExpenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final electricityRate = ref.watch(electricityRateProvider).value;

    final coutPersonnel = session.coutTotalPersonnel;
    final coutBobines = session.coutBobines ?? 0;
    
    // Calculate electricity cost: preference for saved cost, fallback to rate * consumption
    int coutElectricite = session.coutElectricite ?? 0;
    if (coutElectricite == 0 && electricityRate != null && session.consommationCourant > 0) {
      coutElectricite = (session.consommationCourant * electricityRate).round();
    }

    final coutDepenses = linkedExpenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amountCfa,
    );
    
    // Total production cost (base session + dynamic electricity + linked expenses)
    // Note: session.coutTotal already includes session.coutElectricite if it was saved
    // So we calculate manually to be safe with the dynamic fallback
    final sessionBaseCosts = (session.coutBobines ?? 0) + (session.coutEmballages ?? 0) + session.coutTotalPersonnel;
    final coutTotal = sessionBaseCosts + coutElectricite + coutDepenses;
    
    // Calculer les revenus estimés basés sur la quantité produite et le prix moyen des ventes
    final revenusEstimes = _calculateEstimatedRevenue(ref, session);
    final marge = revenusEstimes - coutTotal;
    final margePourcentage = revenusEstimes > 0
        ? (marge / revenusEstimes * 100)
        : 0.0;
    
    // Unit cost price (prix de revient)
    final totalUnits = session.quantiteProduite > 0 ? session.quantiteProduite : 1;
    final prixDeRevient = coutTotal / totalUnits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductionReportComponents.buildSectionTitle('Résumé Financier', theme),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coûts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ProductionReportComponents.buildCostRow(
                label: 'Personnel',
                amount: coutPersonnel,
                formatCurrency: ProductionReportHelpers.formatCurrency,
                theme: theme,
              ),
              ProductionReportComponents.buildCostRow(
                label: 'Bobines',
                amount: coutBobines,
                formatCurrency: ProductionReportHelpers.formatCurrency,
                theme: theme,
              ),
              ProductionReportComponents.buildCostRow(
                label: 'Emballages',
                amount: session.coutEmballages ?? 0,
                formatCurrency: ProductionReportHelpers.formatCurrency,
                theme: theme,
              ),
              ProductionReportComponents.buildCostRow(
                label: 'Électricité',
                amount: coutElectricite,
                formatCurrency: ProductionReportHelpers.formatCurrency,
                theme: theme,
              ),
              if (coutDepenses > 0)
                ProductionReportComponents.buildCostRow(
                  label: 'Dépenses liées',
                  amount: coutDepenses,
                  formatCurrency: ProductionReportHelpers.formatCurrency,
                  theme: theme,
                ),
              const Divider(),
              ProductionReportComponents.buildCostRow(
                label: 'Total des coûts',
                amount: coutTotal,
                formatCurrency: ProductionReportHelpers.formatCurrency,
                theme: theme,
                isTotal: true,
              ),
              const SizedBox(height: 8),
              _buildUnitPriceRow(
                context,
                'Prix de revient',
                '${prixDeRevient.toStringAsFixed(2)} CFA / ${session.quantiteProduiteUnite}',
              ),
              if (revenusEstimes > 0) ...[
                const SizedBox(height: 16),
                Text(
                  'Revenus',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ProductionReportComponents.buildCostRow(
                  label: 'Revenus estimés',
                  amount: revenusEstimes,
                  formatCurrency: ProductionReportHelpers.formatCurrency,
                  theme: theme,
                  isRevenue: true,
                ),
                const Divider(),
                ProductionReportComponents.buildCostRow(
                  label: 'Marge',
                  amount: marge,
                  formatCurrency: ProductionReportHelpers.formatCurrency,
                  theme: theme,
                  isMargin: true,
                  percentage: margePourcentage,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitPriceRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Calcule les revenus estimés basés sur la quantité produite et le prix moyen des ventes.
  int _calculateEstimatedRevenue(WidgetRef ref, ProductionSession session) {
    if (session.quantiteProduite <= 0) {
      return 0;
    }

    try {
      // Récupérer les ventes récentes pour calculer le prix moyen
      final salesAsync = ref.read(salesStateProvider);
      final salesState = salesAsync.value;
      final sales = salesState?.sales ?? [];

      if (sales.isEmpty) {
        // Si aucune vente, utiliser un prix par défaut estimé (ex: 200 CFA par unité)
        // Ce prix peut être ajusté selon les besoins métier
        const defaultUnitPrice = 200;
        return session.quantiteProduite * defaultUnitPrice;
      }

      // Calculer le prix unitaire moyen des ventes récentes
      final totalRevenue = sales.fold<int>(0, (sum, s) => sum + s.totalPrice);
      final totalQuantity = sales.fold<int>(0, (sum, s) => sum + s.quantity);
      
      if (totalQuantity > 0) {
        final averageUnitPrice = (totalRevenue / totalQuantity).round();
        return (session.quantiteProduite * averageUnitPrice).toInt();
      }

      // Fallback: utiliser le prix moyen des ventes individuelles
      final averagePrice = sales.isNotEmpty
          ? (totalRevenue / sales.length).round()
          : 0;
      
      if (averagePrice > 0) {
        // Estimer le prix unitaire en divisant par une quantité moyenne estimée
        const estimatedAverageQuantity = 10; // Quantité moyenne par vente
        final estimatedUnitPrice = (averagePrice / estimatedAverageQuantity).round();
        return (session.quantiteProduite * estimatedUnitPrice).toInt();
      }

      // Dernier fallback: prix par défaut
      const defaultUnitPrice = 200;
      return session.quantiteProduite * defaultUnitPrice;
    } catch (e) {
      // En cas d'erreur, utiliser un prix par défaut
      const defaultUnitPrice = 200;
      return session.quantiteProduite * defaultUnitPrice;
    }
  }
}
