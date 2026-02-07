import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_payment.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/salary_payment.dart';

class PaymentReceiptGenerator {
  
  static Future<void> generateProductionReceipt(ProductionPayment payment) async {
    final doc = pw.Document();
    
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildReceiptLayout(
            context, 
            title: 'REÇU DE PAIEMENT - PRODUCTION',
            id: payment.id,
            date: payment.paymentDate,
            amount: payment.totalAmount,
            period: payment.period,
            beneficiary: payment.persons.length == 1 
                ? payment.persons.first.name 
                : 'Groupe (${payment.persons.length} personnes)',
            details: [
              for (final p in payment.persons)
                _PaymentDetailRow(
                  label: p.name,
                  value: '${p.daysWorked}j x ${p.pricePerDay} = ${CurrencyFormatter.format(p.totalAmount ?? 0)}',
                ),
            ],
            signature: payment.signature,
            signerName: payment.signerName,
            font: font,
            fontBold: fontBold,
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'recu_production_${payment.period}.pdf',
    );
  }

  static Future<void> generateMonthlyReceipt(SalaryPayment payment) async {
    final doc = pw.Document();

    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildReceiptLayout(
            context,
            title: 'BULLETIN DE SALAIRE',
            id: payment.id,
            date: payment.date,
            amount: payment.amount,
            period: payment.period,
            beneficiary: payment.employeeName,
            details: [
               _PaymentDetailRow(label: 'Salaire de base', value: CurrencyFormatter.format(payment.amount)),
               // Add bonuses/deductions if available in model later
            ],
            signature: payment.signature,
            signerName: payment.signerName,
            font: font,
            fontBold: fontBold,
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'bulletin_salaire_${payment.employeeName}_${payment.period}.pdf',
    );
  }

  static pw.Widget _buildReceiptLayout(
    pw.Context context, {
    required String title,
    required String id,
    required DateTime date,
    required int amount,
    required String period,
    required String beneficiary,
    required List<_PaymentDetailRow> details,
    required Uint8List? signature,
    String? signerName, // Added parameter
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('ELYF GROUP', style: pw.TextStyle(font: fontBold, fontSize: 20)),
                pw.Text('Division Eau Minérale', style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 16)),
                pw.Text('N° $id', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
                pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(date)}', style: pw.TextStyle(font: font, fontSize: 10)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 40),

        // Info Block
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Bénéficiaire', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
                  pw.Text(beneficiary, style: pw.TextStyle(font: fontBold, fontSize: 14)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Période', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
                  pw.Text(period, style: pw.TextStyle(font: fontBold, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 30),

        // Amount
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text('Montant Net à Payer', style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey600)),
              pw.Text(
                CurrencyFormatter.formatFCFA(amount),
                style: pw.TextStyle(font: fontBold, fontSize: 32, color: PdfColors.blue900),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 30),

        // Details Table
        pw.Text('Détails du paiement', style: pw.TextStyle(font: fontBold, fontSize: 12)),
        pw.Divider(color: PdfColors.grey300),
        ...details.map((d) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(d.label, style: pw.TextStyle(font: font, fontSize: 11)),
              pw.Text(d.value, style: pw.TextStyle(font: font, fontSize: 11)),
            ],
          ),
        )),
        pw.Divider(color: PdfColors.grey300),
        
        pw.Spacer(),

        // Signatures
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Pour la Direction', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                pw.SizedBox(height: 50),
                pw.Container(
                  width: 150,
                  height: 1,
                  color: PdfColors.grey400,
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Signature du Bénéficiaire', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                if (signerName != null && signerName.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('Signé par : $signerName', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
                ],
                pw.SizedBox(height: 10),
                if (signature != null)
                   pw.Container(
                     height: 60,
                     width: 120,
                     child: pw.Image(pw.MemoryImage(signature)),
                   )
                else
                  pw.SizedBox(height: 50),
                  
                pw.Container(
                  width: 150,
                  height: 1,
                  color: PdfColors.grey400,
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 30),
        pw.Center(
          child: pw.Text(
            'Ce document est une preuve de paiement générée électroniquement.',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
          ),
        ),
      ],
    );
  }
}

class _PaymentDetailRow {
  final String label;
  final String value;
  _PaymentDetailRow({required this.label, required this.value});
}
