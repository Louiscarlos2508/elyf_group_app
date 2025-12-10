import 'dart:io';

import 'package:intl/intl.dart';

import '../../features/eau_minerale/domain/entities/stock_item.dart';
import 'base_stock_report_pdf_service.dart';

/// Service pour générer le rapport de stock du module Eau Minérale.
class EauMineraleStockReportPdfService extends BaseStockReportPdfService {
  /// Génère un rapport de stock pour le module Eau Minérale.
  Future<File> generateReport({
    required List<StockItem> stockItems,
    DateTime? reportDate,
  }) async {
    final date = reportDate ?? DateTime.now();
    final stockData = stockItems.map((item) {
      return StockItemData(
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        updatedAt: item.updatedAt,
      );
    }).toList();

    return generateStockReportPdf(
      moduleName: 'Eau Minérale',
      reportDate: date,
      stockItems: stockData,
      fileName: 'rapport_stock_eau_minerale_'
          '${DateFormat('yyyyMMdd').format(date)}.pdf',
    );
  }
}

