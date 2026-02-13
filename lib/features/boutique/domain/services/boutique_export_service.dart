
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/purchase.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/expense.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/stock_movement.dart';

class BoutiqueExportService {
  BoutiqueExportService();

  Future<File> exportSales(List<Sale> sales) async {
    final header = ['Date', 'Numéro', 'Montant Total', 'Méthode', 'Articles'];
    final rows = sales.map((sale) {
      final items = sale.items.map((i) => '${i.quantity}x ${i.productName}').join('; ');
      return [
        DateFormat('dd/MM/yyyy HH:mm').format(sale.date),
        sale.number ?? sale.id,
        sale.totalAmount.toString(),
        sale.paymentMethod?.name ?? 'Non spécifié',
        items,
      ];
    }).toList();

    return _generateCsvFile('ventes_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv', header, rows);
  }

  Future<File> exportPurchases(List<Purchase> purchases) async {
    final header = ['Date', 'Numéro', 'Montant Total', 'Fournisseur', 'Payé', 'Dette', 'Articles'];
    final rows = purchases.map((purchase) {
      final items = purchase.items.map((i) => '${i.quantity}x ${i.productName}').join('; ');
      return [
        DateFormat('dd/MM/yyyy HH:mm').format(purchase.date),
        purchase.number ?? purchase.id,
        purchase.totalAmount.toString(),
        purchase.supplierId ?? '-',
        purchase.paidAmount?.toString() ?? '0',
        purchase.debtAmount?.toString() ?? '0',
        items,
      ];
    }).toList();

    return _generateCsvFile('achats_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv', header, rows);
  }

  Future<File> exportExpenses(List<Expense> expenses) async {
    final header = ['Date', 'Numéro', 'Libellé', 'Catégorie', 'Montant', 'Méthode'];
    final rows = expenses.map((expense) {
      return [
        DateFormat('dd/MM/yyyy HH:mm').format(expense.date),
        expense.number ?? expense.id,
        expense.label,
        expense.category.name,
        expense.amountCfa.toString(),
        expense.paymentMethod.name,
      ];
    }).toList();

    return _generateCsvFile('depenses_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv', header, rows);
  }

  Future<File> exportStockMovements(List<StockMovement> movements) async {
    final header = ['Date', 'Type', 'Produit', 'Quantité', 'Stock Après', 'Notes'];
    final rows = movements.map((movement) {
      return [
        DateFormat('dd/MM/yyyy HH:mm').format(movement.date),
        movement.type.name,
        movement.productId, // Ideally we want product name, but passing it might be complex here without context
        movement.quantity.toString(),
        movement.balanceAfter.toString(),
        movement.notes ?? '',
      ];
    }).toList();

    return _generateCsvFile('stock_mouvements_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv', header, rows);
  }

  Future<File> _generateCsvFile(String filename, List<String> header, List<List<String>> rows) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');

    final buffer = StringBuffer();
    
    // Add BOM for Excel compatibility (UTF-8)
    buffer.write('\uFEFF');

    // Header
    buffer.writeln(_rowToCsv(header));

    // Rows
    for (final row in rows) {
      buffer.writeln(_rowToCsv(row));
    }

    await file.writeAsString(buffer.toString());
    return file;
  }

  String _rowToCsv(List<String> row) {
    return row.map((field) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }).join(',');
  }
}
