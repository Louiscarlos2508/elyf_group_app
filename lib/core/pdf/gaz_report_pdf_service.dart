import 'dart:io';

import '../../features/gaz/domain/entities/report_data.dart';
import 'package:pdf/widgets.dart' as pw;
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
        title: 'Vue d\'ensemble Financière',
        kpis: [
          {
            'label': 'Chiffre d\'Affaires (CA)',
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
        ],
      ),
      
      // Répartition par produit
      if (reportData.productBreakdown.isNotEmpty)
        buildTableSection(
          title: 'Répartition des Ventes par Produit',
          headers: ['Type de Bouteille', 'Volume Vendu'],
          rows: reportData.productBreakdown.entries
              .map((e) => [e.key, '${e.value} bouteilles'])
              .toList(),
          columnAlignments: [pw.TextAlign.left, pw.TextAlign.right],
        ),

      buildKpiSection(
        title: 'Statistiques de Vente',
        kpis: [
          {
            'label': 'Nombre total de ventes',
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

      // Performance Réseau POS (si applicable)
      if (reportData.posPerformance.isNotEmpty)
        buildTableSection(
          title: 'Performance du Réseau de Points de Vente',
          headers: ['Point de Vente', 'CA', 'Ventes', 'Volume', 'Top Produit', 'Part CA'],
          rows: reportData.posPerformance
              .map((pos) => [
                    pos.enterpriseName,
                    formatCurrency(pos.revenue.toInt()),
                    '${pos.salesCount}',
                    '${pos.quantitySold}',
                    pos.topProduct ?? '-',
                    '${pos.revenuePercentage.toStringAsFixed(1)}%',
                  ])
              .toList(),
          columnAlignments: [
            pw.TextAlign.left,
            pw.TextAlign.right,
            pw.TextAlign.right,
            pw.TextAlign.right,
            pw.TextAlign.center,
            pw.TextAlign.right,
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
