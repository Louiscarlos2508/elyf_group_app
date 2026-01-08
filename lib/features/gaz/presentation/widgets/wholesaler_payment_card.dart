import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/collection.dart';
import 'package:elyf_groupe_app/shared.dart';

/// Carte de paiement pour un grossiste dans la section retour.
class WholesalerPaymentCard extends StatelessWidget {
  const WholesalerPaymentCard({
    super.key,
    required this.collection,
    required this.onPaymentPressed,
  });

  final Collection collection;
  final VoidCallback onPaymentPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,###', 'fr_FR');

    // Calculer les totaux par poids
    final bottlesByWeight = <int, int>{};
    for (final entry in collection.emptyBottles.entries) {
      final weight = entry.key;
      final qty = entry.value;
      final leakQty = collection.leaks[weight] ?? 0;
      final validQty = qty - leakQty;
      if (validQty > 0) {
        bottlesByWeight[weight] = validQty;
      }
    }

    // Statut du paiement selon le design Figma
    final paymentStatus = collection.isPaymentComplete
        ? 'Payé'
        : 'En attente';
    final statusColor = const Color(0xFF0A0A0A);

    return Container(
      padding: const EdgeInsets.fromLTRB(17.292, 17.292, 17.292, 1.305),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.305,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec nom et statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.clientName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    collection.clientPhone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF4A5565),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9.305,
                  vertical: 3.305,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.1),
                    width: 1.305,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  paymentStatus,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11.99),
          // Détails des bouteilles
          ...bottlesByWeight.entries.map((entry) {
            final weight = entry.key;
            final qty = entry.value;
            final pricePerBottle = collection.getUnitPriceForWeight(weight);
            final totalPrice = qty * pricePerBottle;

            return Container(
              margin: const EdgeInsets.only(bottom: 7.993),
              padding: const EdgeInsets.fromLTRB(7.993, 7.993, 7.993, 0),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${weight}kg',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  Text(
                    '$qty × ${numberFormat.format(pricePerBottle.toInt())} F',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF4A5565),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Divider
          Container(
            margin: const EdgeInsets.symmetric(vertical: 7.993),
            height: 0.999,
            color: Colors.black.withValues(alpha: 0.1),
          ),
          // Montant dû
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Montant dû:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF4A5565),
                ),
              ),
              Text(
                '${numberFormat.format(collection.amountDue.toInt())} FCFA',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7.993),
          // Déjà payé
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Déjà payé:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF00A63E),
                ),
              ),
              Text(
                '${numberFormat.format(collection.amountPaid.toInt())} FCFA',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF00A63E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7.993),
          // Reste
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reste:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
              Text(
                '${numberFormat.format(collection.remainingAmount.toInt())} FCFA',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFFE7000B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11.99),
          // Bouton d'enregistrement de paiement
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF030213),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: const Size(0, 32),
              ),
              onPressed: collection.isPaymentComplete ? null : onPaymentPressed,
              child: Text(
                collection.isPaymentComplete
                    ? 'Paiement complet'
                    : 'Enregistrer paiement',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

