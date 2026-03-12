import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/stock_repository.dart';
import '../../domain/entities/material_consumption.dart';
import '../../domain/repositories/product_repository.dart';

class StockController {
  StockController(
    this._stockRepository,
    this._productRepository,
    this.enterpriseId,
  );

  final StockRepository _stockRepository;
  final ProductRepository _productRepository;
  final String enterpriseId;

  /// Récupère l'état global du stock dynamiquement.
  Future<StockState> fetchSnapshot() async {
    // 1. Récupérer tous les produits du catalogue
    final products = await _productRepository.fetchProducts();
    
    final List<StockItem> items = [];
    int totalMachineMaterials = 0;

    for (final product in products) {
      final stockQty = await _stockRepository.getStock(product.id);
      
      StockType type = StockType.finishedGoods;
      if (product.isRawMaterial || product.role == 'mainBobine') {
        type = StockType.rawMaterial;
      }

      items.add(StockItem(
        id: product.id,
        name: product.name,
        type: type,
        quantity: stockQty.toDouble(),
        unit: product.unit,
        enterpriseId: enterpriseId,
        updatedAt: DateTime.now(),
      ));
      
      if (product.role == 'mainBobine' || product.isRawMaterial) {
        totalMachineMaterials += stockQty;
      }
    }

    return StockState(
      items: items,
      availableMachineMaterials: totalMachineMaterials,
    );
  }

  /// Retourne le stock actuel pour un produit.
  Future<int> getStock(String productId) async {
    return _stockRepository.getStock(productId);
  }

  /// Enregistre une entrée de stock générique.
  Future<void> recordEntry({
    String? id,
    required String productId,
    required String productName,
    required double quantite,
    String? unit,
    String? raison,
    String? fournisseur,
    String? notes,
  }) async {
    if (quantite <= 0) throw const ValidationException('La quantité doit être positive.');

    await _stockRepository.recordMovement(StockMovement(
      id: id ?? '', // Généré par le repo si vide
      enterpriseId: enterpriseId,
      productId: productId,
      productName: productName,
      date: DateTime.now(),
      type: StockMovementType.entry,
      reason: raison ?? 'Livraison',
      quantity: quantite,
      unit: unit ?? 'unité',
      notes: notes,
    ));
  }

  /// Enregistre une sortie de stock générique.
  Future<void> recordExit({
    String? id,
    required String productId,
    required String productName,
    required double quantite,
    String? unit,
    String? raison,
    String? productionId,
    String? notes,
  }) async {
    if (quantite <= 0) throw const ValidationException('La quantité doit être positive.');

    // Vérifier le stock
    final current = await _stockRepository.getStock(productId);
    if (current < quantite) {
      throw ValidationException('Stock insuffisant pour $productName. Disponible: $current');
    }

    await _stockRepository.recordMovement(StockMovement(
      id: id ?? '', 
      enterpriseId: enterpriseId,
      productId: productId,
      productName: productName,
      date: DateTime.now(),
      type: StockMovementType.exit,
      reason: raison ?? 'Consommation',
      quantity: quantite,
      unit: unit ?? 'unité',
      productionId: productionId,
      notes: notes,
    ));
  }

  /// Enregistre une décrémentation lors du chargement d'une machine (Bobine, etc).
  Future<void> recordMachineLoadExit({
    String? id,
    required String productId,
    required String productName,
    required double quantite,
    required String machineId,
    String? usageId,
    String? productionId,
    String? notes,
  }) async {
    await recordExit(
      id: id,
      productId: productId,
      productName: productName,
      quantite: quantite,
      raison: 'Installation Machine $machineId',
      productionId: productionId,
      notes: '${notes ?? ""} [UsageID: $usageId]',
    );
  }

  /// Enregistre les consommations déclarées lors d'une production.
  Future<void> recordMaterialConsumptions({
    required List<MaterialConsumption> consumptions,
    required String productionId,
    String? notes,
  }) async {
    for (final consumption in consumptions) {
      if (consumption.quantity == 0) continue;
      
      // Idempotency: Use deterministic ID for material consumption
      final deterministicId = 'local_stk_cons_${productionId}_${consumption.productId}';
      
      await recordExit(
        id: deterministicId,
        productId: consumption.productId,
        productName: consumption.productName,
        quantite: consumption.quantity,
        unit: consumption.unit,
        productionId: productionId,
        raison: 'Déclaration Production',
        notes: notes,
      );
    }
  }

  /// Enregistre les produits finis produits lors d'une séance.
  Future<void> recordProductionOutput({
    required List<MaterialConsumption> producedItems,
    required String productionId,
    String? notes,
  }) async {
    for (final item in producedItems) {
      if (item.quantity == 0) continue;

      // Idempotency: Use deterministic ID for production output
      final deterministicId = 'local_stk_prod_${productionId}_${item.productId}';

      await recordEntry(
        id: deterministicId,
        productId: item.productId,
        productName: item.productName,
        quantite: item.quantity,
        unit: item.unit,
        raison: 'Production Journalière',
        notes: notes ?? 'Session ID: $productionId',
      );
    }
  }


  /// Récupère l'historique des mouvements pour un produit.
  Future<List<StockMovement>> fetchMovements({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _stockRepository.fetchMovements(
      productId: productId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

class StockState {
  const StockState({
    required this.items,
    required this.availableMachineMaterials,
  });

  final List<StockItem> items;
  final int availableMachineMaterials;

  int get totalStockQuantity =>
      items.fold(0, (sum, item) => sum + item.quantity.toInt());
}

