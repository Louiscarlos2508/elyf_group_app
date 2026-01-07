import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/financial_report_controller.dart';
import '../../application/providers.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/services/financial_calculation_service.dart';
import 'financial_summary_card.dart';
import '../../../../shared.dart';

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

    // Récupérer les ventes pour analyse
    final salesAsync = ref.watch(gasSalesProvider);

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
                  const SizedBox(height: 24),
                  // Analyse des ventes par type
                  salesAsync.when(
                    data: (sales) {
                      final filteredSales = sales.where((s) {
                        return s.saleDate
                                .isAfter(startDate.subtract(const Duration(days: 1))) &&
                            s.saleDate.isBefore(endDate.add(const Duration(days: 1)));
                      }).toList();
                      return _buildSalesAnalysis(theme, filteredSales);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
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
                  NotificationService.showInfo(context, 'Fonctionnalité de versement à implémenter');
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

  Widget _buildSalesAnalysis(ThemeData theme, List<GasSale> sales) {
    // Séparer les ventes par type
    final retailSales = sales.where((s) => s.saleType == SaleType.retail).toList();
    final wholesaleSales = sales.where((s) => s.saleType == SaleType.wholesale).toList();

    // Calculer les totaux
    final retailTotal = retailSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final wholesaleTotal = wholesaleSales.fold<double>(0, (sum, s) => sum + s.totalAmount);

    // Grouper les ventes en gros par tour
    final wholesaleByTour = <String, ({int count, double total})>{};
    for (final sale in wholesaleSales) {
      final tourId = sale.tourId ?? 'Sans tour';
      if (!wholesaleByTour.containsKey(tourId)) {
        wholesaleByTour[tourId] = (count: 0, total: 0.0);
      }
      final current = wholesaleByTour[tourId]!;
      wholesaleByTour[tourId] = (
        count: current.count + 1,
        total: current.total + sale.totalAmount,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyse des Ventes',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Répartition par type
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSalesTypeRow(
                theme,
                'Ventes au Détail',
                retailSales.length,
                retailTotal,
                Colors.orange,
              ),
              const Divider(),
              _buildSalesTypeRow(
                theme,
                'Ventes en Gros',
                wholesaleSales.length,
                wholesaleTotal,
                Colors.purple,
              ),
            ],
          ),
        ),
        // Détail des ventes en gros par tour
        if (wholesaleByTour.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Ventes en Gros par Tour',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...wholesaleByTour.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 16,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key == 'Sans tour' ? 'Sans tour associé' : 'Tour ${entry.key.substring(0, 8)}...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatDouble(entry.value.total),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${entry.value.count} vente${entry.value.count > 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSalesTypeRow(
    ThemeData theme,
    String label,
    int count,
    double total,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatDouble(total),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '$count vente${count > 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}