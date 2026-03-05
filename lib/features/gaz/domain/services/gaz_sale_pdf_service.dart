import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import '../entities/gas_sale.dart';
import '../../../../core/pdf/base_payment_pdf_service.dart';

/// Service spécialisé pour générer des PDF de reçus pour les ventes de gaz.
class GazSalePdfService extends BasePaymentPdfService {
  GazSalePdfService._();
  static final GazSalePdfService instance = GazSalePdfService._();

  /// Génère un PDF de reçu pour une vente de gaz.
  Future<File> generateSaleReceipt({
    required GasSale sale,
    String? cylinderLabel,
    String? enterpriseName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildGazHeader(enterpriseName),
              pw.SizedBox(height: 30),
              buildTitle('REÇU DE VENTE'),
              pw.SizedBox(height: 24),
              _buildSaleInfo(sale, dateFormat),
              pw.SizedBox(height: 24),
              _buildSaleDetails(sale, cylinderLabel),
              pw.Spacer(),
              pw.SizedBox(height: 40),
              buildSignatureSection(),
              pw.SizedBox(height: 20),
              buildFooter(),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName = 'recu_gaz_${sale.id.split('-').last.toUpperCase()}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Génère un PDF de reçu pour une vente groupée.
  Future<File> generateBatchSaleReceipt({
    required List<GasSale> sales,
    String? enterpriseName,
  }) async {
    if (sales.isEmpty) throw Exception('No sales to generate PDF');
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final mainSale = sales.first;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildGazHeader(enterpriseName),
              pw.SizedBox(height: 30),
              buildTitle('FACTURE DE VENTE (GROS)'),
              pw.SizedBox(height: 24),
              _buildSaleInfo(mainSale, dateFormat),
              pw.SizedBox(height: 24),
              _buildBatchSaleDetails(sales),
              pw.Spacer(),
              pw.SizedBox(height: 40),
              buildSignatureSection(),
              pw.SizedBox(height: 20),
              buildFooter(),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName = 'facture_groupee_${mainSale.tourId ?? "gaz"}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildBatchSaleDetails(List<GasSale> sales) {
    double totalAmount = 0;
    int totalQty = 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DÉTAILS DES ARTICLES',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableCell('Désignation', isHeader: true),
                _tableCell('Qté', isHeader: true),
                _tableCell('P.U.', isHeader: true),
                _tableCell('Total', isHeader: true),
              ],
            ),
            ...sales.map((sale) {
              totalAmount += sale.totalAmount;
              totalQty += sale.quantity;
              return pw.TableRow(
                children: [
                  _tableCell('Gaz Bouteille'), // Generic for now
                  _tableCell(sale.quantity.toString()),
                  _tableCell('${formatCurrency(sale.unitPrice.toInt())} F'),
                  _tableCell('${formatCurrency(sale.totalAmount.toInt())} F'),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 250,
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('NBRE TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text('$totalQty BTL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('MONTANT TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${formatCurrency(totalAmount.toInt())} FCFA', 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Mode de Paiement:', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(sales.first.paymentMethod.label, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildGazHeader(String? enterpriseName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              enterpriseName?.toUpperCase() ?? 'ELYF GROUP',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.Text(
              'Département Gaz',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey600),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSaleInfo(GasSale sale, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          buildInfoRow('Date:', dateFormat.format(sale.saleDate)),
          buildInfoRow('Client:', sale.wholesalerName ?? sale.customerName ?? 'Client Divers'),
          buildInfoRow('Type Vente:', sale.saleType.label),
          if (sale.tourId != null) buildInfoRow('Tour:', sale.tourId!.split('-').last.toUpperCase()),
        ],
      ),
    );
  }

  pw.Widget _buildSaleDetails(GasSale sale, String? cylinderLabel) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DÉTAILS DE LA VENTE',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableCell('Article', isHeader: true),
                _tableCell('Qté', isHeader: true),
                _tableCell('P.U.', isHeader: true),
                _tableCell('Total', isHeader: true),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell(cylinderLabel ?? 'Bouteille Gaz'),
                _tableCell(sale.quantity.toString()),
                _tableCell('${formatCurrency(sale.unitPrice.toInt())} F'),
                _tableCell('${formatCurrency(sale.totalAmount.toInt())} F'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 200,
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${formatCurrency(sale.totalAmount.toInt())} FCFA', 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Paiement:', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(sale.paymentMethod.label, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (sale.notes != null && sale.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(sale.notes!, style: const pw.TextStyle(fontSize: 10)),
        ],
      ],
    );
  }

  pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 10,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }
}
