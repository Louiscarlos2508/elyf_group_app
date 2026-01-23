import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../domain/entities/sale.dart';
import 'invoice_print_helpers.dart';
import 'invoice_pdf_components.dart';

/// Construit le contenu PDF pour une facture de vente.
pw.Widget buildSalePdfContent(Sale sale) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      buildPdfHeader('FACTURE DE VENTE'),
      pw.SizedBox(height: 10),
      pw.Divider(), 
      pw.SizedBox(height: 10),

      // Info facture
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('N°: ${InvoicePrintHelpers.truncateId(sale.id)}'),
          pw.Text(
            'Date: ${InvoicePrintHelpers.formatDate(sale.date)} '
            '${InvoicePrintHelpers.formatTime(sale.date)}',
          ),
        ],
      ),
      pw.SizedBox(height: 20),

      // Client
      buildPdfClientSection(
        customerName: sale.customerName,
        customerPhone: sale.customerPhone,
      ),
      pw.SizedBox(height: 20),

      // Détails
      _buildProductTable(sale),
      pw.SizedBox(height: 20),

      // Totaux
      _buildTotalsSection(sale),
      pw.Spacer(),

      // Footer
      buildPdfFooter('Merci pour votre achat !'),
    ],
  );
}

/// Construit le tableau des produits.
pw.Widget _buildProductTable(Sale sale) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Produit',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Qté',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Prix unit.',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Total',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(sale.productName),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('${sale.quantity}'),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(InvoicePrintHelpers.formatCurrency(sale.unitPrice)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(InvoicePrintHelpers.formatCurrency(sale.totalPrice)),
          ),
        ],
      ),
    ],
  );
}

/// Construit la section des totaux.
pw.Widget _buildTotalsSection(Sale sale) {
  return pw.Container(
    alignment: pw.Alignment.centerRight,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text('Total: '),
            pw.Text(
              InvoicePrintHelpers.formatCurrency(sale.totalPrice),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text('Payé: '),
            pw.Text(InvoicePrintHelpers.formatCurrency(sale.amountPaid)),
          ],
        ),
        if (sale.cashAmount > 0)
          pw.Text(
            '  - Cash: ${InvoicePrintHelpers.formatCurrency(sale.cashAmount)}',
          ),
        if (sale.orangeMoneyAmount > 0)
          pw.Text(
            '  - Orange Money: '
            '${InvoicePrintHelpers.formatCurrency(sale.orangeMoneyAmount)}',
          ),
        if (sale.remainingAmount > 0) ...[
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'CRÉDIT: ${InvoicePrintHelpers.formatCurrency(sale.remainingAmount)}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.orange900,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
