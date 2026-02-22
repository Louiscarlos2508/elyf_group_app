import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/tour.dart';

/// En-tête du détail du tour avec carte de statut.
class TourDetailHeader extends StatelessWidget {
  const TourDetailHeader({super.key, required this.tour});

  final Tour tour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = tour.status == TourStatus.closed
        ? 'Terminé'
        : tour.status == TourStatus.open
        ? 'En cours'
        : 'Annulé';
    final statusBgColor = tour.status == TourStatus.closed
        ? const Color(0xFFECEEF2)
        : tour.status == TourStatus.open
        ? const Color(0xFF030213)
        : const Color(0xFFFEE2E2);
    final statusTextColor = tour.status == TourStatus.closed
        ? const Color(0xFF030213)
        : tour.status == TourStatus.open
        ? Colors.white
        : const Color(0xFF991B1B);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isVerySmall = constraints.maxWidth < 250;

        return Container(
          padding: EdgeInsets.all(isVerySmall ? 12 : 16), // Reduced padding on small screens
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF).withValues(alpha: 0.5),
            border: Border.all(color: const Color(0xFFBEDBFF), width: 1.305),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (!isVerySmall) ...[
                          const Icon(
                            Icons.local_shipping,
                            size: 18,
                            color: Color(0xFF0A0A0A),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            'Tour du ${DateFormat('dd/MM/yyyy').format(tour.tourDate)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isVerySmall ? 14 : 16,
                              color: const Color(0xFF0A0A0A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${tour.totalBottlesToLoad} chargés',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: isVerySmall ? 10 : 12,
                              color: const Color(0xFF4A5565),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isVerySmall) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '• ${tour.status.label}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: const Color(0xFF155DFC),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: isVerySmall ? 10 : 12,
                    fontWeight: FontWeight.w500,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
