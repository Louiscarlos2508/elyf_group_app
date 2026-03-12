import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/printing/sunmi_v3_service.dart';
import '../../../../core/printing/templates/payment_receipt_template.dart';
import '../../../../shared/domain/entities/payment_method.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/tenant.dart';

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  return ReceiptService();
});

class ReceiptService {
  ReceiptService();

  final _sunmi = SunmiV3Service.instance;

  /// Vérifie si l'imprimante Sunmi est disponible.
  Future<bool> isSunmiAvailable() async {
    return await _sunmi.isSunmiDevice && await _sunmi.isPrinterAvailable();
  }

  /// Construit le contenu texte du reçu.
  String _buildReceiptContent({
    required Payment payment,
    required Tenant tenant,
    required Property property,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final amountFormat = NumberFormat('#,###', 'fr_FR');

    String period = '';
    if (payment.paymentType == PaymentType.deposit) {
      period = 'Caution / Dépôt de garantie';
    } else if (payment.month != null && payment.year != null) {
      final date = DateTime(payment.year!, payment.month!, 1);
      final monthName = DateFormat('MMMM', 'fr_FR').format(date);
      period = '${monthName[0].toUpperCase()}${monthName.substring(1)} ${payment.year}';
    }

    return PaymentReceiptTemplate.generateReceipt(
      receiptNumber: payment.receiptNumber ?? payment.id.substring(0, 8),
      paymentDate: dateFormat.format(payment.paymentDate),
      amount: amountFormat.format(payment.amount),
      paymentMethod: _formatPaymentMethod(payment.paymentMethod),
      tenantName: tenant.fullName,
      propertyAddress: '${property.address}, ${property.city}',
      period: period.isNotEmpty ? period : null,
      notes: payment.notes,
      header: 'ELYF IMMOBILIER',
      footer: 'Merci de votre confiance !',
      showLogo: true,
    );
  }

  /// Imprime un reçu via l'imprimante thermique Sunmi.
  /// (Compatibilité avec PaymentController.printReceipt)
  Future<bool> printReceipt({
    required Payment payment,
    required Tenant tenant,
    required Property property,
  }) => printReceiptSunmi(payment: payment, tenant: tenant, property: property);

  /// Imprime un reçu via l'imprimante thermique Sunmi.
  Future<bool> printReceiptSunmi({
    required Payment payment,
    required Tenant tenant,
    required Property property,
  }) async {
    final content = _buildReceiptContent(
      payment: payment,
      tenant: tenant,
      property: property,
    );
    return _sunmi.printReceipt(content);
  }

  /// Génère un PDF du reçu de paiement.
  Future<File> generateReceiptPdf({
    required Payment payment,
    required Tenant tenant,
    required Property property,
  }) async {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final amountFormat = NumberFormat('#,###', 'fr_FR');

    String period = '';
    if (payment.paymentType == PaymentType.deposit) {
      period = 'Caution / Dépôt de garantie';
    } else if (payment.month != null && payment.year != null) {
      final date = DateTime(payment.year!, payment.month!, 1);
      final monthName = DateFormat('MMMM', 'fr_FR').format(date);
      period = '${monthName[0].toUpperCase()}${monthName.substring(1)} ${payment.year}';
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'ELYF IMMOBILIER',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(child: pw.Text('REÇU DE PAIEMENT', style: const pw.TextStyle(fontSize: 14))),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 8),
            _pdfRow('N° Reçu', payment.receiptNumber ?? payment.id.substring(0, 8)),
            _pdfRow('Date', dateFormat.format(payment.paymentDate)),
            if (period.isNotEmpty) _pdfRow('Période', period),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 8),
            _pdfRow('Locataire', tenant.fullName),
            _pdfRow('Propriété', '${property.address}, ${property.city}'),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 8),
            _pdfRow('Montant', '${amountFormat.format(payment.amount)} FCFA'),
            _pdfRow('Méthode', _formatPaymentMethod(payment.paymentMethod)),
            if (payment.notes != null && payment.notes!.isNotEmpty)
              _pdfRow('Notes', payment.notes!),
            pw.SizedBox(height: 24),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 32),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Signature locataire:'),
                    pw.SizedBox(height: 40),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Signature et cachet:'),
                    pw.SizedBox(height: 40),
                  ],
                ),
              ],
            ),
            pw.Spacer(),
            pw.Center(child: pw.Text('Merci pour votre confiance !', style: const pw.TextStyle(fontSize: 10))),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/recu_paiement_${payment.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.both:
        return 'Espèces + Mobile Money';
      case PaymentMethod.credit:
        return 'Crédit / Dette';
    }
  }
}
