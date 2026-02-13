import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/sale.dart';
import 'package:elyf_groupe_app/shared.dart';

class SalesTable extends StatelessWidget {
  const SalesTable({
    super.key,
    required this.sales,
    required this.formatCurrency,
    required this.onActionTap,
  });

  final List<Sale> sales;
  final String Function(int) formatCurrency;
  final void Function(Sale, String) onActionTap;

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Aucune vente enregistrée'),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('N° Facture')),
          DataColumn(label: Text('Date & Heure')),
          DataColumn(label: Text('Client')),
          DataColumn(label: Text('Montant')),
          DataColumn(label: Text('Méthode')),
          DataColumn(label: Text('Actions')),
        ],
        rows: sales.map((sale) {
          final isDeleted = sale.isDeleted;
          return DataRow(
            cells: [
              DataCell(
                Text(
                  sale.number ?? '#${sale.id.substring(0, 8)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isDeleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              DataCell(
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(sale.date),
                  style: isDeleted ? const TextStyle(color: Colors.grey) : null,
                ),
              ),
              DataCell(
                Text(
                  sale.customerName ?? '-',
                  style: isDeleted ? const TextStyle(color: Colors.grey) : null,
                ),
              ),
              DataCell(
                Text(
                  formatCurrency(sale.totalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDeleted ? Colors.grey : Colors.green[700],
                  ),
                ),
              ),
              DataCell(
                Text(
                  sale.paymentMethod?.name ?? 'cash',
                  style: isDeleted ? const TextStyle(color: Colors.grey) : null,
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrintReceiptButton(sale: sale, iconOnly: true),
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                      onPressed: () => onActionTap(sale, 'view'),
                      tooltip: 'Détails',
                      color: Colors.grey[700],
                    ),
                    if (!isDeleted)
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, size: 20),
                        onPressed: () => onActionTap(sale, 'delete'),
                        tooltip: 'Annuler la vente',
                        color: Colors.red,
                      ),
                    if (isDeleted)
                       const Text(
                        'ANNULÉE',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
