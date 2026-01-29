import 'dart:io';

import '../../features/gaz/domain/entities/report_data.dart';
import 'base_report_pdf_service.dart';

/// Service pour générer des PDF de rapports pour le module Gaz.
class GazReportPdfService extends BaseReportPdfService {
  GazReportPdfService._();
  static final GazReportPdfService instance = GazReportPdfService._();

  /// Génère un PDF de rapport complet pour une période.
  Future<File> generateReport({
    required GazReportData reportData,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now();
    final end = endDate ?? DateTime.now();

    final contentSections = [
      buildKpiSection(
        title: 'Vue d\'ensemble',
        kpis: [
          {
            'label': 'Chiffre d\'Affaires',
            'value': formatCurrency(reportData.salesRevenue.toInt()),
          },
          {
            'label': 'Montant des Dépenses',
            'value': formatCurrency(reportData.expensesAmount.toInt()),
          },
          {
            'label': 'Bénéfice Net',
            'value': formatCurrency(reportData.profit.toInt()),
          },
          {
            'label': 'Taux de Marge',
            'value': '${reportData.profitMarginPercentage.toStringAsFixed(1)}%',
          },
          {
            'label': 'Nombre de ventes',
            'value': '${reportData.salesCount}',
          },
          {
            'label': 'Ventes au détail',
            'value': '${reportData.retailSalesCount}',
          },
          {
            'label': 'Ventes en gros',
            'value': '${reportData.wholesaleSalesCount}',
          },
          {
            'label': 'Nombre de dépenses',
            'value': '${reportData.expensesCount}',
          },
        ],
      ),
    ];

    return generateReportPdf(
      moduleName: 'Gaz',
      reportTitle: 'Rapport Financier',
      startDate: start,
      endDate: end,
      contentSections: contentSections,
    );
  }
}
