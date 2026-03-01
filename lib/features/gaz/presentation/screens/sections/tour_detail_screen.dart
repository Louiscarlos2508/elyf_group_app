import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/auth/providers.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart' hide currentUserIdProvider;
import '../../../domain/entities/tour.dart';
import '../../widgets/tour_detail/closure_step_content.dart';
import '../../widgets/tour_detail/loading_step_content.dart';
import '../../widgets/tour_detail/reception_step_content.dart';
import '../../widgets/tour_detail/tour_detail_header.dart';
import '../../widgets/tour_detail/transport_step_content.dart';

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
  /// Stocke l'index de l'étape en cours de modification (0: Chargement, 1: Transport, 2: Réception)
  int? _editingStepIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tourAsync = ref.watch(tourProvider(widget.tourId));

    return tourAsync.when(
      data: (tour) {
        if (tour == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Détails du tour')),
            body: const Center(child: Text('Tour non trouvé')),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(context, tour),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TourDetailHeader(tour: tour),
                      const SizedBox(height: 24),
                      _buildSteps(context, tour),
                    ],
                  ),
                ),
              ),
              if (tour.status == TourStatus.open && _editingStepIndex == null) 
                _buildBottomBar(context, tour),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Chargement...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(child: Text('Erreur: $e')),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Tour tour) {
    return ElyfAppBar(
      title: 'Gestion du Tour',
      subtitle: 'APPROVISIONNEMENT GAZ',
      module: EnterpriseModule.gaz,
      actions: [
        if (tour.status == TourStatus.open)
          IconButton(
            onPressed: () => _showCancelDialog(tour),
            icon: const Icon(Icons.cancel_outlined, color: Colors.white),
            tooltip: 'Annuler le tour',
          ),
      ],
    );
  }

  Widget _buildSteps(BuildContext context, Tour tour) {
    if (tour.status == TourStatus.cancelled) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.cancel_rounded, size: 80, color: Colors.red.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'Ce tour a été annulé',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );
    }

    if (tour.status == TourStatus.closed) {
      return ClosureStepContent(
        tour: tour,
        enterpriseId: widget.enterpriseId,
        isMobile: true,
      );
    }

    return Column(
      children: [
        _StepCard(
          title: '1. Chargement des vides',
          subtitle: 'Déclarer les bouteilles envoyées au fournisseur',
          icon: Icons.upload_rounded,
          isCompleted: tour.totalBottlesToLoad > 0,
          isEditing: _editingStepIndex == 0,
          canEdit: tour.status == TourStatus.open,
          onEdit: () => setState(() => _editingStepIndex = 0),
          child: LoadingStepContent(
            key: const ValueKey('step_loading'),
            tour: tour,
            enterpriseId: widget.enterpriseId,
            onSaved: () => setState(() => _editingStepIndex = null),
          ),
        ),
        const SizedBox(height: 16),
        _StepCard(
          title: '2. Transport & Frais',
          subtitle: 'Gérer les frais de route et de manutention',
          icon: Icons.local_shipping_outlined,
          isCompleted: tour.transportCompletedDate != null,
          isEnabled: tour.totalBottlesToLoad > 0,
          isEditing: _editingStepIndex == 1,
          canEdit: tour.status == TourStatus.open,
          onEdit: () => setState(() => _editingStepIndex = 1),
          child: TransportStepContent(
            key: const ValueKey('step_transport'),
            tour: tour,
            enterpriseId: widget.enterpriseId,
            onSaved: () => setState(() => _editingStepIndex = null),
          ),
        ),
        const SizedBox(height: 16),
        _StepCard(
          title: '3. Réception des pleines',
          subtitle: 'Enregistrer les bouteilles reçues et le coût gaz',
          icon: Icons.download_rounded,
          isCompleted: tour.fullBottlesReceived.isNotEmpty,
          isEnabled: tour.transportCompletedDate != null,
          isEditing: _editingStepIndex == 2,
          canEdit: tour.status == TourStatus.open,
          onEdit: () => setState(() => _editingStepIndex = 2),
          child: ReceptionStepContent(
            key: const ValueKey('step_reception'),
            tour: tour,
            enterpriseId: widget.enterpriseId,
            onSaved: () => setState(() => _editingStepIndex = null),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, Tour tour) {
    final theme = Theme.of(context);
    final isReadyToClose = tour.fullBottlesReceived.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: FilledButton.icon(
          onPressed: isReadyToClose ? () => _showClosureDialog(tour) : null,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('CLÔTURER LE TOUR'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(Tour tour) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le tour ?'),
        content: const Text(
          'Toutes les saisies actuelles seront perdues. Cette action est irréversible.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non, garder'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final userId = ref.read(currentUserIdProvider);
        if (userId == null) throw Exception('Utilisateur non connecté');
        
        await ref.read(tourControllerProvider).cancelTour(tour.id, userId);
        if (mounted) {
          NotificationService.showSuccess(context, 'Tour annulé');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) NotificationService.showError(context, 'Erreur: $e');
      }
    }
  }

  Future<void> _showClosureDialog(Tour tour) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clôturer le tour'),
        content: const Text(
          'Voulez-vous clôturer ce tour ? Les stocks seront mis à jour définitivement.'
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
        final userId = ref.read(currentUserIdProvider);
        if (userId == null) throw Exception('Utilisateur non connecté');

        await ref.read(tourControllerProvider).closeTour(tour.id, userId);
        if (mounted) {
          NotificationService.showSuccess(context, 'Tour clôturé avec succès');
          ref.invalidate(tourProvider(tour.id));
        }
      } catch (e) {
        if (mounted) NotificationService.showError(context, 'Erreur lors de la clôture: $e');
      }
    }
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.isCompleted = false,
    this.isEnabled = true,
    this.isEditing = false,
    this.canEdit = false,
    this.onEdit,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final bool isCompleted;
  final bool isEnabled;
  final bool isEditing;
  final bool canEdit;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCompleted ? Colors.green : (isEnabled ? theme.colorScheme.primary : theme.colorScheme.outline);
    final showContent = (isEnabled && !isCompleted) || isEditing;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted && !isEditing && canEdit)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Modifier'),
                    )
                  else if (isCompleted)
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                ],
              ),
            ),
            if (showContent) ...[
              const Divider(height: 1),
              Padding(padding: const EdgeInsets.all(16), child: child),
            ],
          ],
        ),
      ),
    );
  }
}
