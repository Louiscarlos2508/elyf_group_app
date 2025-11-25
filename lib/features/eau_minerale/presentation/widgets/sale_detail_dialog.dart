import 'package:flutter/material.dart';

import '../../domain/entities/sale.dart';
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
}

