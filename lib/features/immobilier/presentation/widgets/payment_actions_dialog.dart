import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import '../../../../core/pdf/unified_payment_pdf_service.dart';
import '../../application/providers.dart';
import '../../domain/entities/payment.dart';
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
  bool _isPrinting = false;
  bool _isGeneratingPdf = false;

  Future<void> _printReceipt() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    try {
      final controller = ref.read(paymentControllerProvider);
      final success = await controller.printReceipt(widget.payment.id);
      
      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          NotificationService.showSuccess(
            context,
            'Reçu imprimé avec succès',
          );
        } else {
          NotificationService.showError(
            context,
            'Erreur lors de l\'impression. Vérifiez que l\'imprimante est connectée.',
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
          FilledButton.icon(
            onPressed: _isPrinting ? null : _printReceipt,
            icon: _isPrinting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print),
            label: const Text('Imprimer le reçu'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
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
