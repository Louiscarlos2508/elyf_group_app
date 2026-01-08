import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/liquidity_checkpoint.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
/// Section affichant l'activité journalière (dépôts, retraits, transactions).
class LiquidityDailyActivitySection extends StatelessWidget {
  const LiquidityDailyActivitySection({
    super.key,
    required this.checkpoint,
    required this.stats,
  });

  final LiquidityCheckpoint? checkpoint;
  final Map<String, dynamic> stats;

  String _formatWithCommas(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final deposits = stats['deposits'] as int? ?? 0;
    final withdrawals = stats['withdrawals'] as int? ?? 0;
    final transactionCount = stats['transactionCount'] as int? ?? 0;

    final morningCash = checkpoint?.morningCashAmount ?? 0;
    final morningSim = checkpoint?.morningSimAmount ?? 0;

    return Column(
      children: [
        // Activité de la journée
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 Activité de la journée',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dépôts',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4A5565),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${_formatWithCommas(deposits)} F',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF00A63E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Retraits',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4A5565),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '-${_formatWithCommas(withdrawals)} F',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFFE7000B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transactions',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4A5565),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transactionCount.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF101828),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Solde disponible (basé sur le pointage du matin)
        if (checkpoint != null &&
            (checkpoint!.morningCashAmount != null ||
                checkpoint!.morningSimAmount != null))
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💰 Solde disponible',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 12),
                if (checkpoint!.morningCashAmount != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cash:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4A5565),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatFCFA(checkpoint!.morningCashAmount!),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF101828),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (checkpoint!.morningSimAmount != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SIM:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4A5565),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatFCFA(checkpoint!.morningSimAmount!),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF155DFC),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101828),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatFCFA(morningCash + morningSim),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

