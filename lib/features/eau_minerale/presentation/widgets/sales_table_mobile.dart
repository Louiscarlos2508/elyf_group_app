import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';

import '../../domain/entities/sale.dart';
import 'sales_table_helpers.dart';

/// Mobile list view for sales.
class SalesTableMobile extends StatelessWidget {
  const SalesTableMobile({
    super.key,
    required this.sales,
    required this.formatCurrency,
    this.onActionTap,
  });

  final List<Sale> sales;
  final String Function(int) formatCurrency;
  final void Function(Sale sale, String action)? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sales.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sale = sales[index];
        return ElyfCard(
          isGlass: true,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sale.productName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SalesTableHelpers.buildStatusChip(context, sale),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Qté: ', style: theme.textTheme.bodySmall),
                  Text(
                    sale.quantity.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Client: ', style: theme.textTheme.bodySmall),
                  Expanded(
                    child: Text(
                      sale.customerName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: ${formatCurrency(sale.totalPrice)} CFA',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'Payé: ${formatCurrency(sale.amountPaid)} CFA',
                        style: theme.textTheme.bodySmall,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: sale.remainingAmount > 0
                              ? theme.colorScheme.errorContainer
                              : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Reste: ${formatCurrency(sale.remainingAmount)} CFA',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: sale.remainingAmount > 0
                                ? theme.colorScheme.onErrorContainer
                                : theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SalesTableHelpers.buildActionButtons(
                    context,
                    sale,
                    onActionTap,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
