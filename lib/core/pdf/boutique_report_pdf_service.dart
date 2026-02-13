import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/logging/app_logger.dart';
import '../../features/boutique/domain/entities/closing.dart';
import '../../features/boutique/domain/entities/report_data.dart';
import 'base_report_pdf_service.dart';

/// Service pour générer des PDF de rapports pour le module Boutique.
class BoutiqueReportPdfService extends BaseReportPdfService {
  BoutiqueReportPdfService._();
  static final BoutiqueReportPdfService instance = BoutiqueReportPdfService._();

  /// Génère un PDF de rapport complet pour une période.
  Future<File> generateReport({
    required FullBoutiqueReportData reportData,
  }) async {
    try {
      final start = reportData.startDate;
      final end = reportData.endDate;

      final contentSections = [
        buildKpiSection(
          title: 'Résumé Financier',
          kpis: [
            {
              'label': 'Chiffre d\'Affaires',
              'value': formatCurrency(reportData.general.salesRevenue),
            },
            {
              'label': 'Montant des Achats (Stock)',
              'value': formatCurrency(reportData.general.purchasesAmount),
            },
            {
              'label': 'Dépenses Opérationnelles',
              'value': formatCurrency(reportData.general.expensesAmount),
            },
            {'label': 'Bénéfice Net', 'value': formatCurrency(reportData.general.profit)},
            {
              'label': 'Taux de Marge Net',
              'value': '${reportData.general.profitMarginPercentage.toStringAsFixed(1)}%',
            },
          ],
        ),
        
        // Sales details
        buildTableSection(
          title: 'Top 10 Produits Vendus',
          headers: ['Produit', 'Quantité', 'Chiffre d\'Affaires'],
          rows: reportData.sales.topProducts.map((p) => [
            p.productName,
            p.quantitySold.toString(),
            formatCurrency(p.revenue),
          ]).toList(),
          columnAlignments: [
            pw.TextAlign.left,
            pw.TextAlign.right,
            pw.TextAlign.right,
          ],
        ),

        // Purchase details
        buildTableSection(
          title: 'Principaux Fournisseurs',
          headers: ['Fournisseur', 'Achats', 'Montant Total'],
          rows: reportData.purchases.topSuppliers.map((s) => [
            s.supplierName,
            s.purchasesCount.toString(),
            formatCurrency(s.totalAmount),
          ]).toList(),
          columnAlignments: [
            pw.TextAlign.left,
            pw.TextAlign.right,
            pw.TextAlign.right,
          ],
        ),

        // Expense details
        buildTableSection(
          title: 'Dépenses par Catégorie',
          headers: ['Catégorie', 'Montant'],
          rows: reportData.expenses.byCategory.entries.map((e) => [
            e.key,
            formatCurrency(e.value),
          ]).toList(),
          columnAlignments: [
            pw.TextAlign.left,
            pw.TextAlign.right,
          ],
        ),

        // Profitability analysis
        buildKpiSection(
          title: 'Analyse de Rentabilité',
          kpis: [
            {
              'label': 'Marge Brute',
              'value': formatCurrency(reportData.profit.grossProfit),
            },
            {
              'label': 'Taux de Marge Brute',
              'value': '${reportData.profit.grossMarginPercentage.toStringAsFixed(1)}%',
            },
            {
              'label': 'Dépenses de Fonctionnement',
              'value': formatCurrency(reportData.profit.totalExpenses),
            },
            {
              'label': 'Bénéfice Net Global',
              'value': formatCurrency(reportData.profit.netProfit),
            },
            {
              'label': 'Marge Nette Globale',
              'value': '${reportData.profit.netMarginPercentage.toStringAsFixed(1)}%',
            },
          ],
        ),
      ];

      return await generateReportPdf(
        moduleName: 'Boutique',
        reportTitle: 'Rapport Financier',
        startDate: start,
        endDate: end,
        contentSections: contentSections,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to generate Boutique PDF report', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<File> generateZReport({
    required Closing closing,
  }) async {
    try {
      final contentSections = [
        buildKpiSection(
          title: 'Réconciliation Global',
          kpis: [
            {
              'label': 'Ventes Totales',
              'value': formatCurrency(closing.digitalRevenue),
            },
            {
              'label': 'Dépenses Totales',
              'value': formatCurrency(closing.digitalExpenses),
            },
            {
              'label': 'Attendu Net (Théorique)',
              'value': formatCurrency(closing.digitalNet),
            },
            {
              'label': 'Total Physique (Cash + MM)',
              'value':
                  formatCurrency(
                    closing.physicalCashAmount +
                        closing.physicalMobileMoneyAmount,
                  ),
            },
            {
              'label': 'Écart Global',
              'value': formatCurrency(closing.discrepancy),
            },
          ],
        ),
        buildKpiSection(
          title: 'Détail Espèces (Cash)',
          kpis: [
            {
              'label': 'Fonds de Caisse (Ouverture)',
              'value': formatCurrency(closing.openingCashAmount),
            },
            {
              'label': 'Ventes Cash (Session)',
              'value': formatCurrency(closing.digitalCashRevenue),
            },
            {
              'label': 'Dépenses (Session)',
              'value': formatCurrency(-closing.digitalExpenses),
            },
            {
              'label': 'Attendu Cash Final',
              'value': formatCurrency(closing.expectedCash),
            },
            {
              'label': 'Cash Physique en Caisse',
              'value': formatCurrency(closing.physicalCashAmount),
            },
            {
              'label': 'Écart Cash',
              'value': formatCurrency(closing.cashDiscrepancy),
            },
          ],
        ),
        buildKpiSection(
          title: 'Détail Mobile Money',
          kpis: [
            {
              'label': 'Solde MM (Ouverture)',
              'value': formatCurrency(closing.openingMobileMoneyAmount),
            },
            {
              'label': 'Ventes MM (Session)',
              'value': formatCurrency(closing.digitalMobileMoneyRevenue),
            },
            {
              'label': 'Attendu MM Final',
              'value': formatCurrency(closing.expectedMobileMoney),
            },
            {
              'label': 'Solde MM Physique (Compte)',
              'value': formatCurrency(closing.physicalMobileMoneyAmount),
            },
            {
              'label': 'Écart Mobile Money',
              'value': formatCurrency(closing.mobileMoneyDiscrepancy),
            },
          ],
        ),
      ];

      if (closing.notes != null || closing.openingNotes != null) {
        final List<Map<String, String>> notesKpis = [];
        if (closing.openingNotes != null) {
          notesKpis.add({'label': 'Notes Ouverture', 'value': closing.openingNotes!});
        }
        if (closing.notes != null) {
          notesKpis.add({'label': 'Notes Clôture', 'value': closing.notes!});
        }

        contentSections.add(
          buildKpiSection(
            title: 'Notes & Justifications',
            kpis: notesKpis,
          ),
        );
      }

      return await generateReportPdf(
        moduleName: 'Boutique',
        reportTitle: 'Bilan de Clôture (Z-Report)',
        startDate: closing.date,
        endDate: closing.date,
        fileName: 'Z-Report_${formatDate(closing.date).replaceAll('/', '-')}.pdf',
        contentSections: contentSections,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to generate Boutique Z-Report', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
