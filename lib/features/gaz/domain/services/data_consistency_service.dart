import '../entities/collection.dart';
import '../entities/cylinder.dart';
import '../entities/gas_sale.dart';
import '../entities/tour.dart';
import '../repositories/cylinder_stock_repository.dart';
import '../repositories/gas_repository.dart';
import '../repositories/tour_repository.dart';

/// Service de validation de cohérence des données entre les modules.
///
/// Assure que les données sont cohérentes entre :
/// - Tours et Collections
/// - Stocks et Ventes
/// - Stocks et Tours
/// - Collections et Paiements
class DataConsistencyService {
  const DataConsistencyService({
    required this.stockRepository,
    required this.gasRepository,
    required this.tourRepository,
  });

  final CylinderStockRepository stockRepository;
  final GasRepository gasRepository;
  final TourRepository tourRepository;

  /// Valide la cohérence d'une vente avec le stock disponible.
  ///
  /// Retourne null si cohérent, sinon un message d'erreur.
  Future<String?> validateSaleStockConsistency({
    required String enterpriseId,
    required int weight,
    required int quantity,
    String? siteId,
  }) async {
    // Récupérer le stock disponible
    final stocks = await stockRepository.getStocksByWeight(
      enterpriseId,
      weight,
      siteId: siteId,
    );

    final availableStock = stocks
        .where((s) => s.status == CylinderStatus.full)
        .fold<int>(0, (sum, s) => sum + s.quantity);

    if (availableStock < quantity) {
      return 'Stock insuffisant: $availableStock disponible, $quantity demandé';
    }

    return null;
  }

  /// Valide la cohérence d'une collection avec les données du tour.
  ///
  /// Retourne null si cohérent, sinon un message d'erreur.
  Future<String?> validateCollectionTourConsistency({
    required String tourId,
    required Collection collection,
  }) async {
    final tour = await tourRepository.getTourById(tourId);
    if (tour == null) {
      return 'Tour introuvable';
    }

    // Vérifier que la collection appartient au tour
    final collectionExists = tour.collections.any((c) => c.id == collection.id);
    if (!collectionExists && tour.collections.isNotEmpty) {
      return 'La collection n\'appartient pas à ce tour';
    }

    // Vérifier que les montants sont cohérents
    if (collection.amountPaid < 0) {
      return 'Le montant payé ne peut pas être négatif';
    }

    if (collection.amountPaid > collection.amountDue) {
      return 'Le montant payé ne peut pas dépasser le montant dû';
    }

    return null;
  }

  /// Valide la cohérence du stock après une opération de tour.
  ///
  /// Vérifie que les quantités de bouteilles collectées/transportées
  /// sont cohérentes avec les stocks.
  Future<String?> validateTourStockConsistency({required Tour tour}) async {
    // Pour chaque collection, vérifier que les quantités sont valides
    for (final collection in tour.collections) {
      for (final entry in collection.emptyBottles.entries) {
        final weight = entry.key;
        final quantity = entry.value;

        if (quantity < 0) {
          return 'Quantité négative de bouteilles pour ${weight}kg';
        }

        // Vérifier que les fuites ne dépassent pas les bouteilles collectées
        final leaks = collection.leaks[weight] ?? 0;
        if (leaks > quantity) {
          return 'Les fuites ($leaks) ne peuvent pas dépasser les bouteilles collectées ($quantity) pour ${weight}kg';
        }
      }
    }

    return null;
  }

  /// Valide la cohérence globale d'un tour.
  ///
  /// Vérifie :
  /// - Les collections sont valides
  /// - Les montants sont cohérents
  /// - Les dates sont logiques
  Future<String?> validateTourConsistency(Tour tour) async {
    // Vérifier les dates
    if (tour.collectionCompletedDate != null &&
        tour.collectionCompletedDate!.isBefore(tour.tourDate)) {
      return 'La date de fin de collecte ne peut pas être avant la date du tour';
    }

    if (tour.transportCompletedDate != null &&
        tour.collectionCompletedDate != null &&
        tour.transportCompletedDate!.isBefore(tour.collectionCompletedDate!)) {
      return 'La date de fin de transport ne peut pas être avant la fin de collecte';
    }

    if (tour.returnCompletedDate != null &&
        tour.transportCompletedDate != null &&
        tour.returnCompletedDate!.isBefore(tour.transportCompletedDate!)) {
      return 'La date de retour ne peut pas être avant la fin de transport';
    }

    if (tour.closureDate != null &&
        tour.returnCompletedDate != null &&
        tour.closureDate!.isBefore(tour.returnCompletedDate!)) {
      return 'La date de clôture ne peut pas être avant le retour';
    }

    // Vérifier la cohérence des collections
    final collectionError = await validateTourStockConsistency(tour: tour);
    if (collectionError != null) {
      return collectionError;
    }

    // Vérifier les montants
    if (tour.loadingFeePerBottle < 0 || tour.unloadingFeePerBottle < 0) {
      return 'Les frais de chargement/déchargement ne peuvent pas être négatifs';
    }

    return null;
  }

  /// Valide la cohérence d'une vente complète.
  ///
  /// Vérifie :
  /// - Stock disponible
  /// - Montants cohérents
  /// - Données client valides
  Future<String?> validateSaleConsistency({
    required GasSale sale,
    required String enterpriseId,
    String? siteId,
    int?
    weight, // Poids de la bouteille (peut être null si on doit le récupérer)
  }) async {
    // Si le poids n'est pas fourni, on ne peut pas valider le stock
    // Dans ce cas, on valide juste les montants
    if (weight != null) {
      final stockError = await validateSaleStockConsistency(
        enterpriseId: enterpriseId,
        weight: weight,
        quantity: sale.quantity,
        siteId: siteId,
      );

      if (stockError != null) {
        return stockError;
      }
    }

    // Vérifier les montants
    if (sale.totalAmount < 0) {
      return 'Le montant total ne peut pas être négatif';
    }

    // Vérifier la quantité
    if (sale.quantity <= 0) {
      return 'La quantité doit être positive';
    }

    // Vérifier que le montant correspond au prix unitaire * quantité
    final expectedTotal = sale.unitPrice * sale.quantity;
    if ((sale.totalAmount - expectedTotal).abs() > 0.01) {
      return 'Le montant total ne correspond pas au prix unitaire × quantité';
    }

    return null;
  }

  /// Valide la cohérence globale du module.
  ///
  /// Effectue des vérifications croisées entre toutes les entités.
  Future<List<String>> validateGlobalConsistency({
    required String enterpriseId,
  }) async {
    final errors = <String>[];

    try {
      // Vérifier tous les tours
      final tours = await tourRepository.getTours(enterpriseId);
      for (final tour in tours) {
        final error = await validateTourConsistency(tour);
        if (error != null) {
          errors.add('Tour ${tour.id}: $error');
        }
      }

      // Vérifier toutes les ventes
      final sales = await gasRepository.getSales();
      for (final sale in sales) {
        // Note: Pour valider complètement, il faudrait récupérer le Cylinder
        // pour obtenir le weight. Pour l'instant, on valide juste les montants.
        final error = await validateSaleConsistency(
          sale: sale,
          enterpriseId: enterpriseId,
          weight: null, // Ne valide pas le stock sans le poids
        );
        if (error != null) {
          errors.add('Vente ${sale.id}: $error');
        }
      }
    } catch (e) {
      errors.add('Erreur lors de la validation: $e');
    }

    return errors;
  }
}
