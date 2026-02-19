import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/tenant/tenant_provider.dart';
import '../../application/providers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/services/gaz_report_calculation_service.dart';
import 'financial_summary_card.dart';
import 'package:elyf_groupe_app/shared.dart';

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
    // Récupérer l'entreprise active depuis le contexte
    final activeEnterpriseIdAsync = ref.watch(activeEnterpriseIdProvider);
    final enterpriseId = activeEnterpriseIdAsync.when(
      data: (id) => id ?? 'default_enterprise',
      loading: () => 'default_enterprise',
      error: (_, __) => 'default_enterprise',
    );

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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  _buildHeadquartersPayment(context, ref, theme, netAmount, enterpriseId),
                  const SizedBox(height: 24),
                  // Analyse des ventes par type
                  salesAsync.when(
                    data: (sales) {
                      // Utiliser le service de calcul pour extraire la logique métier
                      final reportService = ref.read(
                        gazReportCalculationServiceProvider,
                      );
                      final salesAnalysis = reportService
                          .calculateSalesAnalysis(
                            sales: sales,
                            startDate: startDate,
                            endDate: endDate,
                          );
                      return _buildSalesAnalysis(theme, salesAnalysis);
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
    })
    charges,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _buildChargeRow(
            theme,
            'Charges fixes',
            charges.fixedCharges,
            const Color(0xFF3B82F6), // Blue
          ),
          const Divider(),
          _buildChargeRow(
            theme,
            'Charges variables',
            charges.variableCharges,
            const Color(0xFFF59E0B), // Amber
          ),
          const Divider(),
          _buildChargeRow(theme, 'Salaires', charges.salaries, const Color(0xFF8B5CF6)), // Violet
          const Divider(),
          _buildChargeRow(
            theme,
            'Frais de chargement',
            charges.loadingEventExpenses,
            const Color(0xFF14B8A6), // Teal
          ),
          const Divider(),
          _buildChargeRow(
            theme,
            'Total charges',
            charges.totalExpenses,
            theme.colorScheme.error,
            isBold: true,
          ),
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
    WidgetRef ref,
    ThemeData theme,
    double netAmount,
    String enterpriseId,
  ) {
    final canTransfer = netAmount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (canTransfer ? AppColors.success : theme.colorScheme.error)
            .withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (canTransfer ? AppColors.success : theme.colorScheme.error)
              .withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                canTransfer ? Icons.check_circle : Icons.error_outline,
                color: canTransfer ? AppColors.success : theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  canTransfer
                      ? 'Reliquat disponible pour versement'
                      : 'Déficit - Pas de versement possible',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: canTransfer ? AppColors.success : theme.colorScheme.error,
                  ),
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
              color: canTransfer ? AppColors.success : theme.colorScheme.error,
            ),
          ),
          if (canTransfer) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showTransferDialog(context, ref, netAmount, enterpriseId),
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Préparer versement siège'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalesAnalysis(ThemeData theme, SalesAnalysis analysis) {
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
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              _buildSalesTypeRow(
                theme,
                'Ventes au Détail',
                analysis.retailSales.length,
                analysis.retailTotal,
                const Color(0xFFF59E0B), // Amber
              ),
              const Divider(),
              _buildSalesTypeRow(
                theme,
                'Ventes en Gros',
                analysis.wholesaleSales.length,
                analysis.wholesaleTotal,
                const Color(0xFF8B5CF6), // Violet
              ),
            ],
          ),
        ),
        // Détail des ventes en gros par tour
        if (analysis.wholesaleByTour.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Ventes en Gros par Tour',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...analysis.wholesaleByTour.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
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
                        color: const Color(0xFF8B5CF6), // Violet
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key == 'Sans tour'
                            ? 'Sans tour associé'
                            : 'Tour ${entry.key.substring(0, 8)}...',
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
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

  /// Affiche un dialog pour confirmer et enregistrer le versement au siège.
  Future<void> _showTransferDialog(
    BuildContext context,
    WidgetRef ref,
    double amount,
    String enterpriseId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Versement au siège'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montant à verser:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.formatDouble(amount),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cette action va créer une dépense pour enregistrer le versement.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Créer une dépense pour enregistrer le versement
      final expense = GazExpense(
        id: 'transfer-${DateTime.now().millisecondsSinceEpoch}',
        category: ExpenseCategory.other,
        amount: amount,
        description: 'Versement au siège - Reliquat net',
        date: DateTime.now(),
        enterpriseId: enterpriseId,
        isFixed: false,
        notes: 'Versement automatique depuis le rapport financier - Période: ${startDate.day}/${startDate.month}/${startDate.year} au ${endDate.day}/${endDate.month}/${endDate.year}',
      );

      try {
        final expenseController = ref.read(expenseControllerProvider);
        await expenseController.addExpense(expense);

        // Invalider les providers pour rafraîchir
        ref.invalidate(gazExpensesProvider);
        ref.invalidate(
          financialChargesProvider((
            enterpriseId: enterpriseId,
            startDate: startDate,
            endDate: endDate,
          )),
        );
        ref.invalidate(
          financialNetAmountProvider((
            enterpriseId: enterpriseId,
            startDate: startDate,
            endDate: endDate,
            totalRevenue: totalRevenue,
          )),
        );

        if (context.mounted) {
          NotificationService.showSuccess(
            context,
            'Versement enregistré avec succès',
          );
        }
      } catch (e) {
        if (context.mounted) {
          NotificationService.showError(
            context,
            'Erreur lors de l\'enregistrement du versement: $e',
          );
        }
      }
    }
  }
}
