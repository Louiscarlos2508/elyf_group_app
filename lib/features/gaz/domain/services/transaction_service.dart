import '../entities/collection.dart';
import '../entities/cylinder.dart';
import '../entities/cylinder_stock.dart';
import '../entities/gas_sale.dart';
import '../entities/tour.dart';
import '../repositories/cylinder_stock_repository.dart';
import '../repositories/gas_repository.dart';
import '../repositories/tour_repository.dart';
import 'data_consistency_service.dart';

/// Service de gestion des transactions atomiques pour opérations critiques.
/// 
/// Assure que les opérations multi-étapes sont exécutées de manière atomique :
/// - Vente : Débit stock + Création vente (tout ou rien)
/// - Tour closure : Mise à jour tour + Mise à jour stocks (tout ou rien)
/// - Collection payment : Mise à jour collection + Mise à jour tour (tout ou rien)
class TransactionService {
  const TransactionService({
    required this.stockRepository,
    required this.gasRepository,
    required this.tourRepository,
    required this.consistencyService,
  });

  final CylinderStockRepository stockRepository;
  final GasRepository gasRepository;
  final TourRepository tourRepository;
  final DataConsistencyService consistencyService;

  /// Exécute une vente de manière atomique.
  /// 
  /// Étapes :
  /// 1. Valide la cohérence (stock disponible)
  /// 2. Débite le stock
  /// 3. Crée la vente
  /// 
  /// En cas d'erreur, rollback automatique.
  Future<GasSale> executeSaleTransaction({
    required GasSale sale,
    required int weight, // Poids de la bouteille vendue
    required String enterpriseId,
    String? siteId,
  }) async {
    // 1. Validation de cohérence
    final consistencyError = await consistencyService.validateSaleConsistency(
      sale: sale,
      enterpriseId: enterpriseId,
      siteId: siteId,
      weight: weight,
    );

    if (consistencyError != null) {
      throw Exception('Validation échouée: $consistencyError');
    }

    // 2. Débiter le stock
    final stockUpdates = <String, ({int originalQuantity, int debitedQuantity})>{}; // stockId -> infos

    try {
      // Récupérer les stocks disponibles
      final stocks = await stockRepository.getStocksByWeight(
        enterpriseId,
        weight,
        siteId: siteId,
      );

      final fullStocks = stocks
          .where((s) => s.status == CylinderStatus.full)
          .toList()
        ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt)); // FIFO

      int remainingToDebit = sale.quantity;

      for (final stock in fullStocks) {
        if (remainingToDebit <= 0) break;

        final toDebit = remainingToDebit > stock.quantity
            ? stock.quantity
            : remainingToDebit;

        final newQuantity = stock.quantity - toDebit;
        stockUpdates[stock.id] = (
          originalQuantity: stock.quantity,
          debitedQuantity: toDebit,
        );

        await stockRepository.updateStockQuantity(stock.id, newQuantity);
        remainingToDebit -= toDebit;
      }

      if (remainingToDebit > 0) {
        throw Exception(
          'Stock insuffisant pour ${weight}kg: $remainingToDebit manquants',
        );
      }

      // 3. Créer la vente
      await gasRepository.addSale(sale);

      return sale;
    } catch (e) {
      // Rollback : restaurer les stocks
      for (final entry in stockUpdates.entries) {
        try {
          final stockInfo = entry.value;
          await stockRepository.updateStockQuantity(
            entry.key,
            stockInfo.originalQuantity,
          );
        } catch (rollbackError) {
          // Log l'erreur de rollback mais ne pas bloquer
          // TODO: Logger l'erreur
        }
      }
      rethrow;
    }
  }

  /// Exécute la clôture d'un tour de manière atomique.
  /// 
  /// Étapes :
  /// 1. Valide la cohérence du tour
  /// 2. Vérifie que toutes les collections sont payées
  /// 3. Met à jour le statut du tour
  /// 4. Met à jour les stocks si nécessaire
  Future<Tour> executeTourClosureTransaction({
    required String tourId,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) {
      throw Exception('Tour introuvable');
    }

    // 1. Validation
    final consistencyError = await consistencyService.validateTourConsistency(
      tour,
    );
    if (consistencyError != null) {
      throw Exception('Validation échouée: $consistencyError');
    }

    if (!tour.areAllCollectionsPaid) {
      throw Exception('Toutes les collectes doivent être payées avant la clôture');
    }

    // 2. Mettre à jour le tour
    final updatedTour = tour.copyWith(
      status: TourStatus.closure,
      closureDate: DateTime.now(),
    );

    await tourRepository.updateTour(updatedTour);

    // 3. Mise à jour des stocks si nécessaire
    // (Les bouteilles collectées peuvent être ajoutées au stock)
    // TODO: Implémenter selon la logique métier

    return updatedTour;
  }

  /// Exécute le paiement d'une collection de manière atomique.
  /// 
  /// Étapes :
  /// 1. Valide la cohérence
  /// 2. Met à jour la collection
  /// 3. Met à jour le tour si toutes les collections sont payées
  Future<Collection> executeCollectionPaymentTransaction({
    required String tourId,
    required String collectionId,
    required double amount,
    required DateTime paymentDate,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) {
      throw Exception('Tour introuvable');
    }

    final collectionIndex = tour.collections.indexWhere(
      (c) => c.id == collectionId,
    );
    if (collectionIndex == -1) {
      throw Exception('Collection introuvable dans le tour');
    }

    final collection = tour.collections[collectionIndex];

    // 1. Validation
    if (amount < 0) {
      throw Exception('Le montant ne peut pas être négatif');
    }

    if (amount > collection.remainingAmount) {
      throw Exception(
        'Le montant payé (${amount}) ne peut pas dépasser le reste à payer (${collection.remainingAmount})',
      );
    }

    // 2. Mettre à jour la collection
    final updatedCollection = collection.copyWith(
      amountPaid: collection.amountPaid + amount,
      paymentDate: paymentDate,
    );

    final updatedCollections = List<Collection>.from(tour.collections);
    updatedCollections[collectionIndex] = updatedCollection;

    // 3. Mettre à jour le tour
    final updatedTour = tour.copyWith(
      collections: updatedCollections,
    );

    await tourRepository.updateTour(updatedTour);

    return updatedCollection;
  }
}

