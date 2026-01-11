import 'dart:io';


import '../../features/eau_minerale/domain/entities/report_data.dart';
import '../../features/eau_minerale/domain/entities/report_period.dart';
import 'base_report_pdf_service.dart';

/// Service pour générer des PDF de rapports pour le module Eau Minérale.
class EauMineraleReportPdfService extends BaseReportPdfService {
  EauMineraleReportPdfService._();
  static final EauMineraleReportPdfService instance =
      EauMineraleReportPdfService._();

  /// Génère un PDF de rapport complet pour une période.
  Future<File> generateReport({
    required ReportPeriod period,
    required ReportData reportData,
  }) async {
    final contentSections = [
      buildKpiSection(
        title: 'Vue d\'ensemble',
        kpis: [
          {
            'label': 'Chiffre d\'Affaires',
            'value': formatCurrency(reportData.revenue),
          },
          {
            'label': 'Encaissements',
            'value': formatCurrency(reportData.collections),
          },
          {
            'label': 'Taux d\'encaissement',
            'value': '${reportData.collectionRate.toStringAsFixed(1)}%',
          },
          {
            'label': 'Charges Totales',
            'value': formatCurrency(reportData.totalExpenses),
          },
          {
            'label': 'Trésorerie',
            'value': formatCurrency(reportData.treasury),
          },
          {
            'label': 'Nombre de ventes',
            'value': '${reportData.salesCount}',
          },
        ],
      ),
    ];

    return generateReportPdf(
      moduleName: 'Eau Minérale',
      reportTitle: 'Rapport Financier',
      startDate: period.startDate,
      endDate: period.endDate,
      contentSections: contentSections,
    );
  }
}

