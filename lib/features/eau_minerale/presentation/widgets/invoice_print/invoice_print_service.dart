import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:elyf_groupe_app/core/printing/sunmi_v3_service.dart';
import '../../../domain/entities/sale.dart';
import 'invoice_thermal_receipts.dart';
import 'invoice_pdf_builder.dart';

/// Service pour l'impression de factures eau minérale (Sunmi + PDF).
class EauMineraleInvoiceService {
  EauMineraleInvoiceService._();
  static final instance = EauMineraleInvoiceService._();

  final _sunmi = SunmiV3Service.instance;

  /// Vérifie si l'imprimante Sunmi est disponible.
  Future<bool> isSunmiAvailable() async {
    return await _sunmi.isSunmiDevice && await _sunmi.isPrinterAvailable();
  }

  /// Imprime une facture de vente via Sunmi.
  Future<bool> printSaleInvoice(Sale sale) async {
    final content = generateSaleReceipt(sale);
    return await _sunmi.printReceipt(content);
  }

  /// Imprime un reçu de paiement crédit via Sunmi.
  Future<bool> printCreditPaymentReceipt({
    required String customerName,
    required Sale sale,
    required int paymentAmount,
    required int remainingAfterPayment,
    String? notes,
  }) async {
    final content = generateCreditPaymentReceipt(
      customerName: customerName,
      sale: sale,
      paymentAmount: paymentAmount,
      remainingAfterPayment: remainingAfterPayment,
      notes: notes,
    );
    return await _sunmi.printReceipt(content);
  }

  /// Génère et ouvre un PDF de facture de vente.
  Future<File> generateSalePdf(Sale sale) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => buildSalePdfContent(sale),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/facture_${sale.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Génère et ouvre un PDF de reçu de paiement crédit.
  Future<File> generateCreditPaymentPdf({
    required String customerName,
    required Sale sale,
    required int paymentAmount,
    required int remainingAfterPayment,
    String? notes,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => buildCreditPaymentPdfContent(
          customerName: customerName,
          sale: sale,
          paymentAmount: paymentAmount,
          remainingAfterPayment: remainingAfterPayment,
          notes: notes,
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/recu_paiement_${sale.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}

