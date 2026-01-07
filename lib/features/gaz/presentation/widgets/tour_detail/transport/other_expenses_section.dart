import 'package:flutter/material.dart';

import '../../../../../shared.dart';
import '../../../../domain/entities/tour.dart';

/// Section des autres dépenses du trajet.
class OtherExpensesSection extends StatelessWidget {
  const OtherExpensesSection({
    super.key,
    required this.tour,
  });

  final Tour tour;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Autres dépenses du trajet',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF364153),
          ),
        ),
        const SizedBox(height: 8),
        // Liste des dépenses
        if (tour.transportExpenses.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Aucune dépense enregistrée',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6A7282),
              ),
            ),
          )
        else ...[
          ...tour.transportExpenses.map((expense) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 11.99,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    expense.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatDouble(expense.amount),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFE7000B),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          // Divider
          Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 8),
          // Total général des dépenses
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total général des dépenses',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0A0A0A),
                ),
              ),
              Text(
                CurrencyFormatter.formatDouble(
                  tour.totalLoadingFees +
                      tour.totalUnloadingFees +
                      tour.totalTransportExpenses,
                ),
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFFE7000B),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

