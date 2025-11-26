import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/immobilier/domain/entities/contract.dart';
import '../../features/immobilier/domain/entities/expense.dart';
import '../../features/immobilier/domain/entities/payment.dart';
import '../../features/immobilier/domain/entities/property.dart';
import '../../features/immobilier/domain/entities/report_period.dart';
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
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    // Calculer les dates selon la période
    if (startDate != null && endDate != null) {
      start = startDate;
      end = endDate;
    } else {
      switch (period) {
        case ReportPeriod.today:
          start = DateTime(now.year, now.month, now.day);
          end = now;
          break;
        case ReportPeriod.thisWeek:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(weekStart.year, weekStart.month, weekStart.day);
          end = now;
          break;
        case ReportPeriod.thisMonth:
          start = DateTime(now.year, now.month, 1);
          end = now;
          break;
        case ReportPeriod.thisYear:
          start = DateTime(now.year, 1, 1);
          end = now;
          break;
        case ReportPeriod.custom:
          start = startDate ?? now;
          end = endDate ?? now;
          break;
      }
    }

    // Calculs des KPIs
    final totalProperties = properties.length;
    final availableProperties = properties
        .where((p) => p.status == PropertyStatus.available)
        .length;
    final rentedProperties = properties
        .where((p) => p.status == PropertyStatus.rented)
        .length;

    final activeContracts = contracts
        .where((c) => c.status == ContractStatus.active)
        .length;

    final totalMonthlyRent = contracts
        .where((c) => c.status == ContractStatus.active)
        .fold<int>(
          0,
          (sum, c) => sum + c.monthlyRent,
        );

    final periodRevenue = periodPayments
        .where((p) => p.status == PaymentStatus.paid)
        .fold<int>(
          0,
          (sum, p) => sum + p.amount,
        );

    final periodExpensesTotal = periodExpenses.fold<int>(
      0,
      (sum, e) => sum + e.amount,
    );

    final netRevenue = periodRevenue - periodExpensesTotal;
    final occupancyRate = totalProperties > 0
        ? (rentedProperties / totalProperties) * 100
        : 0.0;

    final contentSections = [
      buildKpiSection(
        title: 'Vue d\'ensemble',
        kpis: [
          {
            'label': 'Total Propriétés',
            'value': '$totalProperties',
          },
          {
            'label': 'Propriétés Disponibles',
            'value': '$availableProperties',
          },
          {
            'label': 'Propriétés Louées',
            'value': '$rentedProperties',
          },
          {
            'label': 'Taux d\'occupation',
            'value': '${occupancyRate.toStringAsFixed(1)}%',
          },
          {
            'label': 'Contrats Actifs',
            'value': '$activeContracts',
          },
          {
            'label': 'Loyers Mensuels Totaux',
            'value': formatCurrency(totalMonthlyRent),
          },
        ],
      ),
      pw.SizedBox(height: 20),
      buildKpiSection(
        title: 'Période Sélectionnée',
        kpis: [
          {
            'label': 'Revenus de la période',
            'value': formatCurrency(periodRevenue),
          },
          {
            'label': 'Dépenses de la période',
            'value': formatCurrency(periodExpensesTotal),
          },
          {
            'label': 'Résultat Net',
            'value': formatCurrency(netRevenue),
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

