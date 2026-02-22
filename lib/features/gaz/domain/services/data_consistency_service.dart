import '../entities/cylinder.dart';
import '../entities/gas_sale.dart';
import '../entities/tour.dart';
import '../repositories/cylinder_stock_repository.dart';
import '../repositories/gas_repository.dart';
import '../repositories/tour_repository.dart';

/// Service de validation de cohérence des données.
///
/// Assure que les données sont cohérentes entre :
/// - Stocks et Ventes
/// - Tours et Stocks
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
  Future<String?> validateSaleStockConsistency({
    required String enterpriseId,
    required int weight,
    required int quantity,
    String? siteId,
  }) async {
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

  /// Valide la cohérence d'un tour d'approvisionnement.
  ///
  /// Vérifie :
  /// - Les quantités sont valides
  /// - Les dates sont logiques
  /// - Les frais sont cohérents
  Future<String?> validateTourConsistency(Tour tour) async {
    // Vérifier les dates
    if (tour.loadingCompletedDate != null &&
        tour.loadingCompletedDate!.isBefore(tour.tourDate)) {
      return 'La date de fin de chargement ne peut pas être avant la date du tour';
    }

    if (tour.transportCompletedDate != null &&
        tour.loadingCompletedDate != null &&
        tour.transportCompletedDate!.isBefore(tour.loadingCompletedDate!)) {
      return 'La date de fin de transport ne peut pas être avant la fin de chargement';
    }

    if (tour.receptionCompletedDate != null &&
        tour.transportCompletedDate != null &&
        tour.receptionCompletedDate!.isBefore(tour.transportCompletedDate!)) {
      return 'La date de réception ne peut pas être avant la fin de transport';
    }

    if (tour.closureDate != null &&
        tour.receptionCompletedDate != null &&
        tour.closureDate!.isBefore(tour.receptionCompletedDate!)) {
      return 'La date de clôture ne peut pas être avant la réception';
    }

    // Vérifier les quantités
    for (final entry in tour.emptyBottlesLoaded.entries) {
      if (entry.value < 0) {
        return 'Quantité négative de bouteilles vides pour ${entry.key}kg';
      }
    }

    for (final entry in tour.fullBottlesReceived.entries) {
      if (entry.value < 0) {
        return 'Quantité négative de bouteilles pleines pour ${entry.key}kg';
      }
    }

    // Vérifier les frais
    if (tour.loadingFeePerBottle < 0 || tour.unloadingFeePerBottle < 0) {
      return 'Les frais de chargement/déchargement ne peuvent pas être négatifs';
    }

    return null;
  }

  /// Valide la cohérence d'une vente complète.
  Future<String?> validateSaleConsistency({
    required GasSale sale,
    required String enterpriseId,
    String? siteId,
    int? weight,
  }) async {
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

    if (sale.totalAmount < 0) {
      return 'Le montant total ne peut pas être négatif';
    }

    if (sale.quantity <= 0) {
      return 'La quantité doit être positive';
    }

    final expectedTotal = sale.unitPrice * sale.quantity;
    if ((sale.totalAmount - expectedTotal).abs() > 0.01) {
      return 'Le montant total ne correspond pas au prix unitaire × quantité';
    }

    return null;
  }

  /// Valide la cohérence globale du module.
  Future<List<String>> validateGlobalConsistency({
    required String enterpriseId,
  }) async {
    final errors = <String>[];

    try {
      // 1. Check stock integrity
      final stockErrors = await validateCylinderStockConsistency(enterpriseId);
      errors.addAll(stockErrors);

      // 2. Check tour consistency
      final tours = await tourRepository.getTours(enterpriseId);
      for (final tour in tours) {
        final error = await validateTourConsistency(tour);
        if (error != null) {
          errors.add('Tour ${tour.id}: $error');
        }
      }

      // 3. Check sale consistency
      final sales = await gasRepository.getSales();
      final scopedSales = sales.where((s) => s.enterpriseId == enterpriseId).toList();
      for (final sale in scopedSales) {
        final error = await validateSaleConsistency(
          sale: sale,
          enterpriseId: enterpriseId,
          weight: null,
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

  /// Vérifie l'intégrité des enregistrements de stock.
  Future<List<String>> validateCylinderStockConsistency(String enterpriseId) async {
    final errors = <String>[];
    
    final stocks = await stockRepository.getAllForEnterprise(enterpriseId);
    final cylinders = await gasRepository.getCylindersForEnterprises([enterpriseId]);
    final cylinderMap = {for (var c in cylinders) c.id: c};

    // Check for unique key violations (CylinderId, Status, SiteId)
    final uniqueKeys = <String, String>{};
    
    for (final stock in stocks) {
      // 1. Check for valid cylinder
      final cylinder = cylinderMap[stock.cylinderId];
      if (cylinder == null) {
        errors.add('Stock ${stock.id}: Bouteille non trouvée (ID: ${stock.cylinderId})');
        continue;
      }

      // 2. Check for weight mismatch
      if (stock.weight != cylinder.weight) {
        errors.add('Stock ${stock.id}: Poids incohérent (${stock.weight}kg vs ${cylinder.weight}kg pour ${cylinder.label})');
      }

      // 3. Check for duplicates
      final key = '${stock.cylinderId}_${stock.status}_${stock.siteId}';
      if (uniqueKeys.containsKey(key)) {
        errors.add('Stock ${stock.id}: Doublon détecté avec ${uniqueKeys[key]} (Même bouteille, statut et site)');
      } else {
        uniqueKeys[key] = stock.id;
      }
    }

    return errors;
  }
}
