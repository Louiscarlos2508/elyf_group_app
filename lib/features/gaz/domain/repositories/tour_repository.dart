import '../entities/tour.dart';

/// Interface pour le repository des tours d'approvisionnement.
abstract class TourRepository {
  /// Récupère tous les tours d'une entreprise.
  Future<List<Tour>> getTours(
    String enterpriseId, {
    TourStatus? status,
    DateTime? from,
    DateTime? to,
  });

  /// Récupère un tour par son ID.
  Future<Tour?> getTourById(String id);

  /// Crée un nouveau tour.
  Future<String> createTour(Tour tour);

  /// Met à jour un tour existant.
  Future<void> updateTour(Tour tour);

  /// Met à jour le statut d'un tour.
  Future<void> updateStatus(String id, TourStatus status);

  /// Annule un tour.
  Future<void> cancelTour(String id);

  /// Supprime un tour.
  Future<void> deleteTour(String id);
}
