import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../../../core/logging/app_logger.dart';
import '../../../../domain/entities/tour.dart';
import '../../../widgets/tour_card.dart';
import '../tour_detail_screen.dart';

/// Onglet affichant une liste de tours.
class ToursListTab extends ConsumerWidget {
  const ToursListTab({
    super.key,
    required this.enterpriseId,
    required this.tourStatus,
    required this.title,
    required this.onNewTour,
    this.emptyStateMessage,
  });

  final String enterpriseId;
  final TourStatus? tourStatus;
  final String title;
  final VoidCallback onNewTour;
  final String? emptyStateMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final toursAsync = ref.watch(
      toursProvider((enterpriseId: enterpriseId, status: tourStatus)),
    );

    return toursAsync.when(
      data: (tours) {
        // Si tourStatus est null, filtrer les tours non clôturés
        final filteredTours = tourStatus == null
            ? tours.where((t) => t.status != TourStatus.closure).toList()
            : tours;

        return Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1.3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 30),
              Expanded(
                child: filteredTours.isEmpty
                    ? SingleChildScrollView(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                tourStatus == null
                                    ? Icons.local_shipping_outlined
                                    : Icons.history,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                tourStatus == null
                                    ? 'Aucun tour en cours'
                                    : (emptyStateMessage ?? 'Aucun tour dans l\'historique'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (tourStatus == null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Accédez à l\'historique ou créez-en un nouveau',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredTours.length,
                        itemBuilder: (context, index) {
                          final tour = filteredTours[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TourCard(
                              tour: tour,
                              onTap: () {
                                // Logger l'ID du tour pour le débogage
                                AppLogger.debug(
                                  'Ouverture du tour avec ID: ${tour.id}',
                                  name: 'gaz.tours',
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => TourDetailScreen(
                                      tourId: tour.id,
                                      enterpriseId: enterpriseId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.1),
            width: 1.3,
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.1),
            width: 1.3,
          ),
        ),
        child: Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
