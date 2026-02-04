import '../../domain/entities/tour.dart';
import '../../domain/repositories/tour_repository.dart';
import '../../domain/services/tour_service.dart';

/// Contrôleur pour gérer les tours d'approvisionnement.
class TourController {
  const TourController({required this.repository, required this.service});

  final TourRepository repository;
  final TourService service;

  /// Récupère tous les tours.
  Future<List<Tour>> getTours(
    String enterpriseId, {
    TourStatus? status,
    DateTime? from,
    DateTime? to,
  }) async {
    return await repository.getTours(
      enterpriseId,
      status: status,
      from: from,
      to: to,
    );
  }

  /// Observe les tours en temps réel.
  Stream<List<Tour>> watchTours(
    String enterpriseId, {
    TourStatus? status,
    DateTime? from,
    DateTime? to,
  }) {
    return repository.watchTours(
      enterpriseId,
      status: status,
      from: from,
      to: to,
    );
  }

  /// Récupère un tour par ID.
  Future<Tour?> getTourById(String id) async {
    return await repository.getTourById(id);
  }

  /// Crée un nouveau tour.
  Future<String> createTour(Tour tour) async {
    return await repository.createTour(tour);
  }

  /// Met à jour un tour.
  Future<void> updateTour(Tour tour) async {
    await repository.updateTour(tour);
  }

  /// Passe à l'étape suivante du workflow.
  Future<void> moveToNextStep(String tourId) async {
    await service.moveToNextStep(tourId);
  }

  /// Annule un tour.
  Future<void> cancelTour(String id) async {
    await repository.cancelTour(id);
  }

  /// Supprime un tour.
  Future<void> deleteTour(String id) async {
    await repository.deleteTour(id);
  }
}
