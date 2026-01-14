import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/immobilier/domain/entities/payment.dart';
import 'base_payment_pdf_service.dart';
import 'payment_pdf_helpers.dart';

/// Service unifié pour générer des PDF de paiement (factures et reçus).
class UnifiedPaymentPdfService extends BasePaymentPdfService {
  UnifiedPaymentPdfService._();
  static final UnifiedPaymentPdfService instance = UnifiedPaymentPdfService._();

  /// Génère un PDF de facture ou reçu selon le type de paiement.
  Future<File> generateDocument({
    required Payment payment,
    bool asInvoice = true,
  }) async {
    final pdf = pw.Document();
    final contract = payment.contract;
    final property = contract?.property;
    final tenant = contract?.tenant;
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Déterminer le titre selon le type
    final title = _getDocumentTitle(payment, asInvoice);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader(),
              pw.SizedBox(height: 30),
              buildTitle(title),
              pw.SizedBox(height: 20),
              _buildDocumentInfo(payment, dateFormat, asInvoice),
              pw.SizedBox(height: 20),
              PaymentPdfHelpers.buildContractInfo(
                contract: contract,
                property: property,
                tenant: tenant,
                dateFormat: dateFormat,
                service: this,
                showDepositInfo: payment.paymentType == PaymentType.deposit,
              ),
              pw.SizedBox(height: 20),
              _buildPaymentDetails(payment),
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
    final docType = asInvoice ? 'facture' : 'recu';
    final paymentType = payment.paymentType == PaymentType.deposit
        ? 'caution'
        : 'loyer';
    final invoiceNumber = payment.receiptNumber ?? payment.id;
    final file = File(
      '${output.path}/${docType}_${paymentType}_$invoiceNumber.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  String _getDocumentTitle(Payment payment, bool asInvoice) {
    if (asInvoice) {
      return payment.paymentType == PaymentType.deposit
          ? 'FACTURE DE CAUTION'
          : 'FACTURE DE LOYER';
    } else {
      return 'REÇU DE PAIEMENT';
    }
  }

  pw.Widget _buildDocumentInfo(
    Payment payment,
    DateFormat dateFormat,
    bool asInvoice,
  ) {
    final label = asInvoice ? 'Numéro de facture:' : 'Numéro de reçu:';
    return PaymentPdfHelpers.buildBorderedContainer(
      children: [
        buildInfoRow(label, payment.receiptNumber ?? payment.id),
        buildInfoRow(
          asInvoice ? 'Date de facture:' : 'Date d\'émission:',
          dateFormat.format(payment.paymentDate),
        ),
        if (payment.month != null && payment.year != null)
          buildInfoRow(
            'Période:',
            '${getMonthName(payment.month!)} ${payment.year}',
          ),
        buildInfoRow('Montant:', '${formatCurrency(payment.amount)} FCFA'),
        buildInfoRow(
          'Méthode de paiement:',
          getMethodLabel(payment.paymentMethod),
        ),
        if (!asInvoice)
          buildInfoRow('Statut:', _getStatusLabel(payment.status)),
      ],
    );
  }

  pw.Widget _buildPaymentDetails(Payment payment) {
    final itemLabel = _getPaymentItemLabel(payment);
    return PaymentPdfHelpers.buildBorderedContainer(
      children: [
        PaymentPdfHelpers.buildSectionTitle('Détails du Paiement'),
        pw.SizedBox(height: 12),
        _buildPaymentTable(itemLabel, payment.amount),
        pw.SizedBox(height: 12),
        PaymentPdfHelpers.buildTotalTable(
          label: 'TOTAL',
          amount: '${formatCurrency(payment.amount)} FCFA',
        ),
        if (payment.notes != null && payment.notes!.isNotEmpty)
          _buildNotesSection(payment.notes!),
      ],
    );
  }

  String _getPaymentItemLabel(Payment payment) {
    if (payment.paymentType == PaymentType.deposit) {
      return 'Montant de la caution';
    }
    if (payment.month != null && payment.year != null) {
      return 'Loyer ${getMonthName(payment.month!)} ${payment.year}';
    }
    return 'Loyer mensuel';
  }

  pw.Widget _buildPaymentTable(String label, int amount) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                '${formatCurrency(amount)} FCFA',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildNotesSection(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 12),
        pw.Text(
          'Notes:',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(notes, style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  String _getStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Payé';
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.overdue:
        return 'En retard';
      case PaymentStatus.cancelled:
        return 'Annulé';
    }
  }
}
