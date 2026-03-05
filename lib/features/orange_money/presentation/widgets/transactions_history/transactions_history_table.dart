import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import '../../../domain/entities/transaction.dart';
import 'transactions_table_cells.dart';

/// Tableau affichant l'historique des transactions.
class TransactionsHistoryTable extends StatelessWidget {
  const TransactionsHistoryTable({super.key, required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ElyfCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 890, // Réduit de 1130 pour minimiser le scroll horizontal
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table Header
              _TransactionsTableHeader(),
              // Table Rows
              if (transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Text('Aucune transaction trouvée'),
                  ),
                )
              else
                ...transactions.map(
                  (transaction) => _TransactionRow(transaction: transaction),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête du tableau des transactions.
class _TransactionsTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: const Row(
        children: [
          _TableHeaderCell('Date & Heure', width: 120),
          _TableHeaderCell('Type', width: 80),
          _TableHeaderCell('Référence', width: 100),
          _TableHeaderCell('Client', width: 140),
          _TableHeaderCell('Tél.', width: 90),
          _TableHeaderCell("ID Client", width: 130),
          _TableHeaderCell('Village/Ville', width: 110),
          _TableHeaderCell('Montant', width: 120, isRightAligned: true),
        ],
      ),
    );
  }
}

/// Cellule d'en-tête du tableau.
class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell(this.text, {required this.width, this.isRightAligned = false});

  final String text;
  final double width;
  final bool isRightAligned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
        textAlign: isRightAligned ? TextAlign.right : TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Ligne de transaction dans le tableau.
class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          TransactionDateCell(date: transaction.date),
          TransactionTypeCell(transaction: transaction),
          TransactionReferenceCell(transaction: transaction),
          TransactionClientCell(transaction: transaction),
          TransactionPhoneCell(transaction: transaction),
          TransactionIdCardCell(transaction: transaction),
          TransactionTownCell(transaction: transaction),
          TransactionAmountCell(transaction: transaction),
        ],
      ),
    );
  }
}
