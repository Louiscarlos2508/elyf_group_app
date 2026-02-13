
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'printer_interface.dart';

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
    return 80; // Standard PDF/A4 width heuristic in characters
  }

  @override
  Future<bool> printText(String text) async {
     return printReceipt(text);
  }

  @override
  Future<bool> printReceipt(String content) async {
    try {
      final doc = pw.Document();
      
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: content.split('\n').map((line) {
                return pw.Text(
                  line,
                  style: pw.TextStyle(
                    font: pw.Font.courier(),
                    fontSize: 9,
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
