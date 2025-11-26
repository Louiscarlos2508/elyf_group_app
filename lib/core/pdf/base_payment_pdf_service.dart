import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/immobilier/domain/entities/payment.dart';

/// Service de base pour générer des PDF de paiement (factures et reçus).
abstract class BasePaymentPdfService {
  /// Construit l'en-tête du PDF.
  pw.Widget buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Column(
          children: [
            pw.Text(
              'ELYF GROUPE',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Immobilier',
              style: pw.TextStyle(
                fontSize: 14,
                color: PdfColors.blueGrey600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construit le titre du PDF.
  pw.Widget buildTitle(String title) {
    return pw.Center(
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey800,
        ),
      ),
    );
  }

  /// Construit une ligne d'information.
  pw.Widget buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la section de signatures.
  pw.Widget buildSignatureSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 150,
              height: 1,
              color: PdfColors.grey700,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Signature du Locataire',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              width: 150,
              height: 1,
              color: PdfColors.grey700,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Signature de l\'Agent',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  /// Construit le footer.
  pw.Widget buildFooter() {
    return pw.Center(
      child: pw.Text(
        'Merci pour votre paiement!',
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey600,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  /// Formate un montant en devise.
  String formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  /// Retourne le nom du mois.
  String getMonthName(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[month - 1];
  }

  /// Retourne le label de la méthode de paiement.
  String getMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bankTransfer:
        return 'Virement bancaire';
      case PaymentMethod.check:
        return 'Chèque';
    }
  }
}

