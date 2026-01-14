import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import '../../../domain/entities/sale.dart';
import '../invoice_print/invoice_print_service.dart'
    show EauMineraleInvoiceService;

/// Helper class for credit payment print operations.
/// Extracted from CreditPaymentDialog to reduce file size.
class CreditPaymentPrintHelper {
  CreditPaymentPrintHelper._();

  /// Show print option dialog and handle print action.
  static Future<void> showPrintOption({
    required BuildContext context,
    required String customerName,
    required Sale sale,
    required int paymentAmount,
    required int remainingAfterPayment,
    required String? notes,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Imprimer le reçu ?'),
        content: const Text(
          'Voulez-vous imprimer ou générer un PDF du reçu de paiement ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'skip'),
            child: const Text('Non merci'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'pdf'),
            child: const Text('PDF'),
          ),
          FutureBuilder<bool>(
            future: EauMineraleInvoiceService.instance.isSunmiAvailable(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return FilledButton(
                  onPressed: () => Navigator.pop(context, 'sunmi'),
                  child: const Text('Imprimer'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );

    if (result == null || result == 'skip' || !context.mounted) return;

    try {
      if (result == 'pdf') {
        final file = await EauMineraleInvoiceService.instance
            .generateCreditPaymentPdf(
              customerName: customerName,
              sale: sale,
              paymentAmount: paymentAmount,
              remainingAfterPayment: remainingAfterPayment,
              notes: notes,
            );
        if (!context.mounted) return;
        await OpenFile.open(file.path);
      } else if (result == 'sunmi') {
        await EauMineraleInvoiceService.instance.printCreditPaymentReceipt(
          customerName: customerName,
          sale: sale,
          paymentAmount: paymentAmount,
          remainingAfterPayment: remainingAfterPayment,
          notes: notes,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      NotificationService.showWarning(context, 'Erreur d\'impression: $e');
    }
  }
}
