import '../../../../core/errors/app_exceptions.dart';
import '../entities/tour.dart';
import '../repositories/tour_repository.dart';

import 'transaction_service.dart';

/// Service de gestion des tours d'approvisionnement fournisseur.
class TourService {
  const TourService({
    required this.tourRepository,
    required this.transactionService,
  });

  final TourRepository tourRepository;
  final TransactionService transactionService;

  /// Met à jour les bouteilles vides chargées avec gestion du stock transit.
  Future<void> updateEmptyBottlesLoaded(String tourId, Map<int, int> quantities, String userId) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');
    if (tour.status != TourStatus.open) throw ValidationException('Le tour est clôturé', 'TOUR_CLOSED');

    await transactionService.executeTourLoadingTransaction(
      tourId: tourId,
      userId: userId,
      newLoading: quantities,
    );
  }

  /// Annule un tour avec remise en stock des bouteilles en transit.
  Future<void> cancelTour(String tourId, String userId) async {
    await transactionService.executeTourCancellationTransaction(
      tourId: tourId,
      userId: userId,
    );
  }

  /// Met à jour les bouteilles pleines reçues.
  Future<void> updateFullBottlesReceived(String tourId, Map<int, int> quantities, double? gasCost, String? supplier) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');
    if (tour.status != TourStatus.open) throw ValidationException('Le tour est clôturé', 'TOUR_CLOSED');

    final updated = tour.copyWith(
      fullBottlesReceived: quantities,
      gasPurchaseCost: gasCost,
      supplierName: supplier,
      receptionCompletedDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await tourRepository.updateTour(updated);
  }

  /// Valide l'étape de transport et frais.
  Future<void> validateTransport(String tourId) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');
    if (tour.status != TourStatus.open) throw ValidationException('Le tour est clôturé', 'TOUR_CLOSED');

    final updated = tour.copyWith(
      transportCompletedDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await tourRepository.updateTour(updated);
  }

  /// Clôture un tour avec mise à jour des stocks.
  Future<List<dynamic>> closeTour(String tourId, String userId) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');
    
    if (tour.fullBottlesReceived.isEmpty) {
      throw ValidationException(
        'Saisissez les bouteilles pleines reçues avant la clôture',
        'NO_FULLS_RECEIVED',
      );
    }

    final result = await transactionService.executeTourClosureTransaction(
      tourId: tourId,
      userId: userId,
    );
    return result.alerts;
  }

  /// Calcule le total des frais de chargement/déchargement/échange.
  double calculateAllTourFees(Tour tour) {
    return tour.totalLoadingFees + tour.totalUnloadingFees + tour.totalExchangeFees;
  }
}
