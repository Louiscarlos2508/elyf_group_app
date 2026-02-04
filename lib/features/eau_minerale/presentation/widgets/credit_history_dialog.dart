import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/credit_payment.dart';
import '../../domain/entities/sale.dart';
import 'invoice_print/invoice_print_button.dart';
import 'invoice_print/invoice_print_service.dart';

/// Dialog showing credit history for a customer.
class CreditHistoryDialog extends ConsumerWidget {
  const CreditHistoryDialog({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  final String customerId;
  final String customerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(customerCreditHistoryProvider(customerId));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 900 : 700,
              maxHeight: isWide ? 850 : 700,
            ),
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
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.history,
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
                Expanded(
                  child: historyAsync.when(
                    data: (historyItems) {
                      if (historyItems.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.credit_card_off,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun historique de crédit',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: historyItems.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = historyItems[index];
                          return _CreditSaleItem(
                            sale: item.sale,
                            payments: item.payments,
                            customerName: customerName,
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Center(
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
                            Text(
                              'Erreur de chargement',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Fermer'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CreditSaleItem extends StatelessWidget {
  const _CreditSaleItem({
    required this.sale,
    required this.payments,
    required this.customerName,
  });

  final Sale sale;
  final List<CreditPayment> payments;
  final String customerName;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate total paid from payments list
    final totalPaid = payments.fold<int>(
      0,
      (sum, p) => sum + p.amount,
    );

    // Initial down payment is difference between total paid amount recorded on sale 
    // and sum of individual payment records.
    final initialPayment = sale.amountPaid - totalPaid;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Sale header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
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
                    color: sale.isFullyPaid 
                        ? Colors.green.withValues(alpha: 0.1)
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    sale.isFullyPaid
                        ? Icons.check_circle_outline
                        : Icons.access_time,
                    size: 20,
                    color: sale.isFullyPaid
                        ? Colors.green
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.productName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(sale.date)} • ${sale.quantity} unités',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                EauMineralePrintButton(sale: sale, compact: true),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatFCFA(sale.totalPrice),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Payment summary statistics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  theme,
                  'Payé',
                  CurrencyFormatter.formatFCFA(sale.amountPaid),
                  Colors.green,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                _buildStatItem(
                  theme,
                  'Restant',
                  CurrencyFormatter.formatFCFA(sale.remainingAmount),
                  sale.remainingAmount > 0 ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          
          // Payments Details List
          if (payments.isNotEmpty || initialPayment > 0) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Historique des versements',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Initial payment (down payment)
                  if (initialPayment > 0)
                    _buildPaymentItem(
                      context,
                      theme,
                      initialPayment,
                      'Acompte initial',
                      sale.date,
                      cashAmount: sale.cashAmount,
                      omAmount: sale.orangeMoneyAmount,
                      onPrint: () => EauMineraleInvoiceService.instance
                          .printCreditPaymentReceipt(
                        customerName: customerName,
                        sale: sale,
                        paymentAmount: initialPayment,
                        remainingAfterPayment:
                            sale.totalPrice - initialPayment,
                      ),
                    ),
                    
                  // Subsequent payments
                  ...payments.map((payment) {
                    return _buildPaymentItem(
                      context,
                      theme,
                      payment.amount,
                      payment.notes ?? 'Versement',
                      payment.date,
                      cashAmount: payment.cashAmount,
                      omAmount: payment.orangeMoneyAmount,
                      onPrint: () => EauMineraleInvoiceService.instance
                          .printCreditPaymentReceipt(
                        customerName: customerName,
                        sale: sale,
                        paymentAmount: payment.amount,
                        remainingAfterPayment: sale.totalPrice - sale.amountPaid, // Just an approximation for the receipt depending on time
                        cashAmount: payment.cashAmount,
                        omAmount: payment.orangeMoneyAmount,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ] else
             Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Aucun versement',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(
    BuildContext context,
    ThemeData theme,
    int amount,
    String label,
    DateTime date, {
    VoidCallback? onPrint,
    int cashAmount = 0,
    int omAmount = 0,
  }) {
    // Determine payment method label
    final List<String> methods = [];
    if (cashAmount > 0) methods.add('Esp: ${CurrencyFormatter.formatCFA(cashAmount)}');
    if (omAmount > 0) methods.add('OM: ${CurrencyFormatter.formatCFA(omAmount)}');
    final methodText = methods.isNotEmpty ? methods.join(' • ') : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        CurrencyFormatter.formatFCFA(amount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _formatDate(date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (methodText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    methodText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onPrint != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.print, size: 18),
              onPressed: onPrint,
              visualDensity: VisualDensity.compact,
              tooltip: 'Imprimer reçu',
            ),
          ],
        ],
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
        const SizedBox(height: 2),
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
