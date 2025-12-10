import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Service de base pour générer des PDF de rapports de stock.
abstract class BaseStockReportPdfService {
  /// Génère un PDF de rapport de stock.
  Future<File> generateStockReportPdf({
    required String moduleName,
    required DateTime reportDate,
    required List<StockItemData> stockItems,
    String? fileName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildHeader(moduleName),
            pw.SizedBox(height: 20),
            _buildTitle('Rapport de Stock'),
            pw.SizedBox(height: 10),
            _buildReportInfo(
              'Date du rapport: ${dateFormat.format(reportDate)} à '
              '${timeFormat.format(DateTime.now())}',
            ),
            pw.SizedBox(height: 30),
            _buildStockTable(stockItems),
            pw.SizedBox(height: 30),
            _buildSummary(stockItems),
            pw.SizedBox(height: 30),
            _buildFooter(),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final fileNameFinal = fileName ??
        'rapport_stock_${moduleName.toLowerCase().replaceAll(' ', '_')}_'
        '${DateFormat('yyyyMMdd').format(reportDate)}.pdf';
    final file = File('${output.path}/$fileNameFinal');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildHeader(String moduleName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'ELYF GROUPE',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              moduleName,
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Text(
          DateFormat('dd/MM/yyyy').format(DateTime.now()),
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _buildTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 24,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _buildReportInfo(String info) {
    return pw.Text(
      info,
      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
    );
  }

  pw.Widget _buildStockTable(List<StockItemData> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        _buildTableHeader(),
        ...items.map((item) => _buildTableRow(item)),
      ],
    );
  }

  pw.TableRow _buildTableHeader() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _buildTableCell('Article', isHeader: true),
        _buildTableCell('Quantité', isHeader: true),
        _buildTableCell('Unité', isHeader: true),
        _buildTableCell('Dernière mise à jour', isHeader: true),
      ],
    );
  }

  pw.TableRow _buildTableRow(StockItemData item) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return pw.TableRow(
      children: [
        _buildTableCell(item.name),
        _buildTableCell(_formatQuantity(item.quantity)),
        _buildTableCell(item.unit),
        _buildTableCell(dateFormat.format(item.updatedAt)),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildSummary(List<StockItemData> items) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Résumé',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Nombre total d\'articles: ${items.length}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          'Document généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    }
    return quantity.toStringAsFixed(2);
  }
}

/// Données d'un article en stock pour le rapport.
class StockItemData {
  const StockItemData({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.updatedAt,
  });

  final String name;
  final double quantity;
  final String unit;
  final DateTime updatedAt;
}

