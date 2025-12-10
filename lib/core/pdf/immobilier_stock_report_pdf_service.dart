import '../../features/immobilier/domain/entities/property.dart';
import 'base_stock_report_pdf_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';

/// Service pour générer le rapport de stock du module Immobilier.
/// Pour Immobilier, le "stock" représente les propriétés disponibles/en location.
class ImmobilierStockReportPdfService extends BaseStockReportPdfService {
  /// Génère un rapport de stock pour le module Immobilier.
  Future<File> generateReport({
    required List<Property> properties,
    DateTime? reportDate,
  }) async {
    final date = reportDate ?? DateTime.now();
    final stockData = properties.map((property) {
      return StockItemData(
        name: '${property.address}, ${property.city}',
        quantity: 1.0,
        unit: property.status.name,
        updatedAt: property.updatedAt ?? property.createdAt ?? DateTime.now(),
      );
    }).toList();

    return generateStockReportPdf(
      moduleName: 'Immobilier',
      reportDate: date,
      stockItems: stockData,
      fileName: 'rapport_stock_immobilier_'
          '${DateFormat('yyyyMMdd').format(date)}.pdf',
    );
  }
}

