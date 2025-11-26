import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/immobilier/domain/entities/contract.dart';
import '../../features/immobilier/domain/entities/payment.dart';
import '../../features/immobilier/domain/entities/property.dart';
import '../../features/immobilier/domain/entities/tenant.dart';
import 'base_payment_pdf_service.dart';

/// Helpers pour construire des widgets PDF communs.
class PaymentPdfHelpers {
  PaymentPdfHelpers._();

  /// Construit un conteneur avec bordure.
  static pw.Widget buildBorderedContainer({
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Construit un titre de section.
  static pw.Widget buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey700,
      ),
    );
  }

  /// Construit un tableau de total.
  static pw.Widget buildTotalTable({
    required String label,
    required String amount,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit les informations du contrat.
  static pw.Widget buildContractInfo({
    required Contract? contract,
    required Property? property,
    required Tenant? tenant,
    required DateFormat dateFormat,
    required BasePaymentPdfService service,
    bool showDepositInfo = false, // Afficher les infos de caution uniquement si nécessaire
  }) {
    return buildBorderedContainer(
      children: [
        buildSectionTitle('Informations du Contrat'),
        pw.SizedBox(height: 12),
        service.buildInfoRow('Propriété:', property?.address ?? 'N/A'),
        if (property != null) service.buildInfoRow('Ville:', property.city),
        service.buildInfoRow('Locataire:', tenant?.fullName ?? 'N/A'),
        if (tenant != null && tenant.phone.isNotEmpty)
          service.buildInfoRow('Téléphone:', tenant.phone),
        if (contract != null) ...[
          service.buildInfoRow('Loyer mensuel:',
              '${service.formatCurrency(contract.monthlyRent)} FCFA'),
          service.buildInfoRow(
              'Date de début:', dateFormat.format(contract.startDate)),
          service.buildInfoRow(
              'Date de fin:', dateFormat.format(contract.endDate)),
          if (contract.paymentDay != null)
            service.buildInfoRow('Jour de paiement:',
                'Le ${contract.paymentDay} de chaque mois'),
          // Afficher la caution uniquement si demandé (pour les factures de caution)
          if (showDepositInfo) ...[
            if (contract.depositInMonths != null)
              service.buildInfoRow('Caution:',
                  '${contract.depositInMonths} mois (${service.formatCurrency(contract.calculatedDeposit)} FCFA)')
            else if (contract.deposit > 0)
              service.buildInfoRow(
                  'Caution:', '${service.formatCurrency(contract.deposit)} FCFA'),
          ],
        ],
      ],
    );
  }
}

