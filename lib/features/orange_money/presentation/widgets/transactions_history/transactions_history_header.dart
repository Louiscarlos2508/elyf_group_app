import 'package:flutter/material.dart';

/// Header de l'écran d'historique des transactions.
class TransactionsHistoryHeader extends StatelessWidget {
  const TransactionsHistoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique des transactions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF101828),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Consultez vos dernières transactions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF4A5565),
            height: 1.43,
          ),
        ),
      ],
    );
  }
}
