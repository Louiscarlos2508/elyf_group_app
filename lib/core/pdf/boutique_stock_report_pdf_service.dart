import '../../features/boutique/domain/entities/product.dart';
import 'base_stock_report_pdf_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';

/// Service pour générer le rapport de stock du module Boutique.
class BoutiqueStockReportPdfService extends BaseStockReportPdfService {
  /// Génère un rapport de stock pour le module Boutique.
  Future<File> generateReport({
    required List<Product> products,
    DateTime? reportDate,
  }) async {
    final date = reportDate ?? DateTime.now();
    final stockData = products.map((product) {
      return StockItemData(
        name: product.name,
        quantity: product.stock.toDouble(),
        unit: 'unité',
        updatedAt: DateTime.now(), // Les produits n'ont pas de updatedAt
      );
    }).toList();

    return generateStockReportPdf(
      moduleName: 'Boutique',
      reportDate: date,
      stockItems: stockData,
      fileName: 'rapport_stock_boutique_'
          '${DateFormat('yyyyMMdd').format(date)}.pdf',
    );
  }
}

