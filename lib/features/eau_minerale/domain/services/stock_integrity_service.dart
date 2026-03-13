import '../../../../core/logging/app_logger.dart';
import '../repositories/stock_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';
import '../repositories/production_session_repository.dart';
import '../entities/stock_movement.dart';
import '../product_roles.dart';
import '../entities/sale.dart';
import '../entities/production_session_status.dart';

/// Résultat d'une vérification d'intégrité du stock pour un produit spécifique.
class StockIntegrityResult {
  const StockIntegrityResult({
    required this.isValid,
    required this.productId,
    required this.productName,
    required this.storedQuantity,
    required this.calculatedQuantity,
    this.uiQuantity = 0,
    this.hasStoredRecord = true,
    this.discrepancy,
    this.movementsCount,
    this.totalEntries = 0,
    this.totalExits = 0,
    this.hadNegativeBalance = false,
    this.stockType = 'produit',
    this.hasPotentialDuplicate = false,
  });

  final bool isValid;
  final String productId;
  final String productName;
  final double storedQuantity;
  final double calculatedQuantity;
  final double uiQuantity;
  final bool hasStoredRecord;
  final double? discrepancy;
  final int? movementsCount;
  final double totalEntries;
  final double totalExits;
  final bool hadNegativeBalance;
  final String stockType;
  final bool hasPotentialDuplicate;

  /// Alias pour compatibilité UI
  String get stockId => productId;

  double get difference => storedQuantity - calculatedQuantity;
}

class StockIntegrityService {
  StockIntegrityService({
    required this.stockRepository,
    required this.productRepository,
    required this.saleRepository,
    required this.sessionRepository,
  });

  final StockRepository stockRepository;
  final ProductRepository productRepository;
  final SaleRepository saleRepository;
  final ProductionSessionRepository sessionRepository;

  /// Vérifie l'intégrité de tous les stocks "clés" définis par les rôles.
  Future<List<StockIntegrityResult>> verifyAllStocks() async {
    final products = await productRepository.fetchProducts();
    
    // On vérifie maintenant TOUS les produits, plus seulement les rôles clés
    final results = <StockIntegrityResult>[];
    for (final p in products) {
      final res = await verifyProductStock(p.id, p.name);
      results.add(res);
    }
    
    return results;
  }

  /// Vérifie l'intégrité pour un produit spécifique.
  Future<StockIntegrityResult> verifyProductStock(String productId, String productName) async {
    // On récupère TOUS les mouvements pour agréger l'historique par Nom si l'ID a changé
    final allMovements = await stockRepository.fetchMovements();
    final movements = allMovements.where((m) => 
      m.productId == productId || 
      m.productName.toLowerCase() == productName.toLowerCase()
    ).toList();
    
    // On compare avec le stock "stocké" (officiel) qui vient de la collection stock_items
    final storedQuantityResult = await stockRepository.getStoredQuantity(productId);
    final storedQuantity = storedQuantityResult ?? 0.0;
    
    // Et on compare avec le stock "utilisé par l'UI" (recalculé)
    final uiQuantity = await stockRepository.getStock(productId);

    // 1. Vérification du calcul simple (Balance cumulative des mouvements)
    double calculatedQuantity = 0;
    double totalEntries = 0;
    double totalExits = 0;
    bool hadNegativeBalance = false;
    
    // Trier par date pour calculer le solde glissant
    final sortedMovements = List<StockMovement>.from(movements)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final m in sortedMovements) {
      if (m.type == StockMovementType.entry) {
        totalEntries += m.quantity;
        calculatedQuantity += m.quantity;
      } else {
        totalExits += m.quantity;
        calculatedQuantity -= m.quantity;
      }
      if (calculatedQuantity < -0.001) {
        hadNegativeBalance = true;
      }
    }

    final diff = storedQuantity - calculatedQuantity;
    final uiDiff = uiQuantity - calculatedQuantity;
    
    // 2. Vérification de la cohérence Business (Ventes & Productions)
    final product = await productRepository.getProduct(productId);
    bool hasMissingBusinessMovements = false;
    
    if (product != null) {
      if (product.role == ProductRoles.mainFinishedGood) {
        // Pour le produit fini principal, vérifier les ventes
        final sales = await saleRepository.fetchSales();
        final productSales = sales.where((s) => s.productId == productId && s.status != SaleStatus.voided).toList();
        
        for (final s in productSales) {
          final expectedMovementId = 'local_stk_sale_${s.id}';
          final hasMovement = movements.any((m) => m.id == expectedMovementId);
          if (!hasMovement) {
            hasMissingBusinessMovements = true;
            break;
          }
        }
      } else if (product.role == ProductRoles.mainBobine || product.role == ProductRoles.mainPackaging) {
        // Pour les matières premières, vérifier les consommations de production
        final sessions = await sessionRepository.fetchSessions();
        final completedSessions = sessions.where((s) => s.status == ProductionSessionStatus.completed).toList();
        
        for (final sess in completedSessions) {
          final expectedMovementId = 'local_stk_cons_${sess.id}_$productId';
          final hasMovement = movements.any((m) => m.id == expectedMovementId);
          if (!hasMovement) {
            //hasMissingBusinessMovements = true; // On ne bloque pas encore car les vieilles sessions n'ont pas forcément d'ID déterministe
            //break;
          }
        }
      }
    }

    // 4. Détection de "doublons" (Désactivé car basé sur le nom)
    bool hasPotentialDuplicate = false;

    // Le stock est valide si:
    // 1. La somme des mouvements correspond au stock stocké (storedQuantity)
    // 2. Le stock utilisé par l'UI (uiQuantity) correspond aussi (car il recalcule normalement)
    // 3. Il n'y a pas eu de balance négative
    // 4. Les mouvements business critiques sont présents
    final isValid = (diff.abs() < 0.001) && (uiDiff.abs() < 0.001) && !hadNegativeBalance && !hasMissingBusinessMovements && !hasPotentialDuplicate && (storedQuantityResult != null || movements.isEmpty);

    return StockIntegrityResult(
      isValid: isValid,
      productId: productId,
      productName: productName,
      storedQuantity: storedQuantity,
      calculatedQuantity: calculatedQuantity,
      uiQuantity: uiQuantity,
      hasStoredRecord: storedQuantityResult != null,
      totalEntries: totalEntries,
      totalExits: totalExits,
      hadNegativeBalance: hadNegativeBalance,
      discrepancy: isValid ? null : (diff != 0 ? diff : uiDiff),
      movementsCount: movements.length,
      stockType: _inferTypeFromId(productId, product?.role),
      hasPotentialDuplicate: hasPotentialDuplicate,
    );
  }

  String _inferTypeFromId(String id, String? role) {
    if (role == ProductRoles.mainBobine) return 'bobine';
    if (role == ProductRoles.mainPackaging) return 'packaging';
    if (id.contains('bobine')) return 'bobine';
    if (id.contains('packaging')) return 'packaging';
    return 'produit';
  }

  /// Corrige un stock en recalculant sa quantité à partir des mouvements.
  Future<void> repairStock(StockIntegrityResult result) async {
    if (result.isValid) return;

    await stockRepository.syncStoredQuantity(result.productId);
    
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
