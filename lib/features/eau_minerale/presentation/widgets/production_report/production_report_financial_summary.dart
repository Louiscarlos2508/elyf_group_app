import 'package:flutter/material.dart';

import '../../../domain/entities/expense_record.dart';
import '../../../domain/entities/production_session.dart';
import 'production_report_components.dart';
import 'production_report_helpers.dart';

/// Résumé financier du rapport.
class ProductionReportFinancialSummary extends StatelessWidget {
  const ProductionReportFinancialSummary({
    super.key,
    required this.session,
    required this.linkedExpenses,
  });

  final ProductionSession session;
  final List<ExpenseRecord> linkedExpenses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coutPersonnel = session.coutTotalPersonnel;
    final coutBobines = session.coutBobines ?? 0;
    final coutElectricite = session.coutElectricite ?? 0;
    final coutDepenses = linkedExpenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amountCfa,
    );
    final coutTotal = session.coutTotal + coutDepenses;
    final revenusEstimes = 0; // TODO: Calculer les revenus estimés
    final marge = revenusEstimes - coutTotal;
    final margePourcentage = revenusEstimes > 0
        ? (marge / revenusEstimes * 100)
        : 0.0;

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
}
