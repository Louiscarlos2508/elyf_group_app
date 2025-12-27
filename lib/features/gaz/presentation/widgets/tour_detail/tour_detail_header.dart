import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/tour.dart';

/// En-tête du détail du tour avec carte de statut.
class TourDetailHeader extends StatelessWidget {
  const TourDetailHeader({
    super.key,
    required this.tour,
  });

  final Tour tour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = tour.status == TourStatus.closure
        ? 'Terminé'
        : tour.status == TourStatus.collection
            ? 'Préparation'
            : 'En cours';
    final statusBgColor = tour.status == TourStatus.closure
        ? const Color(0xFFECEEF2)
        : tour.status == TourStatus.collection
            ? const Color(0xFFECEEF2)
            : const Color(0xFF030213);
    final statusTextColor = tour.status == TourStatus.closure
        ? const Color(0xFF030213)
        : tour.status == TourStatus.collection
            ? const Color(0xFF030213)
            : Colors.white;

    return Container(
      padding: const EdgeInsets.all(25.285),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF).withValues(alpha: 0.5),
        border: Border.all(
          color: const Color(0xFFBEDBFF),
          width: 1.305,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_shipping,
                      size: 20,
                      color: Color(0xFF0A0A0A),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tour du ${DateFormat('dd/MM/yyyy').format(tour.tourDate)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${tour.totalBottlesToLoad} bouteilles collectées',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF4A5565),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• Étape: ${tour.status.label}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF155DFC),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9.305,
              vertical: 3.305,
            ),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: statusTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

