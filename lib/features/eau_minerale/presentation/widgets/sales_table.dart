import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

import '../../domain/entities/sale.dart';
import 'sales_table_desktop.dart';
import 'sales_table_mobile.dart';

/// Table widget for displaying sales list.
class SalesTable extends StatelessWidget {
  const SalesTable({super.key, required this.sales, this.onActionTap});

  final List<Sale> sales;
  final void Function(Sale sale, String action)? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (sales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        child: Text(
          'Aucune vente enregistrée',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        if (isWide) {
          return SalesTableDesktop(
            sales: sales,
            formatCurrency: CurrencyFormatter.formatFCFA,
            onActionTap: onActionTap,
          );
        } else {
          return SalesTableMobile(
            sales: sales,
            formatCurrency: CurrencyFormatter.formatFCFA,
            onActionTap: onActionTap,
          );
        }
      },
    );
  }
}
