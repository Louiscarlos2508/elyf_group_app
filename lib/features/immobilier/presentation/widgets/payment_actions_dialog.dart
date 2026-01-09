import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../../../../core/pdf/unified_payment_pdf_service.dart';
import '../../../../core/printing/sunmi_v3_service.dart';
import '../../../../core/printing/templates/payment_receipt_template.dart';
import '../../domain/entities/payment.dart';
import 'payment_form_helpers.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
/// Dialog pour les actions sur un paiement (impression, PDF).
class PaymentActionsDialog extends StatefulWidget {
  const PaymentActionsDialog({
    super.key,
    required this.payment,
  });

  final Payment payment;

  @override
  State<PaymentActionsDialog> createState() => _PaymentActionsDialogState();
}

class _PaymentActionsDialogState extends State<PaymentActionsDialog> {
  bool _isPrinting = false;
  bool _isGeneratingPdf = false;
  bool _isSunmiAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkSunmiAvailability();
  }

  Future<void> _checkSunmiAvailability() async {
    final isSunmi = await SunmiV3Service.instance.isSunmiDevice;
    if (mounted) {
      setState(() => _isSunmiAvailable = isSunmi);
    }
  }

  Future<void> _printReceipt() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    try {
      final contract = widget.payment.contract;
      final property = contract?.property;
      final tenant = contract?.tenant;

      final receiptNumber = widget.payment.receiptNumber ?? widget.payment.id;
      final paymentDate = PaymentFormHelpers.formatDate(widget.payment.paymentDate);
      final amount = PaymentFormHelpers.formatCurrency(widget.payment.amount);
      final paymentMethod = PaymentFormHelpers.getMethodLabel(widget.payment.paymentMethod);
      final tenantName = tenant?.fullName ?? 'N/A';
      final propertyAddress = property != null
          ? '${property.address}, ${property.city}'
          : 'N/A';
      final period = widget.payment.month != null && widget.payment.year != null
          ? '${PaymentFormHelpers.getMonthName(widget.payment.month!)} ${widget.payment.year}'
          : null;

      final content = PaymentReceiptTemplate.generateReceipt(
        receiptNumber: receiptNumber,
        paymentDate: paymentDate,
        amount: amount,
        paymentMethod: paymentMethod,
        tenantName: tenantName,
        propertyAddress: propertyAddress,
        period: period,
        notes: widget.payment.notes,
      );

      final success = await SunmiV3Service.instance.printPaymentReceipt(content);
      if (mounted) {
        Navigator.of(context).pop();
        if (success ) {
        NotificationService.showSuccess(context, 
              success
                  ? 'Reçu imprimé avec succès'
                  : 'Erreur lors de l\'impression',
            );
      } else {
        NotificationService.showError(context, 
              success
                  ? 'Reçu imprimé avec succès'
                  : 'Erreur lors de l\'impression',
            );
      }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);

    try {
      final pdfService = UnifiedPaymentPdfService.instance;
      final file = await pdfService.generateDocument(
        payment: widget.payment,
        asInvoice: false, // Reçu pour les actions
      );

      if (mounted) {
        Navigator.of(context).pop();
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done && mounted) {
          NotificationService.showInfo(context, 'PDF généré: ${file.path}');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        NotificationService.showError(context, 'Erreur lors de la génération PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Actions sur le paiement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSunmiAvailable) ...[
            FilledButton.icon(
              onPressed: _isPrinting ? null : _printReceipt,
              icon: _isPrinting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print),
              label: const Text('Imprimer sur Sunmi'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: _isGeneratingPdf ? null : _downloadPdf,
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: const Text('Télécharger PDF'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

