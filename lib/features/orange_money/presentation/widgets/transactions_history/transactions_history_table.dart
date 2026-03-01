import 'package:flutter/material.dart';
import '../../../domain/entities/transaction.dart';
import 'transactions_table_cells.dart';

/// Widget pour afficher le tableau des transactions.
/// Utilise un SingleChildScrollView horizontal pour éviter les débordements sur mobile.
class TransactionsHistoryTable extends StatelessWidget {
  const TransactionsHistoryTable({super.key, required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5E5E5), width: 1.219),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 900, // Largeur minimale pour contenir toutes les colonnes
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table Header
              _TransactionsTableHeader(),
              // Table Rows
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB), // Léger fond pour l'en-tête
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1.219),
        ),
      ),
      child: Row(
        children: [
          _TableHeaderCell('Date & Heure', width: 140),
          _TableHeaderCell('Type', width: 100),
          _TableHeaderCell('Client', width: 200),
          _TableHeaderCell('Téléphone', width: 120),
          _TableHeaderCell("Pièce d'identité", width: 180),
          _TableHeaderCell('Montant', width: 160, isRightAligned: true),
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
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4A5565),
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
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1.219),
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
