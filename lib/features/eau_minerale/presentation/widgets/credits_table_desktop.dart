import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/shared/utils/date_formatter.dart';
import '../../domain/entities/customer_credit.dart';
import '../../domain/repositories/customer_repository.dart' show CustomerSummary;

class CreditsTableDesktop extends StatelessWidget {
  const CreditsTableDesktop({
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

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),    // Client
          1: FlexColumnWidth(1.5),  // Contact
          2: FlexColumnWidth(1.5),  // Total Crédit
          3: FlexColumnWidth(1),    // Ventes
          4: FlexColumnWidth(2),    // Actions
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            children: [
              _buildHeaderCell(context, 'Client'),
              _buildHeaderCell(context, 'Contact'),
              _buildHeaderCell(context, 'Total Crédit'),
              _buildHeaderCell(context, 'Ancienneté'),
              _buildHeaderCell(context, 'Actions'),
            ],
          ),
          ...customers.map((customer) {
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

            return TableRow(
              children: [
                _buildDataCellText(
                  context,
                  customer.name.isEmpty ? 'Client Inconnu' : customer.name,
                  isBold: customer.name.isNotEmpty,
                  isItalic: customer.name.isEmpty,
                ),
                _buildDataCellText(
                  context,
                  customer.phone.isEmpty ? 'Aucun numéro' : customer.phone,
                  isItalic: customer.phone.isEmpty,
                ),
                _buildDataCellWidget(
                  context,
                  Text(
                    CurrencyFormatter.formatFCFA(totalCredit),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDataCellWidget(
                  context,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${credits.length} vente${credits.length > 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (oldestCreditDate != null)
                        Text(
                          'Dès le ${DateFormatter.formatDate(oldestCreditDate)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildDataCellWidget(
                  context,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => onPaymentTap(customer.id),
                        icon: const Icon(Icons.attach_money, size: 18),
                        label: const Text('Encaisser'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        tooltip: 'Plus d\'options',
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
                              title: Text('Historique complet'),
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDataCellText(
    BuildContext context,
    String text, {
    bool isBold = false,
    bool isItalic = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isBold ? FontWeight.bold : null,
          fontStyle: isItalic ? FontStyle.italic : null,
          color: isItalic ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6) : null,
        ),
      ),
    );
  }

  Widget _buildDataCellWidget(BuildContext context, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: content,
    );
  }
}
