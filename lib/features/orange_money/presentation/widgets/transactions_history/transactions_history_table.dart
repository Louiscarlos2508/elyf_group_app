import 'package:flutter/material.dart';
import '../../../domain/entities/transaction.dart';
import 'transactions_table_cells.dart';

/// Widget pour afficher le tableau des transactions.
class TransactionsHistoryTable extends StatelessWidget {
  const TransactionsHistoryTable({
    super.key,
    required this.transactions,
  });

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFFE5E5E5),
          width: 1.219,
        ),
      ),
      child: Column(
        children: [
          // Table Header
          _TransactionsTableHeader(),
          // Table Rows
          ...transactions.map(
            (transaction) => _TransactionRow(transaction: transaction),
          ),
        ],
      ),
    );
  }
}

/// En-tête du tableau des transactions.
class _TransactionsTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E5E5),
            width: 1.219,
          ),
        ),
      ),
      child: Row(
        children: [
          _TableHeaderCell('Date & Heure', width: 124.683),
          _TableHeaderCell('Type', width: 95.065),
          _TableHeaderCell('Client', width: 259.976),
          _TableHeaderCell('Téléphone', width: 100.541),
          _TableHeaderCell("Pièce d'identité", width: 175.474),
          Expanded(
            child: _TableHeaderCell('Montant', isRightAligned: true),
          ),
        ],
      ),
    );
  }
}

/// Cellule d'en-tête du tableau.
class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell(
    this.text, {
    this.width,
    this.isRightAligned = false,
  });

  final String text;
  final double? width;
  final bool isRightAligned;

  @override
  Widget build(BuildContext context) {
    Widget cell = Container(
      width: width,
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF0A0A0A),
        ),
        textAlign: isRightAligned ? TextAlign.right : TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );

    if (width == null) {
      return cell;
    }
    return SizedBox(width: width, child: cell);
  }
}

/// Ligne de transaction dans le tableau.
class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E5E5),
            width: 1.219,
          ),
        ),
      ),
      child: Row(
        children: [
          TransactionDateCell(date: transaction.date),
          TransactionTypeCell(transaction: transaction),
          TransactionClientCell(transaction: transaction),
          TransactionPhoneCell(transaction: transaction),
          const TransactionIdCardCell(),
          TransactionAmountCell(transaction: transaction),
        ],
      ),
    );
  }
}

