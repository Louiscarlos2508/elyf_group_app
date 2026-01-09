import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

/// Net balance card for reports screen.
class ReportNetBalanceCard extends StatelessWidget {
  const ReportNetBalanceCard({
    super.key,
    required this.stats,
  });

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final cashInTotal = stats['cashInTotal'] as int? ?? 0;
    final cashOutTotal = stats['cashOutTotal'] as int? ?? 0;
    final netBalance = cashInTotal - cashOutTotal;

    return Container(
      padding: const EdgeInsets.fromLTRB(25.219, 25.219, 1.219, 1.219),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border.all(
          color: const Color(0xFFB9F8CF),
          width: 1.219,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Column(
          children: [
            const Text(
              'Solde net de la période',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Color(0xFF4A5565),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${netBalance >= 0 ? '+' : ''}${CurrencyFormatter.formatFCFA(netBalance)}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.normal,
                color: Color(0xFF00A63E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dépôts - Retraits = ${CurrencyFormatter.formatFCFA(cashInTotal)} - ${CurrencyFormatter.formatFCFA(cashOutTotal)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Color(0xFF4A5565),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

