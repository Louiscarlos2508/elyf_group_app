import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../domain/entities/sale.dart';
import 'invoice_print_helpers.dart';
import 'invoice_pdf_components.dart';

/// Construit le contenu PDF pour un reçu de paiement crédit.
pw.Widget buildCreditPaymentPdfContent({
  required String customerName,
  required Sale sale,
  required int paymentAmount,
  required int remainingAfterPayment,
  String? notes,
}) {
  final now = DateTime.now();

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      buildPdfHeader('REÇU DE PAIEMENT'),
      pw.SizedBox(height: 20),
      pw.Divider(),
      pw.SizedBox(height: 10),

      // Date
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Date: ${InvoicePrintHelpers.formatDate(now)}'),
          pw.Text('Heure: ${InvoicePrintHelpers.formatTime(now)}'),
        ],
      ),
      pw.SizedBox(height: 20),

      // Client
      buildPdfClientSection(customerName: customerName),
      pw.SizedBox(height: 20),

      // Vente référence
      _buildSaleReferenceSection(sale),
      pw.SizedBox(height: 20),

      // Paiement
      _buildPaymentSection(sale, paymentAmount),
      pw.SizedBox(height: 20),

      // Reste à payer
      _buildRemainingAmountSection(remainingAfterPayment),

      if (notes != null && notes.isNotEmpty) ...[
        pw.SizedBox(height: 20),
        pw.Text('Note: $notes'),
      ],

      pw.Spacer(),

      // Footer
      buildPdfFooter('Merci !'),
    ],
  );
}

/// Construit la section de référence de vente.
pw.Widget _buildSaleReferenceSection(Sale sale) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'VENTE DE RÉFÉRENCE',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text('Date: ${InvoicePrintHelpers.formatDate(sale.date)}'),
        pw.Text('Produit: ${sale.productName}'),
        pw.Text('Quantité: ${sale.quantity}'),
        pw.Text(
          'Total vente: ${InvoicePrintHelpers.formatCurrency(sale.totalPrice)}',
        ),
        pw.Text(
          'Déjà payé avant: '
          '${InvoicePrintHelpers.formatCurrency(sale.amountPaid)}',
        ),
      ],
    ),
  );
}

/// Construit la section de paiement.
pw.Widget _buildPaymentSection(Sale sale, int paymentAmount) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(15),
    decoration: pw.BoxDecoration(
      color: PdfColors.green100,
      border: pw.Border.all(color: PdfColors.green),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      children: [
        pw.Text(
          'PAIEMENT AUJOURD\'HUI',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          InvoicePrintHelpers.formatCurrency(paymentAmount),
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green900,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total payé: '
          '${InvoicePrintHelpers.formatCurrency(sale.amountPaid + paymentAmount)}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}

/// Construit la section du reste à payer.
pw.Widget _buildRemainingAmountSection(int remainingAfterPayment) {
  if (remainingAfterPayment > 0) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Reste à payer:'),
          pw.Text(
            InvoicePrintHelpers.formatCurrency(remainingAfterPayment),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange900,
            ),
          ),
        ],
      ),
    );
  }

  return pw.Center(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.green100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        'SOLDÉ',
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.green900,
        ),
      ),
    ),
  );
}

