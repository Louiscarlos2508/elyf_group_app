import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

import '../../domain/entities/sale.dart';
import 'sales_table_desktop.dart';
import 'sales_table_mobile.dart';

/// Table widget for displaying sales list.
class SalesTable extends StatelessWidget {
  const SalesTable({
    super.key,
    required this.sales,
    this.onActionTap,
  });

  final List<Sale> sales;
  final void Function(Sale sale, String action)? onActionTap;
    
    final buffer = StringBuffer();
    final reversed = amountStr.split('').reversed.join();
    
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(reversed[i]);
    }
    
    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todaySales = sales.where((sale) {
      final saleDate = DateTime(
        sale.date.year,
        sale.date.month,
        sale.date.day,
      );
      return saleDate.isAtSameMomentAs(todayStart);
    }).toList();

    if (todaySales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        child: Text(
          'Aucune vente aujourd\'hui',
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
            sales: todaySales,
            formatCurrency: _formatCurrency,
            onActionTap: onActionTap,
          );
        } else {
          return SalesTableMobile(
            sales: todaySales,
            formatCurrency: _formatCurrency,
            onActionTap: onActionTap,
          );
        }
      },
    );
  }

}

