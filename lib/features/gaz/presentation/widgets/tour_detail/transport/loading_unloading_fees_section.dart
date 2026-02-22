import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../../../shared/utils/currency_formatter.dart';
import '../../../../domain/entities/tour.dart';

/// Section des frais de chargement et déchargement.
class LoadingUnloadingFeesSection extends StatelessWidget {
  const LoadingUnloadingFeesSection({super.key, required this.tour});

  final Tour tour;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frais de chargement
        Container(
          padding: const EdgeInsets.fromLTRB(11.99, 11.99, 11.99, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Frais de chargement',
                    style: TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
                  ),
                  Text(
                    '${tour.totalBottlesToLoad} × ${tour.loadingFeePerBottle.toStringAsFixed(0)} F',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatDouble(tour.totalLoadingFees),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFE7000B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Frais de déchargement
        Container(
          padding: const EdgeInsets.fromLTRB(11.99, 11.99, 11.99, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Frais de déchargement',
                    style: TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
                  ),
                  Text(
                    '${tour.totalBottlesReceived} × ${tour.unloadingFeePerBottle.toStringAsFixed(0)} F',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatDouble(tour.totalUnloadingFees),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFE7000B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Divider
        Container(height: 1, color: Colors.black.withValues(alpha: 0.1)),
        const SizedBox(height: 8),
        // Total chargement/déchargement
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11.99, vertical: 0),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total chargement/déchargement',
                style: TextStyle(fontSize: 16, color: Color(0xFF0A0A0A)),
              ),
              Text(
                CurrencyFormatter.formatDouble(
                  tour.totalLoadingFees + tour.totalUnloadingFees,
                ),
                style: const TextStyle(fontSize: 18, color: Color(0xFFE7000B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
