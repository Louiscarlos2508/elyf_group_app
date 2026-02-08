import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/entities/tour.dart';
import '../../widgets/tour_detail/closure_step_content.dart';
import '../../widgets/tour_detail/collection_step_content.dart';
import '../../widgets/tour_detail/return_step_content.dart';
import '../../widgets/tour_detail/tour_detail_header.dart';
import '../../widgets/tour_detail/transport_step_content.dart';
import '../../widgets/tour_detail/tour_workflow_stepper.dart';

/// Écran de détail d'un tour d'approvisionnement.
class TourDetailScreen extends ConsumerStatefulWidget {
  final String tourId;
  final String enterpriseId;

  const TourDetailScreen({
    super.key,
    required this.tourId,
    required this.enterpriseId,
  });

  @override
  ConsumerState<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends ConsumerState<TourDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final tourAsync = ref.watch(tourProvider(widget.tourId));

    return tourAsync.when(
      data: (tour) {
        if (tour == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Détails du tour')),
            body: const Center(
              child: Text('Tour non trouvé'),
            ),
          );
        }

        return _buildTourDetail(tour, theme, isMobile);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Détails du tour')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, stackTrace) {
        developer.log(
          'Erreur lors du chargement du tour',
          name: 'TourDetailScreen',
          error: e,
          stackTrace: stackTrace,
        );
        return Scaffold(
          appBar: AppBar(title: const Text('Détails du tour')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Une erreur inattendue s\'est produite',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Veuillez réessayer',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    // Invalider le provider pour réessayer
                    ref.invalidate(tourProvider(widget.tourId));
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTourDetail(Tour tour, ThemeData theme, bool isMobile) {

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête avec bouton retour
          Container(
            padding: ResponsiveHelper.adaptivePadding(context),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(child: TourDetailHeader(tour: tour)),
              ],
            ),
          ),
          // Workflow stepper
          TourWorkflowStepper(tour: tour),
          // Contenu selon l'étape
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey('tour_content_${tour.id}_${tour.status}'),
              padding: ResponsiveHelper.adaptivePadding(context),
              child: _buildStepContent(tour, theme, isMobile),
            ),
          ),
          // Boutons d'action
          if (tour.status != TourStatus.closure)
            Container(
              padding: ResponsiveHelper.adaptivePadding(context),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: tour.status == TourStatus.collection
                  ? // Pour l'étape collecte, seulement le bouton "Passer au transport"
                    Align(
                      alignment: Alignment.centerRight,
                      child: IntrinsicWidth(
                        child: FilledButton(
                          style: GazButtonStyles.filledPrimary(context),
                          onPressed: () async {
                            try {
                              final controller = ref.read(
                                tourControllerProvider,
                              );
                              await controller.moveToNextStep(tour.id);
                              if (mounted && context.mounted) {
                                developer.log(
                                  'Changement d\'étape effectué, rafraîchissement des providers',
                                  name: 'TourDetailScreen',
                                );
                                // Invalider les providers pour rafraîchir
                                ref.invalidate(
                                  toursProvider((
                                    enterpriseId: widget.enterpriseId,
                                    status: null,
                                  )),
                                );
                                // Forcer le rechargement du tour en utilisant refresh
                                final _ = ref.refresh(tourProvider(tour.id));
                              }
                            } catch (e) {
                              if (!mounted || !context.mounted) return;
                              NotificationService.showError(
                                context,
                                'Erreur: $e',
                              );
                            }
                          },
                          child: Text(
                            _getNextStepButtonLabel(tour.status),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    )
                  : // Pour les autres étapes, deux boutons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: OutlinedButton(
                            style: GazButtonStyles.outlined(context),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Retour',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: FilledButton(
                            style: GazButtonStyles.filledPrimary(context),
                            onPressed: () async {
                              try {
                                final controller = ref.read(
                                  tourControllerProvider,
                                );
                                await controller.moveToNextStep(tour.id);
                                if (mounted) {
                                  ref.invalidate(
                                    toursProvider((
                                      enterpriseId: widget.enterpriseId,
                                      status: null,
                                    )),
                                  );
                                  // Invalider le provider du tour pour forcer le rafraîchissement
                                  ref.invalidate(tourProvider(tour.id));
                                }
                              } catch (e) {
                                if (!mounted || !context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: $e'),
                                    backgroundColor: theme.colorScheme.error,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              _getNextStepButtonLabel(tour.status),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent(Tour tour, ThemeData theme, bool isMobile) {
    switch (tour.status) {
      case TourStatus.collection:
        return CollectionStepContent(
          tour: tour,
          enterpriseId: widget.enterpriseId,
        );
      case TourStatus.transport:
        return TransportStepContent(
          tour: tour,
          enterpriseId: widget.enterpriseId,
        );
      case TourStatus.return_:
        // Si toutes les collections sont payées, afficher l'écran de clôture
        // Sinon, afficher l'écran de retour pour les paiements
        if (tour.areAllCollectionsPaid) {
          return ClosureStepContent(
            tour: tour,
            enterpriseId: widget.enterpriseId,
            isMobile: isMobile,
          );
        } else {
          return ReturnStepContent(
            tour: tour,
            enterpriseId: widget.enterpriseId,
          );
        }
      case TourStatus.closure:
        return ClosureStepContent(
          tour: tour,
          enterpriseId: widget.enterpriseId,
          isMobile: isMobile,
        );
      case TourStatus.cancelled:
        return Center(
          child: Text('Tour annulé', style: theme.textTheme.titleLarge),
        );
    }
  }

  String _getNextStepButtonLabel(TourStatus status) {
    switch (status) {
      case TourStatus.collection:
        return 'Passer au transport';
      case TourStatus.transport:
        return 'Passer au retour';
      case TourStatus.return_:
        return 'Passer à la clôture';
      case TourStatus.closure:
      case TourStatus.cancelled:
        return '';
    }
  }
}
