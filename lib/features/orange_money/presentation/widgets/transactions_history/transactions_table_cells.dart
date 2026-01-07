import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction.dart';
import 'transactions_history_helpers.dart';

/// Cellule de date et heure.
class TransactionDateCell extends StatelessWidget {
  const TransactionDateCell({
    super.key,
    required this.date,
  });

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return SizedBox(
      width: 124.683,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 16,
              color: Color(0xFF4A5565),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF101828),
                  ),
                ),
                Text(
                  timeFormat.format(date),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF4A5565),
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
  const TransactionTypeCell({
    super.key,
    required this.transaction,
  });

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 95.065,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: transaction.isCashIn
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.transparent,
              width: 1.219,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                transaction.isCashIn ? Icons.check : Icons.arrow_upward,
                size: 12,
                color: transaction.isCashIn
                    ? const Color(0xFF016630)
                    : const Color(0xFF991B1B),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  transaction.isCashIn ? 'Dépôt' : 'Retrait',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: transaction.isCashIn
                        ? const Color(0xFF016630)
                        : const Color(0xFF991B1B),
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
  const TransactionClientCell({
    super.key,
    required this.transaction,
  });

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 259.976,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          transaction.customerName ?? transaction.phoneNumber,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF101828),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Cellule de téléphone.
class TransactionPhoneCell extends StatelessWidget {
  const TransactionPhoneCell({
    super.key,
    required this.transaction,
  });

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100.541,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          transaction.phoneNumber.replaceAll('+226', ''),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF4A5565),
          ),
        ),
      ),
    );
  }
}

/// Cellule de pièce d'identité.
class TransactionIdCardCell extends StatelessWidget {
  const TransactionIdCardCell({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 175.474,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(
              Icons.credit_card,
              size: 16,
              color: Color(0xFF4A5565),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CNI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF101828),
                  ),
                ),
                Text(
                  '-', // Pas de données pour l'instant
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF4A5565),
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

/// Cellule de montant.
class TransactionAmountCell extends StatelessWidget {
  const TransactionAmountCell({
    super.key,
    required this.transaction,
  });

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          TransactionsHistoryHelpers.formatAmount(
            transaction.amount,
            transaction.isCashIn,
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: transaction.isCashIn
                ? const Color(0xFF008236)
                : const Color(0xFFDC2626),
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }
}

