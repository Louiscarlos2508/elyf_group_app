import '../../../../core/logging/app_logger.dart';
import '../repositories/stock_repository.dart';
import '../repositories/product_repository.dart';
import '../entities/stock_movement.dart';
import '../product_roles.dart';

/// Résultat d'une vérification d'intégrité du stock pour un produit spécifique.
class StockIntegrityResult {
  const StockIntegrityResult({
    required this.isValid,
    required this.productId,
    required this.productName,
    required this.storedQuantity,
    required this.calculatedQuantity,
    this.discrepancy,
    this.movementsCount,
    this.stockType = 'produit', // Pour compatibilité UI
  });

  final bool isValid;
  final String productId;
  final String productName;
  final int storedQuantity;
  final int calculatedQuantity;
  final int? discrepancy;
  final int? movementsCount;
  final String stockType;

  /// Alias pour compatibilité UI
  String get stockId => productId;

  int get difference => storedQuantity - calculatedQuantity;
}

/// Service de vérification d'intégrité des stocks (Version unifiée).
class StockIntegrityService {
  StockIntegrityService({
    required this.stockRepository,
    required this.productRepository,
  });

  final StockRepository stockRepository;
  final ProductRepository productRepository;

  /// Vérifie l'intégrité de tous les stocks "clés" définis par les rôles.
  Future<List<StockIntegrityResult>> verifyAllStocks() async {
    final products = await productRepository.fetchProducts();
    
    // Filtrer les produits qui ont des rôles définis (pour éviter de tout scanner si inutile)
    final keyRoles = [
      ProductRoles.mainFinishedGood,
      ProductRoles.mainBobine,
      ProductRoles.mainPackaging,
    ];
    
    final keyProducts = products.where((p) => keyRoles.contains(p.role)).toList();
    
    final results = <StockIntegrityResult>[];
    for (final p in keyProducts) {
      final res = await verifyProductStock(p.id, p.name);
      results.add(res);
    }
    
    return results;
  }

  /// Vérifie l'intégrité pour un produit spécifique.
  Future<StockIntegrityResult> verifyProductStock(String productId, String productName) async {
    final movements = await stockRepository.fetchMovements(productId: productId);
    final storedQuantity = await stockRepository.getStock(productId);

    double calculatedQuantity = 0;
    for (final m in movements) {
      if (m.type == StockMovementType.entry) {
        calculatedQuantity += m.quantity;
      } else {
        calculatedQuantity -= m.quantity;
      }
    }

    if (calculatedQuantity < 0) calculatedQuantity = 0;

    final discrepancy = storedQuantity - calculatedQuantity.toInt();
    final isValid = discrepancy == 0;

    return StockIntegrityResult(
      isValid: isValid,
      productId: productId,
      productName: productName,
      storedQuantity: storedQuantity,
      calculatedQuantity: calculatedQuantity.toInt(),
      discrepancy: isValid ? null : discrepancy,
      movementsCount: movements.length,
      stockType: _inferTypeFromId(productId),
    );
  }

  String _inferTypeFromId(String id) {
    if (id.contains('bobine')) return 'bobine';
    if (id.contains('packaging')) return 'packaging';
    return 'produit';
  }

  /// Corrige un stock en recalculant sa quantité à partir des mouvements.
  Future<void> repairStock(StockIntegrityResult result) async {
    if (result.isValid) return;

    await stockRepository.updateStock(result.productId, result.calculatedQuantity);
    
    AppLogger.info(
      'Stock ${result.productId} (${result.productName}) repaired: ${result.storedQuantity} -> ${result.calculatedQuantity}',
      name: 'StockIntegrityService',
    );
  }

  /// Corrige tous les stocks invalides.
  Future<int> repairAllInvalidStocks() async {
    final results = await verifyAllStocks();
    int repairedCount = 0;
    
    for (final res in results) {
      if (!res.isValid) {
        await repairStock(res);
        repairedCount++;
      }
    }
    
    return repairedCount;
  }
}
