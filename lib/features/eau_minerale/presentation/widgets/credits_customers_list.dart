import 'package:flutter/material.dart';

import '../../domain/entities/customer_credit.dart';
import '../../domain/services/credit_calculation_service.dart';
import '../../domain/repositories/customer_repository.dart'
    show CustomerSummary;
import 'credits_table_desktop.dart';
import 'credits_list_mobile.dart';

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
      final totalCreditFromCredits =
          CreditCalculationService.calculateTotalCredit(credits);
      
      // Garder seulement ceux qui ont un crédit restant > 0
      return totalCreditFromCredits > 0;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suivi par Client',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Regroupement des crédits par client',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (customersWithRealCredits.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun crédit en cours',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              if (isWide) {
                return CreditsTableDesktop(
                  customers: customersWithRealCredits,
                  getCredits: getCredits,
                  onHistoryTap: onHistoryTap,
                  onPaymentTap: onPaymentTap,
                );
              } else {
                return CreditsListMobile(
                  customers: customersWithRealCredits,
                  getCredits: getCredits,
                  onHistoryTap: onHistoryTap,
                  onPaymentTap: onPaymentTap,
                );
              }
            },
          ),
      ],
    );
  }
}
