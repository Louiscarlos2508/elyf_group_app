import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/collection.dart';

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
    final paymentStatus = collection.isPaymentComplete ? 'Payé' : 'En attente';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    collection.clientPhone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
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
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  paymentStatus,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: theme.colorScheme.onSurface,
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
            // totalPrice calculé pour usage futur si nécessaire

            return Container(
              margin: const EdgeInsets.only(bottom: 7.993),
              padding: const EdgeInsets.fromLTRB(7.993, 7.993, 7.993, 0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${weight}kg',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  ),
                  Text(
                    '$qty × ${numberFormat.format(pricePerBottle.toInt())} F',
                    style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  ),
                ],
              ),
            );
          }),
          // Divider
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
          // Montant dû
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Montant dû:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${numberFormat.format(collection.amountDue.toInt())} FCFA',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
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
                  color: const Color(0xFF10B981), // Emerald
                ),
              ),
              Text(
                '${numberFormat.format(collection.amountPaid.toInt())} FCFA',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF10B981), // Emerald
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
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${numberFormat.format(collection.remainingAmount.toInt())} FCFA',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
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
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
