import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/immobilier/domain/entities/contract.dart';
import '../../features/immobilier/domain/entities/expense.dart';
import '../../features/immobilier/domain/entities/payment.dart';
import '../../features/immobilier/domain/entities/property.dart';
import '../../features/immobilier/domain/entities/report_period.dart';
import '../../features/immobilier/domain/entities/tenant.dart';
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
    String? enterpriseName,
    String? footerText,
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
      pw.SizedBox(height: 20),
      if (periodPayments.isNotEmpty)
        buildTableSection(
          title: 'Détail des Recettes',
          headers: ['Date', 'Locataire / Propriété', 'Description', 'Montant'],
          rows: periodPayments.map((p) {
            final tenantName = p.contract?.tenant?.fullName ?? 'Inconnu';
            final propertyName = p.contract?.property?.address ?? 'Inconnue';
            return [
              formatDate(p.paymentDate),
              '$tenantName\n($propertyName)',
              'Loyer ${p.month ?? '-'}/${p.year ?? '-'}',
              formatCurrency(p.amount),
            ];
          }).toList(),
          columnAlignments: [
            pw.TextAlign.left,
            pw.TextAlign.left,
            pw.TextAlign.left,
            pw.TextAlign.right,
          ],
        ),
      if (periodExpenses.isNotEmpty)
        buildTableSection(
          title: 'Détail des Dépenses',
          headers: ['Date', 'Propriété', 'Description', 'Montant'],
          rows: periodExpenses.map((e) {
            return [
              formatDate(e.expenseDate),
              e.property ?? 'Général',
              e.description,
              formatCurrency(e.amount),
            ];
          }).toList(),
          columnAlignments: [
            pw.TextAlign.left,
            pw.TextAlign.left,
            pw.TextAlign.left,
            pw.TextAlign.right,
          ],
        ),
    ];

    return generateReportPdf(
      moduleName: 'Immobilier',
      reportTitle: 'Rapport Financier',
      startDate: start,
      endDate: end,
      contentSections: contentSections,
      enterpriseName: enterpriseName,
      footerText: footerText,
    );
  }

  /// Génère un relevé de compte pour un locataire.
  Future<File> generateTenantBalanceReport({
    required Tenant tenant,
    required List<Contract> contracts,
    required List<Payment> payments,
    required DateTime startDate,
    required DateTime endDate,
    String? enterpriseName,
    String? footerText,
  }) async {
    // Filtrer les contrats du locataire
    final tenantContracts = contracts.where((c) => c.tenantId == tenant.id).toList();
    final tenantContractIds = tenantContracts.map((c) => c.id).toSet();
    
    // Filtrer les paiements du locataire dans la période
    final tenantPayments = payments.where((p) {
      return tenantContractIds.contains(p.contractId) &&
          p.paymentDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          p.paymentDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Trier les paiements par date
    tenantPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    // Calculer le total payé
    final totalPaid = tenantPayments.fold<int>(0, (sum, p) => sum + p.amount);

    // Contenu du rapport
    final contentSections = [
      buildKpiSection(
        title: 'Résumé du Compte',
        kpis: [
          {'label': 'Locataire', 'value': tenant.fullName},
          {'label': 'Téléphone', 'value': tenant.phone},
          {'label': 'Contrats Actifs', 'value': '${tenantContracts.where((c) => c.status == ContractStatus.active).length}'},
          {'label': 'Total Payé (Période)', 'value': formatCurrency(totalPaid)},
        ],
      ),
      pw.SizedBox(height: 20),
      pw.Header(
        level: 2,
        text: 'Historique des Paiements',
        textStyle: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey700,
        ),
      ),
      pw.SizedBox(height: 10),
      pw.TableHelper.fromTextArray(
        headers: ['Date', 'Description', 'Montant', 'Statut'],
        data: tenantPayments.map((p) {
          return [
            '${p.paymentDate.day}/${p.paymentDate.month}/${p.paymentDate.year}',
            'Loyer ${p.month}/${p.year}',
            formatCurrency(p.amount),
            p.status == PaymentStatus.paid ? 'Payé' : 'En attente',
          ];
        }).toList(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue600),
        rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
        cellAlignment: pw.Alignment.centerLeft,
        cellAlignments: {
          2: pw.Alignment.centerRight,
        },
      ),
    ];

    return generateReportPdf(
      moduleName: 'Immobilier',
      reportTitle: 'Relevé de Compte Locataire',
      startDate: startDate,
      endDate: endDate,
      contentSections: contentSections,
      enterpriseName: enterpriseName,
      footerText: footerText,
    );
  }
}
