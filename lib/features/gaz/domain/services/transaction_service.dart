import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/logging/app_logger.dart';
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
      throw ValidationException(
        'Validation échouée: $consistencyError',
        'VALIDATION_FAILED',
      );
    }

    // 2. Débiter le stock
    final stockUpdates =
        <
          String,
          ({int originalQuantity, int debitedQuantity})
        >{}; // stockId -> infos

    try {
      // Récupérer les stocks disponibles
      final stocks = await stockRepository.getStocksByWeight(
        enterpriseId,
        weight,
        siteId: siteId,
      );

      final fullStocks =
          stocks.where((s) => s.status == CylinderStatus.full).toList()
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
        throw ValidationException(
          'Stock insuffisant pour ${weight}kg: $remainingToDebit manquants',
          'INSUFFICIENT_STOCK',
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
        } catch (rollbackError, rollbackStackTrace) {
          // Log l'erreur de rollback mais ne pas bloquer
          AppLogger.error(
            'TransactionService: Erreur lors du rollback du stock ${entry.key}',
            name: 'transaction.rollback',
            error: rollbackError,
            stackTrace: rollbackStackTrace,
          );
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
  Future<Tour> executeTourClosureTransaction({required String tourId}) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) {
      throw NotFoundException(
        'Tour introuvable',
        'TOUR_NOT_FOUND',
      );
    }

    // 1. Validation
    final consistencyError = await consistencyService.validateTourConsistency(
      tour,
    );
    if (consistencyError != null) {
      throw ValidationException(
        'Validation échouée: $consistencyError',
        'VALIDATION_FAILED',
      );
    }

    if (!tour.areAllCollectionsPaid) {
      throw ValidationException(
        'Toutes les collectes doivent être payées avant la clôture',
        'UNPAID_COLLECTIONS',
      );
    }

    // 2. Mettre à jour le tour
    final updatedTour = tour.copyWith(
      status: TourStatus.closure,
      closureDate: DateTime.now(),
    );

    await tourRepository.updateTour(updatedTour);

    // 3. Mise à jour des stocks : ajouter les bouteilles vides collectées au stock
    // Les bouteilles collectées sont ajoutées au stock avec le statut emptyAtStore
    try {
      // Récupérer tous les cylindres pour mapper les poids aux cylinderId
      final allCylinders = await gasRepository.getCylinders();
      // Filtrer par entreprise
      final cylinders = allCylinders
          .where((c) => c.enterpriseId == updatedTour.enterpriseId)
          .toList();
      
      // Agréger toutes les bouteilles vides collectées par poids
      final emptyBottlesByWeight = <int, int>{};
      for (final collection in updatedTour.collections) {
        for (final entry in collection.emptyBottles.entries) {
          final weight = entry.key;
          final quantity = entry.value;
          // Soustraire les fuites car elles ne sont pas ajoutées au stock
          final leakQuantity = collection.leaks[weight] ?? 0;
          final validQuantity = quantity - leakQuantity;
          
          if (validQuantity > 0) {
            emptyBottlesByWeight[weight] = 
                (emptyBottlesByWeight[weight] ?? 0) + validQuantity;
          }
        }
      }

      // Pour chaque poids, trouver ou créer un stock et ajouter les bouteilles
      for (final entry in emptyBottlesByWeight.entries) {
        final weight = entry.key;
        final quantityToAdd = entry.value;

        // Trouver le cylindre correspondant au poids
        final cylinder = cylinders.firstWhere(
          (c) => c.weight == weight,
          orElse: () {
            throw NotFoundException(
              'Aucun cylindre trouvé pour le poids $weight kg',
              'CYLINDER_NOT_FOUND',
            );
          },
        );

        // Chercher un stock existant avec le statut emptyAtStore pour ce poids
        final existingStocks = await stockRepository.getStocksByWeight(
          updatedTour.enterpriseId,
          weight,
        );

        final emptyStocks = existingStocks
            .where(
              (s) => s.status == CylinderStatus.emptyAtStore && 
                     s.cylinderId == cylinder.id,
            )
            .toList();
        final emptyStock = emptyStocks.isNotEmpty ? emptyStocks.first : null;

        if (emptyStock != null) {
          // Mettre à jour le stock existant
          await stockRepository.updateStockQuantity(
            emptyStock.id,
            emptyStock.quantity + quantityToAdd,
          );
        } else {
          // Créer un nouveau stock
          final newStock = CylinderStock(
            id: 'stock_${DateTime.now().millisecondsSinceEpoch}_$weight',
            cylinderId: cylinder.id,
            weight: weight,
            status: CylinderStatus.emptyAtStore,
            quantity: quantityToAdd,
            enterpriseId: updatedTour.enterpriseId,
            updatedAt: DateTime.now(),
          );
          await stockRepository.addStock(newStock);
        }
      }

      AppLogger.info(
        'TransactionService: ${emptyBottlesByWeight.values.fold<int>(0, (sum, qty) => sum + qty)} bouteilles vides ajoutées au stock lors de la clôture du tour ${updatedTour.id}',
        name: 'transaction.tour_closure',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'TransactionService: Erreur lors de la mise à jour des stocks pour le tour ${updatedTour.id}: $e',
        name: 'transaction.tour_closure',
        error: e,
        stackTrace: stackTrace,
      );
      // Ne pas faire échouer la clôture du tour si la mise à jour du stock échoue
      // Le tour est déjà clôturé, on log juste l'erreur
    }

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
      throw NotFoundException(
        'Tour introuvable',
        'TOUR_NOT_FOUND',
      );
    }

    final collectionIndex = tour.collections.indexWhere(
      (c) => c.id == collectionId,
    );
    if (collectionIndex == -1) {
      throw NotFoundException(
        'Collection introuvable dans le tour',
        'COLLECTION_NOT_FOUND',
      );
    }

    final collection = tour.collections[collectionIndex];

    // 1. Validation
    if (amount < 0) {
      throw ValidationException(
        'Le montant ne peut pas être négatif',
        'NEGATIVE_AMOUNT',
      );
    }

    if (amount > collection.remainingAmount) {
      throw ValidationException(
        'Le montant payé ($amount) ne peut pas dépasser le reste à payer (${collection.remainingAmount})',
        'PAYMENT_AMOUNT_EXCEEDS_REMAINING',
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
    final updatedTour = tour.copyWith(collections: updatedCollections);

    await tourRepository.updateTour(updatedTour);

    return updatedCollection;
  }
}
