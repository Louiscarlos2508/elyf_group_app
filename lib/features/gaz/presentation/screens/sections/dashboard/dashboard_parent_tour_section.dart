import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';
import '../../../../../../shared/utils/currency_formatter.dart';
import '../../../../domain/entities/tour.dart';
import '../../../../application/providers.dart';

/// Section displaying recent tours for parent enterprise.
class DashboardParentTourSection extends ConsumerWidget {
  const DashboardParentTourSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final toursAsync = ref.watch(gazYearlyToursProvider);

    return toursAsync.when(
      data: (tours) {
        // Only show last 5 tours
        final recentTours = tours.take(5).toList();

        return ElyfCard(
          isGlass: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.local_shipping_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Activité des Tours",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to Logistics Tab (index 3: Journal du Camion)
                      ref.read(gazNavigationIndexProvider.notifier).setIndex(3);
                    },
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recentTours.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 48,
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun tour récent',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentTours.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tour = recentTours[index];
                    return _TourListItem(tour: tour);
                  },
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => const SizedBox.shrink(), // Silent error on dashboard
    );
  }
}

class _TourListItem extends StatelessWidget {
  const _TourListItem({required this.tour});

  final Tour tour;

  Color _getStatusColor(BuildContext context, TourStatus status) {
    switch (status) {
      case TourStatus.open:
      case TourStatus.collecting:
      case TourStatus.recharging:
      case TourStatus.delivering:
      case TourStatus.closing:
        return const Color(0xFF3B82F6); // Blue
      case TourStatus.closed:
        return const Color(0xFF10B981); // Emerald
      case TourStatus.cancelled:
        return Theme.of(context).colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(context, tour.status);
    final dateFormat = DateFormat('dd MMM yyyy', 'fr');
    final dateStr = dateFormat.format(tour.tourDate);
    
    final isClosed = tour.status == TourStatus.closed;
    final totalBottles = isClosed ? tour.totalBottlesReceived : tour.totalBottlesToLoad;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Left side: Status & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalBottles bouteilles ${isClosed ? 'reçues' : 'à charger'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Right side: Cost
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatDouble(tour.totalExpenses),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isClosed ? const Color(0xFF16A34A) : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tour.status.label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
