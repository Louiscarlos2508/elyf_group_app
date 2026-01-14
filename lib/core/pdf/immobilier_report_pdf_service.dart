import 'dart:io';

import 'package:pdf/widgets.dart' as pw;

import '../../features/immobilier/domain/entities/contract.dart';
import '../../features/immobilier/domain/entities/expense.dart';
import '../../features/immobilier/domain/entities/payment.dart';
import '../../features/immobilier/domain/entities/property.dart';
import '../../features/immobilier/domain/entities/report_period.dart';
import '../../features/immobilier/domain/services/dashboard_calculation_service.dart';
import 'base_report_pdf_service.dart';

/// Service pour générer des PDF de rapports pour le module Immobilier.
class ImmobilierReportPdfService extends BaseReportPdfService {
  ImmobilierReportPdfService._();
  static final ImmobilierReportPdfService instance =
      ImmobilierReportPdfService._();

  /// Génère un PDF de rapport complet pour une période.
  Future<File> generateReport({
    required ReportPeriod period,
    DateTime? startDate,
    DateTime? endDate,
    required List<Property> properties,
    required List<Contract> contracts,
    required List<Payment> payments,
    required List<PropertyExpense> expenses,
    required List<Payment> periodPayments,
    required List<PropertyExpense> periodExpenses,
  }) async {
    // Utiliser le service de calcul pour extraire la logique métier
    final calculationService = ImmobilierDashboardCalculationService();

    // Calculer les dates de période
    final periodDates = calculationService.calculatePeriodDates(
      period: period,
      startDate: startDate,
      endDate: endDate,
    );
    final start = periodDates.start;
    final end = periodDates.end;

    // Calculer les métriques de période
    final metrics = calculationService.calculatePeriodMetrics(
      properties: properties,
      contracts: contracts,
      periodPayments: periodPayments,
      periodExpenses: periodExpenses,
    );

    final contentSections = [
      buildKpiSection(
        title: 'Vue d\'ensemble',
        kpis: [
          {'label': 'Total Propriétés', 'value': '${metrics.totalProperties}'},
          {
            'label': 'Propriétés Disponibles',
            'value': '${metrics.availableProperties}',
          },
          {
            'label': 'Propriétés Louées',
            'value': '${metrics.rentedProperties}',
          },
          {
            'label': 'Taux d\'occupation',
            'value': '${metrics.occupancyRate.toStringAsFixed(1)}%',
          },
          {
            'label': 'Contrats Actifs',
            'value': '${metrics.activeContractsCount}',
          },
          {
            'label': 'Loyers Mensuels Totaux',
            'value': formatCurrency(metrics.totalMonthlyRent),
          },
        ],
      ),
      pw.SizedBox(height: 20),
      buildKpiSection(
        title: 'Période Sélectionnée',
        kpis: [
          {
            'label': 'Revenus de la période',
            'value': formatCurrency(metrics.periodRevenue),
          },
          {
            'label': 'Dépenses de la période',
            'value': formatCurrency(metrics.periodExpensesTotal),
          },
          {
            'label': 'Résultat Net',
            'value': formatCurrency(metrics.netRevenue),
          },
        ],
      ),
    ];

    return generateReportPdf(
      moduleName: 'Immobilier',
      reportTitle: 'Rapport Financier',
      startDate: start,
      endDate: end,
      contentSections: contentSections,
    );
  }
}
