import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import '../../../domain/entities/transaction.dart';

/// Widget displaying transaction information in the new customer form.
class TransactionInfoCard extends StatelessWidget {
  const TransactionInfoCard({
    super.key,
    required this.phoneNumber,
    required this.amount,
    required this.type,
  });

  final String phoneNumber;
  final int amount;
  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17.219),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.219,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Téléphone',
                style: TextStyle(fontSize: 16, color: Color(0xFF4A5565)),
              ),
              Text(
                phoneNumber,
                style: const TextStyle(fontSize: 16, color: Color(0xFF101828)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Montant',
                style: TextStyle(fontSize: 16, color: Color(0xFF4A5565)),
              ),
              Text(
                CurrencyFormatter.formatFCFA(amount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF101828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Type',
                style: TextStyle(fontSize: 16, color: Color(0xFF4A5565)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: type == TransactionType.cashIn
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.transparent, width: 1.219),
                ),
                child: Text(
                  type == TransactionType.cashIn ? 'Dépôt' : 'Retrait',
                  style: TextStyle(
                    fontSize: 12,
                    color: type == TransactionType.cashIn
                        ? const Color(0xFF016630)
                        : const Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
