import '../entities/tour.dart';
import '../repositories/tour_repository.dart';

/// Service de gestion des tours avec logique métier.
class TourService {
  const TourService({required this.tourRepository});

  final TourRepository tourRepository;

  /// Valide qu'on peut passer au statut suivant.
  /// Retourne un message d'erreur si la transition n'est pas valide, sinon null.
  String? validateStatusTransition(
    TourStatus currentStatus,
    TourStatus newStatus,
  ) {
    // Définir les transitions autorisées
    final allowedTransitions = <TourStatus, List<TourStatus>>{
      TourStatus.collection: [TourStatus.transport, TourStatus.cancelled],
      TourStatus.transport: [TourStatus.return_, TourStatus.cancelled],
      TourStatus.return_: [TourStatus.closure, TourStatus.cancelled],
      TourStatus.closure: [TourStatus.cancelled],
    };

    final allowed = allowedTransitions[currentStatus] ?? [];
    if (!allowed.contains(newStatus)) {
      return 'Transition non autorisée de ${currentStatus.label} vers ${newStatus.label}';
    }

    return null;
  }

  /// Valide qu'un tour peut passer à l'étape suivante.
  Future<String?> validateCanMoveToNextStep(Tour tour) async {
    switch (tour.status) {
      case TourStatus.collection:
        if (tour.collections.isEmpty) {
          return 'Ajoutez au moins une collecte avant de passer au transport';
        }
        break;
      case TourStatus.transport:
        // Pas de validation spécifique pour le transport
        break;
      case TourStatus.return_:
        if (!tour.areAllCollectionsPaid) {
          return 'Toutes les collectes doivent être payées avant la clôture';
        }
        break;
      case TourStatus.closure:
        // Déjà en clôture
        break;
      case TourStatus.cancelled:
        return 'Un tour annulé ne peut pas être modifié';
    }
    return null;
  }

  /// Passe à l'étape suivante du workflow.
  Future<void> moveToNextStep(String tourId) async {
    final tour = await tourRepository.getTourById(tourId);

    if (tour == null) {
      throw Exception('Tour introuvable');
    }

    // Valider qu'on peut passer à l'étape suivante
    final validationError = await validateCanMoveToNextStep(tour);
    if (validationError != null) {
      throw Exception(validationError);
    }

    // Déterminer le prochain statut
    final nextStatus = _getNextStatus(tour.status);
    if (nextStatus == null) {
      throw Exception('Aucune étape suivante disponible');
    }

    // Valider la transition
    final transitionError = validateStatusTransition(tour.status, nextStatus);
    if (transitionError != null) {
      throw Exception(transitionError);
    }

    // Mettre à jour le statut
    await tourRepository.updateStatus(tourId, nextStatus);
  }

  /// Obtient le statut suivant.
  TourStatus? _getNextStatus(TourStatus currentStatus) {
    switch (currentStatus) {
      case TourStatus.collection:
        return TourStatus.transport;
      case TourStatus.transport:
        return TourStatus.return_;
      case TourStatus.return_:
        return TourStatus.closure;
      case TourStatus.closure:
        return null; // Déjà terminé
      case TourStatus.cancelled:
        return null; // Annulé
    }
  }

  /// Calcule le total des frais de chargement/déchargement.
  double calculateLoadingUnloadingFees(Tour tour) {
    return tour.totalLoadingFees + tour.totalUnloadingFees;
  }
}
