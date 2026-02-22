import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/core/logging/app_logger.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/entities/tour.dart';
import '../../widgets/tour_detail/closure_step_content.dart';
import '../../widgets/tour_detail/loading_step_content.dart';
import '../../widgets/tour_detail/reception_step_content.dart';
import '../../widgets/tour_detail/tour_detail_header.dart';

/// Écran de détail d'un tour d'approvisionnement fournisseur.
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
        AppLogger.error(
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
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
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
          
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey('tour_content_${tour.id}_${tour.status}'),
              padding: ResponsiveHelper.adaptivePadding(context),
              child: _buildMainContent(tour, theme, isMobile),
            ),
          ),
          
          // Action button (Closure)
          if (tour.status == TourStatus.open)
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
              child: FilledButton(
                style: GazButtonStyles.filledPrimary(context).copyWith(
                  minimumSize: WidgetStateProperty.all(const Size.fromHeight(56)),
                ),
                onPressed: tour.fullBottlesReceived.isEmpty ? null : () => _showClosureDialog(tour),
                child: const Text('Clôturer le tour d\'approvisionnement'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(Tour tour, ThemeData theme, bool isMobile) {
    if (tour.status == TourStatus.closed) {
      return ClosureStepContent(
        tour: tour,
        enterpriseId: widget.enterpriseId,
        isMobile: isMobile,
      );
    }

    if (tour.status == TourStatus.cancelled) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Icon(Icons.cancel_outlined, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Tour annulé', style: theme.textTheme.titleLarge),
          ],
        ),
      );
    }

    return Column(
      children: [
        LoadingStepContent(
          tour: tour,
          enterpriseId: widget.enterpriseId,
        ),
        const SizedBox(height: 16),
        ReceptionStepContent(
          tour: tour,
          enterpriseId: widget.enterpriseId,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _showClosureDialog(Tour tour) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clôturer le tour'),
        content: const Text(
          'Voulez-vous clôturer ce tour ? Cela mettra à jour les stocks de l\'entreprise.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer la clôture'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final controller = ref.read(tourControllerProvider);
        // Assuming current user ID is available or needed
        // For now using a placeholder or getting it from a provider if available
        await controller.closeTour(tour.id, 'user_placeholder');
        
        if (mounted) {
          NotificationService.showSuccess(context, 'Tour clôturé avec succès');
          ref.invalidate(tourProvider(tour.id));
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showError(context, 'Erreur lors de la clôture: $e');
        }
      }
    }
  }
}
