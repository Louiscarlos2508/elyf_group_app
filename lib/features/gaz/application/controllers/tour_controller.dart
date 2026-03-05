import '../../domain/entities/tour.dart';
import '../../domain/repositories/tour_repository.dart';
import '../../domain/services/tour_service.dart';
import '../../domain/entities/stock_alert.dart';

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
    return repository.getTours(
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
    return repository.getTourById(id);
  }

  /// Crée un nouveau tour.
  Future<String> createTour(Tour tour) async {
    return repository.createTour(tour);
  }

  /// Met à jour un tour.
  Future<void> updateTour(Tour tour) async {
    await repository.updateTour(tour);
  }

  /// Met à jour les sources de chargement (Multi-sources).
  Future<void> updateEmptyBottlesLoaded(
      String tourId, List<TourLoadingSource> loadingSources, String userId) async {
    await service.updateEmptyBottlesLoaded(tourId, loadingSources, userId);
  }

  /// Valide l'étape de transport et frais.
  Future<void> validateTransport(String tourId) async {
    await service.validateTransport(tourId);
  }

  /// Met à jour les bouteilles pleines reçues.
  Future<void> updateFullBottlesReceived(String tourId, Map<int, int> quantities, double? gasCost, String? supplier) async {
    await service.updateFullBottlesReceived(tourId, quantities, gasCost, supplier);
  }

  /// Clôture un tour avec mise à jour des stocks et enregistrement financier.
  Future<List<StockAlert>> closeTour(
    String tourId,
    String userId, {
    Map<int, String> weightToCylinderId = const {},
  }) async {
    final alerts = await service.closeTour(
      tourId,
      userId,
      weightToCylinderId: weightToCylinderId,
    );
    return alerts.cast<StockAlert>();
  }

  /// Annule un tour avec remise en stock des bouteilles en transit.
  Future<void> cancelTour(String id, String userId) async {
    await service.cancelTour(id, userId);
  }

  /// Supprime un tour.
  Future<void> deleteTour(String id) async {
    await repository.deleteTour(id);
  }
}
