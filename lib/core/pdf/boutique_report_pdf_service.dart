import 'dart:io';

import '../../features/boutique/domain/entities/report_data.dart';
import 'base_report_pdf_service.dart';

/// Service pour générer des PDF de rapports pour le module Boutique.
class BoutiqueReportPdfService extends BaseReportPdfService {
  BoutiqueReportPdfService._();
  static final BoutiqueReportPdfService instance = BoutiqueReportPdfService._();

  /// Génère un PDF de rapport complet pour une période.
  Future<File> generateReport({
    required ReportData reportData,
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
            'value': formatCurrency(reportData.salesRevenue),
          },
          {
            'label': 'Montant des Achats',
            'value': formatCurrency(reportData.purchasesAmount),
          },
          {
            'label': 'Montant des Dépenses',
            'value': formatCurrency(reportData.expensesAmount),
          },
          {'label': 'Bénéfice Net', 'value': formatCurrency(reportData.profit)},
          {
            'label': 'Taux de Marge',
            'value': '${reportData.profitMarginPercentage.toStringAsFixed(1)}%',
          },
          {'label': 'Nombre de ventes', 'value': '${reportData.salesCount}'},
          {
            'label': 'Nombre d\'achats',
            'value': '${reportData.purchasesCount}',
          },
          {
            'label': 'Nombre de dépenses',
            'value': '${reportData.expensesCount}',
          },
        ],
      ),
    ];

    return generateReportPdf(
      moduleName: 'Boutique',
      reportTitle: 'Rapport Financier',
      startDate: start,
      endDate: end,
      contentSections: contentSections,
    );
  }
}
