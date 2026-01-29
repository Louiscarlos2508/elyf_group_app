import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/shared/utils/date_formatter.dart';
import '../../domain/entities/customer_credit.dart';
import '../../domain/repositories/customer_repository.dart' show CustomerSummary;

class CreditsListMobile extends StatelessWidget {
  const CreditsListMobile({
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        final credits = getCredits(customer);
        final totalCredit = credits.fold<int>(
          0,
          (sum, credit) => sum + credit.remainingAmount,
        );

        // Trouver la dette la plus ancienne
        final oldestCreditDate = credits.isEmpty
            ? null
            : credits
                .map((c) => c.date)
                .reduce((a, b) => a.isBefore(b) ? a : b);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name.isEmpty ? 'Client Inconnu' : customer.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: customer.name.isEmpty ? FontWeight.normal : FontWeight.bold,
                              fontStyle: customer.name.isEmpty ? FontStyle.italic : null,
                              color: customer.name.isEmpty 
                                ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6) 
                                : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 14, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                customer.phone.isEmpty ? 'Aucun numéro' : customer.phone,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontStyle: customer.phone.isEmpty ? FontStyle.italic : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz),
                      tooltip: 'Actions',
                      onSelected: (value) {
                        if (value == 'history') {
                          onHistoryTap(customer.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'history',
                          child: ListTile(
                            leading: Icon(Icons.history, size: 20),
                            title: Text('Historique'),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solde dû',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatFCFA(totalCredit),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${credits.length} vente${credits.length > 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (oldestCreditDate != null)
                          Text(
                            'Dès le ${DateFormatter.formatDate(oldestCreditDate)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => onPaymentTap(customer.id),
                    icon: const Icon(Icons.attach_money, size: 18),
                    label: const Text('Encaisser le paiement'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
