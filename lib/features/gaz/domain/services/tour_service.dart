import '../../../../core/errors/app_exceptions.dart';
import '../entities/tour.dart';
import '../repositories/tour_repository.dart';
import 'transaction_service.dart';

/// Service de gestion des tours d'approvisionnement (Journal du Camion).
class TourService {
  const TourService({
    required this.tourRepository,
    required this.transactionService,
  });

  final TourRepository tourRepository;
  final TransactionService transactionService;

  /// Définit le stock initial dans le camion au départ et exécute la transaction de sortie de stock.
  Future<void> startTour({
    required String tourId,
    required String userId,
    required Map<int, int> fullBottles,
    required Map<int, int> emptyBottles,
    required Map<int, String> weightToCylinderId,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw const NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');
    if (tour.status == TourStatus.closed || tour.status == TourStatus.cancelled) {
      throw const ValidationException('Le tour est clôturé', 'TOUR_CLOSED');
    }

    // 1. Mettre à jour l'entité
    final updated = tour.copyWith(
      status: TourStatus.collecting,
      initialFullBottles: fullBottles,
      initialEmptyBottles: emptyBottles,
      updatedAt: DateTime.now(),
    );
    await tourRepository.updateTour(updated);

    // 2. Exécuter la transaction de stock
    await transactionService.executeTourStartTransaction(
      tourId: tourId,
      userId: userId,
      fullBottles: fullBottles,
      emptyBottles: emptyBottles,
      weightToCylinderId: weightToCylinderId,
    );
  }

  /// Met à jour (uniquement localement) le stock initial.
  Future<void> updateInitialStock({
    required String tourId,
    required Map<int, int> fullBottles,
    required Map<int, int> emptyBottles,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw const NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');
    
    final updated = tour.copyWith(
      initialFullBottles: fullBottles,
      initialEmptyBottles: emptyBottles,
      updatedAt: DateTime.now(),
    );
    await tourRepository.updateTour(updated);
  }

  /// Ajoute un passage sur un site (POS, Grossiste).
  Future<void> addSiteInteraction({
    required String tourId,
    required TourSiteInteraction record,
    required String userId,
    required Map<int, String> weightToCylinderId,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw const NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');
    if (tour.status == TourStatus.closed || tour.status == TourStatus.cancelled) {
      throw const ValidationException('Le tour est clôturé', 'TOUR_CLOSED');
    }

    // 1. Traiter le mouvement de stock immédiatement
    await transactionService.processSiteInteraction(tour, record, userId, weightToCylinderId);

    // 2. Marquer comme traité et ajouter à la liste
    final processedRecord = record.copyWith(isProcessed: true);
    final updatedInteractions = List<TourSiteInteraction>.from(tour.siteInteractions)..add(processedRecord);
    
    // Transition automatique vers collecting si on était juste open
    final newStatus = tour.status == TourStatus.open ? TourStatus.collecting : tour.status;

    final updated = tour.copyWith(
      siteInteractions: updatedInteractions,
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    await tourRepository.updateTour(updated);
  }

  /// Supprime un passage sur un site.
  Future<void> removeSiteInteraction(String tourId, String recordId) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw const NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');
    if (tour.status == TourStatus.closed || tour.status == TourStatus.cancelled) {
      throw const ValidationException('Le tour est clôturé', 'TOUR_CLOSED');
    }

    final updatedInteractions = tour.siteInteractions.where((r) => r.id != recordId).toList();
    final updated = tour.copyWith(
      siteInteractions: updatedInteractions,
      updatedAt: DateTime.now(),
    );
    await tourRepository.updateTour(updated);
  }

  /// Met à jour la recharge chez le fournisseur.
  Future<void> updateSupplierRecharge({
    required String tourId,
    required String userId,
    required Map<int, int> fullReceived,
    required Map<int, int> emptyReturned,
    required Map<int, String> weightToCylinderId,
    double? gasCost,
    String? supplier,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw const NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');
    if (tour.status == TourStatus.closed || tour.status == TourStatus.cancelled) {
      throw const ValidationException('Le tour est clôturé', 'TOUR_CLOSED');
    }

    // 1. Exécuter la transaction de stock et finance
    await transactionService.executeTourRechargeTransaction(
      tourId: tourId,
      userId: userId,
      fullReceived: fullReceived,
      emptyReturned: emptyReturned,
      weightToCylinderId: weightToCylinderId,
      gasCost: gasCost,
    );

    final updated = tour.copyWith(
      status: TourStatus.delivering,
      fullBottlesReceived: fullReceived,
      emptyBottlesReturned: emptyReturned,
      gasPurchaseCost: gasCost,
      supplierName: supplier,
      receptionCompletedDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await tourRepository.updateTour(updated);
  }

  /// Annule un tour.
  Future<void> cancelTour(String tourId, String userId) async {
    // Note: La transaction devra être mise à jour pour le nouveau modèle
    await transactionService.executeTourCancellationTransaction(
      tourId: tourId,
      userId: userId,
    );
  }

  /// Valide l'étape de transport.
  Future<void> validateTransport(String tourId) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw const NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');
    
    final updated = tour.copyWith(
      status: TourStatus.recharging,
      transportCompletedDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await tourRepository.updateTour(updated);
  }

  /// Prépare la clôture du tour (Bilan).
  Future<void> validateClosing(String tourId) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw const NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');
    
    final updated = tour.copyWith(
      status: TourStatus.closing,
      closureDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await tourRepository.updateTour(updated);
  }

  /// Clôture un tour avec mise à jour des stocks et finances.
  Future<List<dynamic>> closeTour(
    String tourId,
    String userId, {
    Map<int, String> weightToCylinderId = const {},
    Map<int, int> remainingFull = const {},
    Map<int, int> remainingEmpty = const {},
  }) async {
    final result = await transactionService.executeTourClosureTransaction(
      tourId: tourId,
      userId: userId,
      remainingFull: remainingFull,
      remainingEmpty: remainingEmpty,
      weightToCylinderId: weightToCylinderId,
    );
    return result.alerts;
  }

  /// Effectue un ajustement de stock technique (correction) sans ajouter d'interaction au log du tour.
  Future<void> adjustStock({
    required String tourId,
    required TourSiteInteraction correction,
    required String userId,
    required Map<int, String> weightToCylinderId,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) throw const NotFoundException('Tour introuvable', 'TOUR_NOT_FOUND');
    
    // On appelle directement le service de transaction pour l'ajustement
    await transactionService.processSiteInteraction(
      tour, 
      correction, 
      userId, 
      weightToCylinderId,
    );
  }
}
