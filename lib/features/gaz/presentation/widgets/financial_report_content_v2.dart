import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/financial_report_controller.dart';
import '../../application/providers.dart';
import '../../domain/services/financial_calculation_service.dart';
import 'financial_summary_card.dart';
import '../../../../shared/utils/currency_formatter.dart';

/// Contenu de rapport financier avec charges fixes/variables et reliquat siège.
class GazFinancialReportContentV2 extends ConsumerWidget {
  const GazFinancialReportContentV2({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
  });

  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    String enterpriseId = 'default_enterprise'; // TODO: depuis contexte

    // Calculer les charges
    final chargesFuture = ref.watch(
      financialChargesProvider((
        enterpriseId: enterpriseId,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    // Calculer le reliquat net
    final netAmountFuture = ref.watch(
      financialNetAmountProvider((
        enterpriseId: enterpriseId,
        startDate: startDate,
        endDate: endDate,
        totalRevenue: totalRevenue,
      )),
    );

    final isWide = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.all(isWide ? 24 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: chargesFuture.when(
        data: (charges) {
          return netAmountFuture.when(
            data: (netAmount) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rapport Financier Détaillé',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FinancialSummaryCard(
                    totalRevenue: totalRevenue,
                    totalExpenses: charges.totalExpenses,
                    netAmount: netAmount,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Détail des Charges',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildChargesSection(theme, charges),
                  const SizedBox(height: 24),
                  Text(
                    'Versement Siège',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHeadquartersPayment(context, theme, netAmount),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur calcul reliquat: $e'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erreur calcul charges: $e'),
      ),
    );
  }

  Widget _buildChargesSection(
    ThemeData theme,
    ({
      double fixedCharges,
      double variableCharges,
      double salaries,
      double loadingEventExpenses,
      double totalExpenses,
    }) charges,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildChargeRow(theme, 'Charges fixes', charges.fixedCharges, Colors.blue),
          const Divider(),
          _buildChargeRow(theme, 'Charges variables', charges.variableCharges, Colors.orange),
          const Divider(),
          _buildChargeRow(theme, 'Salaires', charges.salaries, Colors.purple),
          const Divider(),
          _buildChargeRow(theme, 'Frais de chargement', charges.loadingEventExpenses, Colors.amber),
          const Divider(),
          _buildChargeRow(theme, 'Total charges', charges.totalExpenses, Colors.red, isBold: true),
        ],
      ),
    );
  }

  Widget _buildChargeRow(
    ThemeData theme,
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            CurrencyFormatter.formatDouble(amount),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadquartersPayment(
    BuildContext context,
    ThemeData theme,
    double netAmount,
  ) {
    final canTransfer = netAmount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: canTransfer
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canTransfer ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                canTransfer ? Icons.check_circle : Icons.error,
                color: canTransfer ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                canTransfer
                    ? 'Reliquat disponible pour versement'
                    : 'Déficit - Pas de versement possible',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: canTransfer ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Montant net à transférer au siège:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatDouble(netAmount),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: canTransfer ? Colors.green : Colors.red,
            ),
          ),
          if (canTransfer) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  // TODO: Implémenter action de versement
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonctionnalité de versement à implémenter'),
                    ),
                  );
                },
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Préparer versement siège'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}