import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/tour.dart';

/// Carte affichant les informations principales d'un tour.
class TourCard extends StatelessWidget {
  const TourCard({super.key, required this.tour, required this.onTap});

  final Tour tour;
  final VoidCallback onTap;

  Color _getStatusColor(BuildContext context, TourStatus status) {
    switch (status) {
      case TourStatus.collection:
        return const Color(0xFF3B82F6); // Blue
      case TourStatus.transport:
        return const Color(0xFFF59E0B); // Amber
      case TourStatus.return_:
        return const Color(0xFF8B5CF6); // Violet
      case TourStatus.closure:
        return const Color(0xFF10B981); // Emerald
      case TourStatus.cancelled:
        return Theme.of(context).colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(context, tour.status);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateStr = dateFormat.format(tour.tourDate);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_shipping, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tour du $dateStr',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tour.totalBottlesToLoad} collectées • Étape: ${tour.status.label}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  tour.status == TourStatus.closure ? 'Terminé' : 'En cours',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
