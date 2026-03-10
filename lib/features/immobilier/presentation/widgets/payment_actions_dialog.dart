import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import '../../../../core/pdf/unified_payment_pdf_service.dart';
import '../../application/providers.dart';
import '../../domain/entities/payment.dart';
import 'immobilier_print_receipt_button.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';

/// Dialog pour les actions sur un paiement (impression, PDF).
class PaymentActionsDialog extends ConsumerStatefulWidget {
  const PaymentActionsDialog({super.key, required this.payment});

  final Payment payment;

  @override
  ConsumerState<PaymentActionsDialog> createState() => _PaymentActionsDialogState();
}

class _PaymentActionsDialogState extends ConsumerState<PaymentActionsDialog> {
  bool _isGeneratingPdf = false;

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
        NotificationService.showError(
          context,
          'Erreur lors de la génération PDF: $e',
        );
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
          ImmobilierPrintReceiptButton(
            payment: widget.payment,
            onPrintSuccess: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 12),
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
