
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'printer_interface.dart';

/// Format facture 80x210mm (points: 72 pt = 1 inch, 1 inch = 25.4 mm).
final PdfPageFormat _receipt80x210 = PdfPageFormat(
  80 * (72 / 25.4),
  210 * (72 / 25.4),
  marginAll: 4,
);

class SystemPrinterService implements PrinterInterface {
  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  Future<bool> isAvailable() async {
    return true; // System printing is always "available" as a service
  }

  @override
  Future<int> getLineWidth() async {
    return 48; // 80mm, aligné avec thermique / journal
  }

  @override
  Future<bool> printText(String text) async {
     return printReceipt(text);
  }

  static const int _lineWidth = 48;
  static const double _baseFontSize = 9.0;
  static const double _minFontSize = 5.0;

  @override
  Future<bool> printReceipt(String content) async {
    try {
      final doc = pw.Document();

      // Adapter la ligne à la page : réduire la taille de police si la ligne est longue
      double fontSizeForLine(String s) {
        if (s.isEmpty) return _baseFontSize;
        final len = s.length;
        if (len <= _lineWidth) return _baseFontSize;
        final size = _baseFontSize * _lineWidth / len;
        return size.clamp(_minFontSize, _baseFontSize);
      }

      doc.addPage(
        pw.Page(
          pageFormat: _receipt80x210,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: content.split('\n').map((line) {
                return pw.Text(
                  line,
                  style: pw.TextStyle(
                    font: pw.Font.courier(),
                    fontSize: fontSizeForLine(line),
                  ),
                );
              }).toList(),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => doc.save(),
        name: 'ELYF-Receipt',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> printImage(Uint8List bytes) async {
    // TODO: Implement image printing for PDF
    return false;
  }

  @override
  Future<bool> openDrawer() async {
    return false; // Not supported by system printing
  }

  @override
  Future<void> disconnect() async {
    // Nothing to do
  }
}
