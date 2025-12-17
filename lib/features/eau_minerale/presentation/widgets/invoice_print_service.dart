import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';

import '../../../../core/printing/sunmi_v3_service.dart';
import '../../domain/entities/sale.dart';

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
    final content = _generateSaleReceipt(sale);
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
    final content = _generateCreditPaymentReceipt(
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
        build: (context) => _buildSalePdfContent(sale),
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
        build: (context) => _buildCreditPaymentPdfContent(
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

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} FCFA';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _centerText(String text, [int width = 32]) {
    if (text.length >= width) return text.substring(0, width);
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  String _truncateId(String id) {
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(0, 8).toUpperCase();
  }

  /// Génère le contenu texte pour l'imprimante thermique (vente).
  String _generateSaleReceipt(Sale sale) {
    final buffer = StringBuffer();

    // Entête compact
    buffer.write('================================\n');
    buffer.write('      EAU MINERALE ELYF\n');
    buffer.write('================================\n');
    buffer.write('FACTURE: ${_truncateId(sale.id)}\n');
    buffer.write('Date: ${_formatDate(sale.date)} ${_formatTime(sale.date)}\n');
    buffer.write('--------------------------------\n');
    buffer.write('Client: ${sale.customerName}\n');
    if (sale.customerPhone.isNotEmpty) {
      buffer.write('Tel: ${sale.customerPhone}\n');
    }
    buffer.write('--------------------------------\n');
    buffer.write('Article: ${sale.productName}\n');
    buffer.write('Qte: ${sale.quantity} x ${_formatCurrency(sale.unitPrice)}\n');
    buffer.write('--------------------------------\n');
    buffer.write('TOTAL: ${_formatCurrency(sale.totalPrice)}\n');
    buffer.write('Paye: ${_formatCurrency(sale.amountPaid)}\n');

    if (sale.cashAmount > 0) {
      buffer.write('  Cash: ${_formatCurrency(sale.cashAmount)}\n');
    }
    if (sale.orangeMoneyAmount > 0) {
      buffer.write('  OM: ${_formatCurrency(sale.orangeMoneyAmount)}\n');
    }

    if (sale.remainingAmount > 0) {
      buffer.write('CREDIT: ${_formatCurrency(sale.remainingAmount)}\n');
    }

    buffer.write('================================\n');
    buffer.write('        Merci!\n');

    return buffer.toString();
  }

  /// Génère le contenu texte pour l'imprimante thermique (paiement crédit).
  String _generateCreditPaymentReceipt({
    required String customerName,
    required Sale sale,
    required int paymentAmount,
    required int remainingAfterPayment,
    String? notes,
  }) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final newAmountPaid = sale.amountPaid + paymentAmount;

    // Entête compact
    buffer.write('================================\n');
    buffer.write('      EAU MINERALE ELYF\n');
    buffer.write('      RECU DE PAIEMENT\n');
    buffer.write('================================\n');
    buffer.write('Date: ${_formatDate(now)} ${_formatTime(now)}\n');
    buffer.write('Client: $customerName\n');
    buffer.write('--------------------------------\n');
    buffer.write('Ref vente: ${_formatDate(sale.date)}\n');
    buffer.write('${sale.productName} x${sale.quantity}\n');
    buffer.write('Total vente: ${_formatCurrency(sale.totalPrice)}\n');
    buffer.write('--------------------------------\n');
    buffer.write('Deja paye: ${_formatCurrency(sale.amountPaid)}\n');
    buffer.write('PAIEMENT: ${_formatCurrency(paymentAmount)}\n');
    buffer.write('Total paye: ${_formatCurrency(newAmountPaid)}\n');
    if (remainingAfterPayment > 0) {
      buffer.write('Reste: ${_formatCurrency(remainingAfterPayment)}\n');
    } else {
      buffer.write('*** SOLDE ***\n');
    }

    if (notes != null && notes.isNotEmpty) {
      buffer.write('Note: $notes\n');
    }

    buffer.write('================================\n');
    buffer.write('        Merci!\n');

    return buffer.toString();
  }

  /// Construit le contenu PDF pour une facture de vente.
  pw.Widget _buildSalePdfContent(Sale sale) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Center(
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
                'FACTURE DE VENTE',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 10),

        // Info facture
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('N°: ${_truncateId(sale.id)}'),
            pw.Text('Date: ${_formatDate(sale.date)} ${_formatTime(sale.date)}'),
          ],
        ),
        pw.SizedBox(height: 20),

        // Client
        pw.Container(
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
              pw.Text('Nom: ${sale.customerName}'),
              if (sale.customerPhone.isNotEmpty)
                pw.Text('Téléphone: ${sale.customerPhone}'),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Détails
        pw.Table(
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
                  child: pw.Text(_formatCurrency(sale.unitPrice)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(_formatCurrency(sale.totalPrice)),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // Totaux
        pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('Total: '),
                  pw.Text(
                    _formatCurrency(sale.totalPrice),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('Payé: '),
                  pw.Text(_formatCurrency(sale.amountPaid)),
                ],
              ),
              if (sale.cashAmount > 0)
                pw.Text('  - Cash: ${_formatCurrency(sale.cashAmount)}'),
              if (sale.orangeMoneyAmount > 0)
                pw.Text('  - Orange Money: ${_formatCurrency(sale.orangeMoneyAmount)}'),
              if (sale.remainingAmount > 0) ...[
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'CRÉDIT: ${_formatCurrency(sale.remainingAmount)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        pw.Spacer(),

        // Footer
        pw.Center(
          child: pw.Text(
            'Merci pour votre achat !',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// Construit le contenu PDF pour un reçu de paiement crédit.
  pw.Widget _buildCreditPaymentPdfContent({
    required String customerName,
    required Sale sale,
    required int paymentAmount,
    required int remainingAfterPayment,
    String? notes,
  }) {
    final now = DateTime.now();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Center(
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
                'REÇU DE PAIEMENT',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 10),

        // Date
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Date: ${_formatDate(now)}'),
            pw.Text('Heure: ${_formatTime(now)}'),
          ],
        ),
        pw.SizedBox(height: 20),

        // Client
        pw.Container(
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
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Vente référence
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'VENTE DE RÉFÉRENCE',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Date: ${_formatDate(sale.date)}'),
              pw.Text('Produit: ${sale.productName}'),
              pw.Text('Quantité: ${sale.quantity}'),
              pw.Text('Total vente: ${_formatCurrency(sale.totalPrice)}'),
              pw.Text('Déjà payé avant: ${_formatCurrency(sale.amountPaid)}'),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Paiement
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.green100,
            border: pw.Border.all(color: PdfColors.green),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'PAIEMENT AUJOURD\'HUI',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                _formatCurrency(paymentAmount),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Total payé: ${_formatCurrency(sale.amountPaid + paymentAmount)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Reste à payer
        if (remainingAfterPayment > 0)
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Reste à payer:'),
                pw.Text(
                  _formatCurrency(remainingAfterPayment),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange900,
                  ),
                ),
              ],
            ),
          )
        else
          pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.green100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'SOLDÉ',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                ),
              ),
            ),
          ),

        if (notes != null && notes.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text('Note: $notes'),
        ],

        pw.Spacer(),

        // Footer
        pw.Center(
          child: pw.Text(
            'Merci !',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Widget bouton d'impression pour les factures eau minérale.
class EauMineralePrintButton extends StatefulWidget {
  const EauMineralePrintButton({
    super.key,
    required this.sale,
    this.compact = false,
  });

  final Sale sale;
  final bool compact;

  @override
  State<EauMineralePrintButton> createState() => _EauMineralePrintButtonState();
}

class _EauMineralePrintButtonState extends State<EauMineralePrintButton> {
  bool _isPrinting = false;
  bool _isSunmiAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkSunmi();
  }

  Future<void> _checkSunmi() async {
    final available = await EauMineraleInvoiceService.instance.isSunmiAvailable();
    if (mounted) {
      setState(() => _isSunmiAvailable = available);
    }
  }

  Future<void> _showPrintOptions() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Générer PDF'),
              subtitle: const Text('Créer un fichier PDF'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            if (_isSunmiAvailable)
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Imprimer (Sunmi)'),
                subtitle: const Text('Imprimante thermique'),
                onTap: () => Navigator.pop(context, 'sunmi'),
              ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _isPrinting = true);

    try {
      if (result == 'pdf') {
        final file = await EauMineraleInvoiceService.instance
            .generateSalePdf(widget.sale);
        if (!mounted) return;
        await OpenFile.open(file.path);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF généré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result == 'sunmi') {
        final success = await EauMineraleInvoiceService.instance
            .printSaleInvoice(widget.sale);
        if (!mounted) return;
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Facture imprimée' : 'Erreur d\'impression',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return IconButton(
        onPressed: _isPrinting ? null : _showPrintOptions,
        icon: _isPrinting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.print),
        tooltip: 'Imprimer la facture',
      );
    }

    return FilledButton.tonal(
      onPressed: _isPrinting ? null : _showPrintOptions,
      child: _isPrinting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.print, size: 18),
                SizedBox(width: 8),
                Text('Imprimer'),
              ],
            ),
    );
  }
}
