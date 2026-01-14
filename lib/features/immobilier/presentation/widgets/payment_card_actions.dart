import 'package:flutter/material.dart';

import '../../domain/entities/payment.dart';
import 'payment_actions_dialog.dart';

/// Widget pour les boutons d'action d'une carte de paiement.
class PaymentCardActions extends StatelessWidget {
  const PaymentCardActions({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.print, size: 20),
          tooltip: 'Imprimer',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => PaymentActionsDialog(payment: payment),
            );
          },
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf, size: 20),
          tooltip: 'Télécharger PDF',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => PaymentActionsDialog(payment: payment),
            );
          },
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
