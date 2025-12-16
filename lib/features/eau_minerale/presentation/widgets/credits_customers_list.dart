import 'package:flutter/material.dart';

import '../../domain/entities/customer_credit.dart';
import '../../domain/repositories/customer_repository.dart' show CustomerSummary;
import 'customer_credit_card.dart';

/// Customers list section for credits screen.
class CreditsCustomersList extends StatelessWidget {
  const CreditsCustomersList({
    super.key,
    required this.customers,
    required this.getCredits,
    required this.onHistoryTap,
    required this.onPaymentTap,
  });

  final List<CustomerSummary> customers;
  final List<CustomerCredit> Function(CustomerSummary) getCredits;
  final void Function(String customerId) onHistoryTap;
  final void Function(String customerId) onPaymentTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Filtrer les clients qui ont réellement des crédits avec un montant restant > 0
    final customersWithRealCredits = customers.where((customer) {
      final credits = getCredits(customer);
      final totalCreditFromCredits = credits.fold<int>(
        0,
        (sum, credit) => sum + credit.remainingAmount,
      );
      // Garder seulement ceux qui ont un crédit restant > 0
      return totalCreditFromCredits > 0;
    }).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suivi par Client',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Regroupement des crédits par client avec historique des paiements',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...customersWithRealCredits.map((customer) {
          final credits = getCredits(customer);
          // Calculer le crédit total réel à partir des crédits détaillés
          final totalCreditFromCredits = credits.fold<int>(
            0,
            (sum, credit) => sum + credit.remainingAmount,
          );
          // Ne pas afficher si le client n'a pas de crédit réel (le widget le gère aussi)
          if (totalCreditFromCredits <= 0) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CustomerCreditCard(
              customer: customer,
              credits: credits,
              onHistoryTap: () => onHistoryTap(customer.id),
              onPaymentTap: () => onPaymentTap(customer.id),
            ),
          );
        }),
        if (customersWithRealCredits.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Text(
                'Aucun crédit en cours',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

