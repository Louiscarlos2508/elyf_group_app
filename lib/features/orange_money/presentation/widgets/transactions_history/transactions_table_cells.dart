import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../domain/entities/transaction.dart';
import 'transactions_history_helpers.dart';

/// Cellule de date et heure.
class TransactionDateCell extends StatelessWidget {
  const TransactionDateCell({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SizedBox(
      width: 120,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(date),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Cellule de type de transaction.
class TransactionTypeCell extends StatelessWidget {
  const TransactionTypeCell({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCashIn = transaction.isCashIn;
    
    return SizedBox(
      width: 80,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCashIn 
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4) 
                : theme.colorScheme.errorContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCashIn 
                  ? theme.colorScheme.primary.withValues(alpha: 0.1) 
                  : theme.colorScheme.error.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCashIn ? Icons.add_circle_outline : Icons.remove_circle_outline,
                size: 14,
                color: isCashIn ? theme.colorScheme.primary : theme.colorScheme.error,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isCashIn ? 'Dépôt' : 'Retrait',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCashIn ? theme.colorScheme.primary : theme.colorScheme.error,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cellule de client.
class TransactionClientCell extends StatelessWidget {
  const TransactionClientCell({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 140,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Text(
          transaction.customerName ?? transaction.phoneNumber,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Cellule de téléphone.
class TransactionPhoneCell extends StatelessWidget {
  const TransactionPhoneCell({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 90,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Text(
          transaction.phoneNumber.replaceAll('+226', ''),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Cellule de pièce d'identité.
class TransactionIdCardCell extends StatelessWidget {
  const TransactionIdCardCell({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SizedBox(
      width: 130,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.badge_outlined, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  transaction.idType ?? 'CNIB',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  transaction.idNumber ?? '-',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (transaction.idIssueDate != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(transaction.idIssueDate!),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary.withValues(alpha: 0.8),
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Cellule de village/commune.
class TransactionTownCell extends StatelessWidget {
  const TransactionTownCell({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 110,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                transaction.town ?? '-',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cellule de référence de transaction.
class TransactionReferenceCell extends StatelessWidget {
  const TransactionReferenceCell({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reference = transaction.reference ?? transaction.id;
    
    return SizedBox(
      width: 100,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            reference,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Cellule de montant.
class TransactionAmountCell extends StatelessWidget {
  const TransactionAmountCell({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCashIn = transaction.isCashIn;

    return SizedBox(
      width: 120,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Text(
          TransactionsHistoryHelpers.formatAmount(
            transaction.amount,
            isCashIn,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isCashIn 
                ? theme.colorScheme.primary 
                : theme.colorScheme.error,
          ),
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
