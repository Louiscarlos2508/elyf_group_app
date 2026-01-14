import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/credit_payment.dart';
import '../../domain/entities/sale.dart';

/// Dialog showing credit history for a customer.
class CreditHistoryDialog extends ConsumerWidget {
  const CreditHistoryDialog({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  final String customerId;
  final String customerName;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final creditRepo = ref.read(creditRepositoryProvider);

    return FutureBuilder<List<Sale>>(
      future: creditRepo.fetchCustomerCredits(customerId),
      builder: (context, salesSnapshot) {
        if (salesSnapshot.connectionState == ConnectionState.waiting) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (salesSnapshot.hasError) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text('Erreur', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    salesSnapshot.error.toString(),
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ),
          );
        }

        final creditSales =
            salesSnapshot.data?.where((s) => s.isCredit).toList() ?? [];

        return FutureBuilder<Map<String, List<CreditPayment>>>(
          future: Future.wait(
            creditSales.map((sale) async {
              final payments = await creditRepo.fetchSalePayments(sale.id);
              return MapEntry(sale.id, payments);
            }),
          ).then((maps) => Map.fromEntries(maps)),
          builder: (context, paymentsSnapshot) {
            final paymentsMap = paymentsSnapshot.data ?? {};

            return _buildDialogContent(
              context,
              theme,
              creditSales,
              paymentsMap,
              paymentsSnapshot.connectionState == ConnectionState.waiting,
            );
          },
        );
      },
    );
  }

  Widget _buildDialogContent(
    BuildContext context,
    ThemeData theme,
    List<Sale> creditSales,
    Map<String, List<CreditPayment>> paymentsMap,
    bool isLoadingPayments,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.1,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.history,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Historique des Crédits',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customerName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (creditSales.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              Icon(
                                Icons.credit_card_off,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun crédit en cours',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      Text(
                        'Ventes en Crédit (${creditSales.length})',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...creditSales.map((sale) {
                        final payments = paymentsMap[sale.id] ?? [];
                        final totalPaid = payments.fold<int>(
                          0,
                          (sum, p) => sum + p.amount,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Sale header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.shopping_cart,
                                        size: 20,
                                        color: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sale.productName,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_formatDate(sale.date)} • ${sale.quantity} unités',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          CurrencyFormatter.formatFCFA(
                                            sale.totalPrice,
                                          ),
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          'Total',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Payment summary
                              Container(
                                padding: const EdgeInsets.all(16),
                                color: theme.colorScheme.surface,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      theme,
                                      'Payé',
                                      CurrencyFormatter.formatFCFA(totalPaid),
                                      Colors.green,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.2),
                                    ),
                                    _buildStatItem(
                                      theme,
                                      'Restant',
                                      CurrencyFormatter.formatFCFA(
                                        sale.remainingAmount,
                                      ),
                                      theme.colorScheme.error,
                                    ),
                                  ],
                                ),
                              ),
                              // Payments list
                              if (payments.isNotEmpty) ...[
                                Divider(
                                  height: 1,
                                  color: theme.colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Paiements (${payments.length})',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...payments.map((payment) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                size: 20,
                                                color: Colors.green,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      CurrencyFormatter.formatFCFA(
                                                        payment.amount,
                                                      ),
                                                      style: theme
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                    if (payment.notes !=
                                                        null) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        payment.notes!,
                                                        style: theme
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                _formatDate(payment.date),
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ] else if (!isLoadingPayments)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Aucun paiement enregistré',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Fermer'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
