import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Header commun pour les PDFs de factures.
pw.Widget buildPdfHeader(String title) {
  return pw.Center(
    child: pw.Column(
      children: [
        pw.Text(
          'EAU MINERALE ELYF',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text('GROUPE APP', style: const pw.TextStyle(fontSize: 14)),
        pw.SizedBox(height: 20),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

/// Section client dans un PDF.
pw.Widget buildPdfClientSection({
  required String customerName,
  String? customerPhone,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CLIENT',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text('Nom: $customerName'),
        if (customerPhone != null && customerPhone.isNotEmpty)
          pw.Text('Téléphone: $customerPhone'),
      ],
    ),
  );
}

/// Footer commun pour les PDFs.
pw.Widget buildPdfFooter(String message) {
  return pw.Center(
    child: pw.Text(
      message,
      style: const pw.TextStyle(fontSize: 12),
    ),
  );
}

