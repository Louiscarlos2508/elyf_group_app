import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../../domain/entities/employee.dart';
import '../../domain/entities/salary_payment.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
/// Dialog pour générer et afficher un reçu de paiement de salaire.
class SalaryReceiptDialog extends StatelessWidget {
  const SalaryReceiptDialog({
    super.key,
    required this.employee,
    required this.payment,
  });

  final Employee employee;
  final SalaryPayment payment;

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) + ' FCFA';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _generateAndPrintReceipt(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'REÇU DE PAIEMENT DE SALAIRE',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Employé: ${employee.name}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              if (employee.position != null)
                pw.Text(
                  'Poste: ${employee.position}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Période:',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    payment.period,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Date de paiement:',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    _formatDate(payment.date),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Montant:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _formatCurrency(payment.amount),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Notes:',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  payment.notes!,
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
              pw.Spacer(),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Signature du bénéficiaire',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 40),
                      if (payment.signature != null)
                        pw.Image(
                          pw.MemoryImage(payment.signature!),
                          width: 150,
                          height: 60,
                        )
                      else
                        pw.Container(
                          width: 150,
                          height: 60,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(),
                          ),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Signature de l\'employeur',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Container(
                        width: 150,
                        height: 60,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Sauvegarder le PDF
    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/receipt_${payment.id}.pdf');
    await file.writeAsBytes(bytes);
    
    // Ouvrir le fichier
    await OpenFile.open(file.path);
    
    if (context.mounted) {
      NotificationService.showInfo(context, 'Reçu généré: ${file.path}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Reçu de paiement'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (employee.position != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      employee.position!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ReceiptRow(
              label: 'Période',
              value: payment.period,
            ),
            _ReceiptRow(
              label: 'Date de paiement',
              value: _formatDate(payment.date),
            ),
            _ReceiptRow(
              label: 'Montant',
              value: _formatCurrency(payment.amount),
              isAmount: true,
            ),
            if (payment.notes != null && payment.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                payment.notes!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (payment.aSignature) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Signature du bénéficiaire',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Image.memory(
                      payment.signature!,
                      height: 80,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        FilledButton.icon(
          onPressed: () => _generateAndPrintReceipt(context),
          icon: const Icon(Icons.print),
          label: const Text('Imprimer'),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isAmount = false,
  });

  final String label;
  final String value;
  final bool isAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
              color: isAmount ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
