import 'dart:io';

import 'package:intl/intl.dart';

import '../../features/eau_minerale/domain/entities/packaging_stock.dart';
import '../../features/eau_minerale/domain/entities/stock_item.dart';
import 'base_stock_report_pdf_service.dart';

/// Service pour générer le rapport de stock du module Eau Minérale.
class EauMineraleStockReportPdfService extends BaseStockReportPdfService {
  /// Génère un rapport de stock complet pour le module Eau Minérale.
  /// Inclut : produits finis, matières premières, emballages, et bobines.
  Future<File> generateReport({
    required List<StockItem> stockItems,
    required List<PackagingStock> packagingStocks,
    required int availableBobines,
    DateTime? reportDate,
  }) async {
    final date = reportDate ?? DateTime.now();

    // Convertir les StockItems (produits finis et matières premières)
    // Filtrer les items "sachet" et "bidon" qui ne doivent pas apparaître dans le rapport
    final stockData = stockItems
        .where(
          (item) =>
              !item.name.toLowerCase().contains('sachet') &&
              !item.name.toLowerCase().contains('bidon'),
        )
        .map((item) {
          return StockItemData(
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            updatedAt: item.updatedAt,
          );
        })
        .toList();

    // Ajouter les emballages
    final packagingData = packagingStocks.map((stock) {
      return StockItemData(
        name: stock.type,
        quantity: stock.quantity.toDouble(),
        unit: stock.unit,
        updatedAt: stock.updatedAt ?? DateTime.now(),
      );
    }).toList();

    // Ajouter les bobines disponibles
    if (availableBobines > 0) {
      stockData.add(
        StockItemData(
          name: 'Bobines disponibles',
          quantity: availableBobines.toDouble(),
          unit: 'unité',
          updatedAt: DateTime.now(),
        ),
      );
    }

    // Combiner toutes les données
    final allStockData = [...stockData, ...packagingData];

    return generateStockReportPdf(
      moduleName: 'Eau Minérale',
      reportDate: date,
      stockItems: allStockData,
      fileName:
          'rapport_stock_eau_minerale_'
          '${DateFormat('yyyyMMdd').format(date)}.pdf',
    );
  }
}
