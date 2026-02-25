import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../domain/entities/tour.dart';

/// En-tête du détail du tour avec carte de statut.
class TourDetailHeader extends StatelessWidget {
  const TourDetailHeader({super.key, required this.tour});

  final Tour tour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(context, tour.status);
    final isClosed = tour.status == TourStatus.closed;
    final isCancelled = tour.status == TourStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.1),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isClosed ? Icons.verified : isCancelled ? Icons.cancel : Icons.local_shipping,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détails du tour',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE dd MMMM yyyy', 'fr').format(tour.tourDate),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: tour.status, color: statusColor),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeaderMetric(
                label: 'Chargés',
                value: '${tour.totalBottlesToLoad}',
                icon: Icons.upload_rounded,
                color: theme.colorScheme.primary,
              ),
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              _HeaderMetric(
                label: 'Reçus',
                value: '${tour.totalBottlesReceived}',
                icon: Icons.download_rounded,
                color: Colors.green,
              ),
              if (tour.gasPurchaseCost != null) ...[
                 Container(
                  width: 1,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                _HeaderMetric(
                  label: 'Coût gaz',
                  value: NumberFormat.currency(
                    symbol: 'F',
                    decimalDigits: 0,
                    locale: 'fr',
                  ).format(tour.gasPurchaseCost),
                  icon: Icons.payments_outlined,
                  color: theme.colorScheme.secondary,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, TourStatus status) {
    final theme = Theme.of(context);
    switch (status) {
      case TourStatus.closed:
        return AppColors.success;
      case TourStatus.cancelled:
        return theme.colorScheme.error;
      case TourStatus.open:
        return theme.colorScheme.primary;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});
  final TourStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
