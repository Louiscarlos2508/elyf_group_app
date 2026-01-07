import 'package:flutter/material.dart';

import '../../domain/entities/sale.dart';
import 'invoice_print/invoice_print_button.dart';
import 'sale_detail_helpers.dart';

/// Dialog showing sale details.
class SaleDetailDialog extends StatelessWidget {
  const SaleDetailDialog({
    super.key,
    required this.sale,
  });

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Détails de la Vente',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    EauMineralePrintButton(sale: sale, compact: true),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SaleDetailRow(
                  label: 'Produit',
                  value: sale.productName,
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 16),
                SaleDetailRow(
                  label: 'Client',
                  value: sale.customerName,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                SaleDetailRow(
                  label: 'Téléphone',
                  value: sale.customerPhone,
                  icon: Icons.phone,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SaleDetailRow(
                        label: 'Quantité',
                        value: '${sale.quantity}',
                        icon: Icons.numbers,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SaleDetailRow(
                        label: 'Prix unitaire',
                        value: SaleDetailHelpers.formatCurrency(sale.unitPrice),
                        icon: Icons.attach_money,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SaleDetailRow(
                        label: 'Total',
                        value: SaleDetailHelpers.formatCurrency(sale.totalPrice),
                        icon: Icons.receipt,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SaleDetailRow(
                        label: 'Montant payé',
                        value: SaleDetailHelpers.formatCurrency(sale.amountPaid),
                        icon: Icons.payment,
                      ),
                    ),
                  ],
                ),
                // Affichage de la répartition des paiements
                if (sale.cashAmount > 0 || sale.orangeMoneyAmount > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Répartition du paiement',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (sale.cashAmount > 0)
                          _buildPaymentRow(
                            'Cash',
                            sale.cashAmount,
                            Icons.money,
                            theme.colorScheme.primary,
                            theme,
                          ),
                        if (sale.cashAmount > 0 && sale.orangeMoneyAmount > 0)
                          const SizedBox(height: 8),
                        if (sale.orangeMoneyAmount > 0)
                          _buildPaymentRow(
                            'Orange Money',
                            sale.orangeMoneyAmount,
                            Icons.account_balance_wallet,
                            theme.colorScheme.secondary,
                            theme,
                          ),
                      ],
                    ),
                  ),
                ],
                if (sale.remainingAmount > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Crédit restant: ${SaleDetailHelpers.formatCurrency(sale.remainingAmount)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SaleDetailRow(
                        label: 'Date',
                        value: SaleDetailHelpers.formatDate(sale.date),
                        icon: Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statut',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: SaleDetailHelpers.getStatusColor(sale.status, context)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              SaleDetailHelpers.getStatusLabel(sale.status),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: SaleDetailHelpers.getStatusColor(sale.status, context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SaleDetailRow(
                    label: 'Notes',
                    value: sale.notes!,
                    icon: Icons.note,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRow(
    String label,
    int amount,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        Text(
          SaleDetailHelpers.formatCurrency(amount),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

