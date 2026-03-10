import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/shared.dart';
import '../../../../../domain/entities/expense.dart';
import '../../../../../domain/entities/tour.dart';


class UnifiedExpenseItem extends StatelessWidget {
  final GazExpense? expense;
  final Tour? tour;
  final VoidCallback onTap;

  const UnifiedExpenseItem({
    super.key,
    this.expense,
    this.tour,
    required this.onTap,
  }) : assert(expense != null || tour != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTour = tour != null;
    
    final title = isTour 
        ? 'Dépense Tournée - ${tour!.supplierName ?? "Fournisseur"}'
        : expense!.description;
    
    final amount = isTour ? tour!.totalExpenses : expense!.amount;
    final date = isTour ? tour!.tourDate : expense!.date;
    final category = isTour ? 'Tournée' : expense!.category.label;
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: (isTour ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
        child: Icon(
          isTour ? Icons.local_shipping_outlined : Icons.receipt_long_outlined,
          color: isTour ? Colors.blue : Colors.orange,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$category • ${DateFormat('dd/MM/yyyy').format(date)}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        CurrencyFormatter.formatDouble(amount),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }
}
