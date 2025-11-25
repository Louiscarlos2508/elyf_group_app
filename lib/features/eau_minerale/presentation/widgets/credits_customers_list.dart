import 'package:flutter/material.dart';

import '../../domain/entities/customer_credit.dart';
import '../../domain/repositories/customer_repository.dart' show CustomerSummary;
import 'customer_credit_card.dart';

/// Customers list section for credits screen.
class CreditsCustomersList extends StatelessWidget {
  const CreditsCustomersList({
    super.key,
    required this.customers,
    required this.getMockCredits,
    required this.onHistoryTap,
    required this.onPaymentTap,
  });

  final List<CustomerSummary> customers;
  final List<CustomerCredit> Function(CustomerSummary) getMockCredits;
  final void Function(String customerId) onHistoryTap;
  final void Function(String customerId) onPaymentTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customersWithCredit = customers.where((c) => c.totalCredit > 0).toList();
    
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
        ...customersWithCredit.map((customer) {
          final credits = getMockCredits(customer);
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
        if (customersWithCredit.isEmpty)
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

