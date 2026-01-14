import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Classe pour représenter les données de stock dans le rapport.
class StockItemData {
  const StockItemData({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.updatedAt,
  });

  final String name;
  final double quantity;
  final String unit;
  final DateTime updatedAt;
}

/// Widget pour afficher un tableau des stocks.
class StockReportTable extends StatelessWidget {
  const StockReportTable({super.key, required this.stockData});

  final List<StockItemData> stockData;

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (stockData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Aucun stock trouvé')),
        ),
      );
    }

    final sortedData = List<StockItemData>.from(stockData)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Détail du stock',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Article')),
                DataColumn(label: Text('Quantité'), numeric: true),
                DataColumn(label: Text('Unité')),
                DataColumn(label: Text('Dernière mise à jour')),
              ],
              rows: sortedData.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.name)),
                    DataCell(
                      Text(
                        item.quantity.toStringAsFixed(0),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text(item.unit)),
                    DataCell(Text(_formatDate(item.updatedAt))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
