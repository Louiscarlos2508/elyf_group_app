import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../domain/entities/sale.dart';

class SaleDetailDialog extends StatelessWidget {
  const SaleDetailDialog({super.key, required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Détails de la Vente ${sale.number ?? ""}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID Local', sale.id.substring(0, 8)),
            _buildDetailRow('Date', '${sale.date.day.toString().padLeft(2, '0')}/${sale.date.month.toString().padLeft(2, '0')}/${sale.date.year} ${sale.date.hour}:${sale.date.minute.toString().padLeft(2, '0')}'),
            _buildDetailRow('Paiement', sale.paymentMethod?.name ?? 'cash'),
            if (sale.customerName != null) _buildDetailRow('Client', sale.customerName!),
            const Divider(height: 24),
            const Text('Articles:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...sale.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(child: Text('${item.quantity}x ${item.productName}', overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text(CurrencyFormatter.formatFCFA(item.totalPrice)),
                ],
              ),
            )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  CurrencyFormatter.formatFCFA(sale.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (sale.isDeleted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CETTE VENTE A ÉTÉ ANNULÉE',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!sale.isDeleted)
           PrintReceiptButton(sale: sale),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
