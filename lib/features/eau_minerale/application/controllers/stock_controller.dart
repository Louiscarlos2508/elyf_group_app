import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/bobine_stock_movement.dart';
import '../../domain/entities/packaging_stock.dart';
import '../../domain/entities/packaging_stock_movement.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/bobine_stock_quantity_repository.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/repositories/packaging_stock_repository.dart';
import '../../domain/repositories/stock_repository.dart';

class StockController {
  StockController(
    this._inventoryRepository,
    this._bobineStockQuantityRepository,
    this._packagingStockRepository,
    this._stockRepository,
  );

  final InventoryRepository _inventoryRepository;
  final BobineStockQuantityRepository _bobineStockQuantityRepository;
  final PackagingStockRepository _packagingStockRepository;
  final StockRepository _stockRepository;

  Future<StockState> fetchSnapshot() async {
    final items = await _inventoryRepository.fetchStockItems();
    // Utiliser le nouveau système de stock par quantité
    final bobineStocks = await _bobineStockQuantityRepository.fetchAll();
    final totalBobines = bobineStocks.fold<int>(0, (sum, stock) => sum + stock.quantity);
    final packagingStocks = await _packagingStockRepository.fetchAll();
    final lowStockPackaging = await _packagingStockRepository.fetchLowStockAlerts();
    
    return StockState(
      items: items,
      availableBobines: totalBobines,
      bobineStocks: bobineStocks,
      packagingStocks: packagingStocks ?? const [],
      lowStockPackaging: lowStockPackaging ?? const [],
    );
  }

  /// Enregistre une entrée de bobine en stock (livraison).
  /// Utilise le nouveau système de stock par quantité.
  Future<void> recordBobineEntry({
    required String bobineType, // Type de bobine (ex: "Bobine standard")
    required int quantite, // Quantité en unités
    String? fournisseur,
    String? notes,
  }) async {
    // Récupérer ou créer le stock
    var stock = await _bobineStockQuantityRepository.fetchByType(bobineType);
    if (stock == null) {
      stock = BobineStock(
        id: 'bobine-stock-${DateTime.now().millisecondsSinceEpoch}',
        type: bobineType,
        quantity: 0,
        unit: 'unité',
        fournisseur: fournisseur,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Enregistrer le mouvement
    final movement = BobineStockMovement(
      id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
      bobineId: stock.id,
      bobineReference: bobineType,
      type: BobineMovementType.entree,
      date: DateTime.now(),
      quantite: quantite.toDouble(),
      raison: 'Livraison',
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _bobineStockQuantityRepository.recordMovement(movement);

    // Mettre à jour le stock
    final updatedStock = stock.copyWith(
      quantity: stock.quantity + quantite,
      fournisseur: fournisseur ?? stock.fournisseur,
      updatedAt: DateTime.now(),
    );
    await _bobineStockQuantityRepository.save(updatedStock);
  }


  /// Enregistre une sortie de bobine du stock (installation en production).
  /// Utilise le nouveau système de stock par quantité.
  /// [productionId] est optionnel car lors de l'installation, la session peut ne pas être encore créée.
  Future<void> recordBobineExit({
    required String bobineType, // Type de bobine (ex: "Bobine standard")
    required int quantite, // Quantité en unités (généralement 1)
    String? productionId, // Optionnel car peut être null lors de l'installation immédiate
    required String machineId,
    String? notes,
  }) async {
    // Récupérer le stock de bobines
    var stock = await _bobineStockQuantityRepository.fetchByType(bobineType);
    if (stock == null) {
      throw Exception('Stock de bobine non trouvé pour le type: $bobineType');
    }

    // Vérifier que le stock est suffisant
    if (!stock.peutSatisfaire(quantite)) {
      throw Exception(
        'Stock insuffisant. Disponible: ${stock.quantity}, Demandé: $quantite',
      );
    }

    // Enregistrer le mouvement
    final movement = BobineStockMovement(
      id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
      bobineId: stock.id, // Utiliser l'ID du stock au lieu d'une bobine individuelle
      bobineReference: bobineType,
      type: BobineMovementType.sortie,
      date: DateTime.now(),
      quantite: quantite.toDouble(),
      raison: 'Installation en production',
      productionId: productionId,
      machineId: machineId,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _bobineStockQuantityRepository.recordMovement(movement);

    // Mettre à jour le stock
    final updatedStock = stock.copyWith(
      quantity: stock.quantity - quantite,
      updatedAt: DateTime.now(),
    );
    await _bobineStockQuantityRepository.save(updatedStock);
  }


  /// Enregistre un retrait de bobine après utilisation complète.
  /// Avec le nouveau système par quantité, le stock est déjà décrémenté lors de l'installation.
  /// Cette méthode enregistre juste un mouvement pour l'historique.
  Future<void> recordBobineRemoval({
    required String bobineType,
    required String productionId,
    String? notes,
  }) async {
    // Récupérer le stock pour obtenir l'ID
    final stock = await _bobineStockQuantityRepository.fetchByType(bobineType);
    if (stock == null) {
      // Si le stock n'existe pas, on enregistre quand même le mouvement pour l'historique
      // avec un ID temporaire
      final movement = BobineStockMovement(
        id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
        bobineId: 'unknown',
        bobineReference: bobineType,
        type: BobineMovementType.retrait,
        date: DateTime.now(),
        quantite: 0, // Le stock est déjà décrémenté lors de l'installation
        raison: 'Retrait après utilisation complète',
        productionId: productionId,
        notes: notes,
        createdAt: DateTime.now(),
      );
      await _bobineStockQuantityRepository.recordMovement(movement);
      return;
    }
    
    final movement = BobineStockMovement(
      id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
      bobineId: stock.id,
      bobineReference: bobineType,
      type: BobineMovementType.retrait,
      date: DateTime.now(),
      quantite: 0, // Le stock est déjà décrémenté lors de l'installation
      raison: 'Retrait après utilisation complète',
      productionId: productionId,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _bobineStockQuantityRepository.recordMovement(movement);
  }

  /// Enregistre une utilisation d'emballages lors de la finalisation d'une production.
  Future<void> recordPackagingUsage({
    required String packagingId,
    required String packagingType,
    required int quantite,
    required String productionId,
    String? notes,
  }) async {
    // Récupérer le stock actuel
    final stock = await _packagingStockRepository.fetchById(packagingId);
    if (stock == null) {
      throw Exception('Stock d\'emballage non trouvé: $packagingId');
    }

    // Vérifier que le stock est suffisant
    if (!stock.peutSatisfaire(quantite)) {
      throw Exception(
        'Stock insuffisant. Disponible: ${stock.quantity}, Demandé: $quantite',
      );
    }

    // Enregistrer le mouvement
    final movement = PackagingStockMovement(
      id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
      packagingId: packagingId,
      packagingType: packagingType,
      type: PackagingMovementType.sortie,
      date: DateTime.now(),
      quantite: quantite,
      raison: 'Utilisation en production',
      productionId: productionId,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _packagingStockRepository.recordMovement(movement);

    // Mettre à jour le stock
    final updatedStock = stock.copyWith(
      quantity: stock.quantity - quantite,
      updatedAt: DateTime.now(),
    );
    await _packagingStockRepository.save(updatedStock);
  }

  /// Enregistre une entrée d'emballages en stock (livraison).
  Future<void> recordPackagingEntry({
    required String packagingId,
    required String packagingType,
    required int quantite,
    String? fournisseur,
    String? notes,
  }) async {
    // Récupérer ou créer le stock
    var stock = await _packagingStockRepository.fetchById(packagingId);
    if (stock == null) {
      stock = PackagingStock(
        id: packagingId,
        type: packagingType,
        quantity: 0,
        unit: 'packs',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Enregistrer le mouvement
    final movement = PackagingStockMovement(
      id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
      packagingId: packagingId,
      packagingType: packagingType,
      type: PackagingMovementType.entree,
      date: DateTime.now(),
      quantite: quantite,
      raison: 'Livraison',
      fournisseur: fournisseur,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _packagingStockRepository.recordMovement(movement);

    // Mettre à jour le stock
    final updatedStock = stock.copyWith(
      quantity: stock.quantity + quantite,
      updatedAt: DateTime.now(),
    );
    await _packagingStockRepository.save(updatedStock);
  }

  /// Récupère les alertes de stock faible.
  Future<List<PackagingStock>> getLowStockAlerts() async {
    return await _packagingStockRepository.fetchLowStockAlerts();
  }

  /// Récupère tous les mouvements de stock (bobines, emballages) combinés.
  Future<List<StockMovement>> fetchAllMovements({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Récupérer tous les mouvements de bobines depuis toutes les sessions
    // Note: fetchMovements de BobineStockQuantityRepository nécessite bobineStockId
    // On récupère tous les stocks et leurs mouvements
    final bobineStocks = await _bobineStockQuantityRepository.fetchAll();
    final List<BobineStockMovement> bobineMovements = [];
    for (final stock in bobineStocks) {
      final movements = await _bobineStockQuantityRepository.fetchMovements(
        bobineStockId: stock.id,
        startDate: startDate,
        endDate: endDate,
      );
      bobineMovements.addAll(movements);
    }
    
    final packagingMovements = await _packagingStockRepository.fetchMovements(
      startDate: startDate,
      endDate: endDate,
    );
    
    // Convertir les mouvements de bobines
    final unifiedBobineMovements = bobineMovements.map((m) {
      return StockMovement(
        id: m.id,
        date: m.date,
        productName: 'Bobine ${m.bobineReference}',
        type: _convertBobineMovementType(m.type),
        reason: m.raison,
        quantity: m.quantite.toDouble(),
        unit: 'unité',
        productionId: m.productionId,
        notes: m.notes,
      );
    }).toList();
    
    // Convertir les mouvements d'emballages
    final unifiedPackagingMovements = packagingMovements.map((m) {
      return StockMovement(
        id: m.id,
        date: m.date,
        productName: m.packagingType,
        type: _convertPackagingMovementType(m.type),
        reason: m.raison,
        quantity: m.quantite.toDouble(),
        unit: 'unité',
        productionId: m.productionId,
        notes: m.notes,
      );
    }).toList();
    
    // Récupérer les mouvements de ventes depuis StockRepository
    final saleMovements = await _stockRepository.fetchMovements(
      productId: null, // Récupérer tous les produits
      startDate: startDate,
      endDate: endDate,
    );
    
    // Combiner tous les mouvements et trier par date (plus récent en premier)
    final allMovements = [
      ...unifiedBobineMovements,
      ...unifiedPackagingMovements,
      ...saleMovements,
    ];
    allMovements.sort((a, b) => b.date.compareTo(a.date));
    
    return allMovements;
  }

  StockMovementType _convertBobineMovementType(BobineMovementType type) {
    switch (type) {
      case BobineMovementType.entree:
        return StockMovementType.entry;
      case BobineMovementType.sortie:
      case BobineMovementType.retrait:
        return StockMovementType.exit;
    }
  }

  StockMovementType _convertPackagingMovementType(PackagingMovementType type) {
    switch (type) {
      case PackagingMovementType.entree:
        return StockMovementType.entry;
      case PackagingMovementType.sortie:
      case PackagingMovementType.ajustement:
        return StockMovementType.exit;
    }
  }

  /// Enregistre une opération de stock (entrée/sortie) pour un StockItem.
  Future<void> recordItemMovement({
    required String itemId,
    required String itemName,
    required StockMovementType type,
    required double quantity,
    required String unit,
    required String reason,
    String? notes,
  }) async {
    // Récupérer l'item actuel
    final item = await _inventoryRepository.fetchStockItemById(itemId);
    if (item == null) {
      throw Exception('Item non trouvé: $itemId');
    }

    // Calculer la nouvelle quantité
    final newQuantity = type == StockMovementType.entry
        ? item.quantity + quantity
        : item.quantity - quantity;

    if (newQuantity < 0) {
      throw Exception(
        'Stock insuffisant. Stock actuel: ${item.quantity} $unit, '
        'Demandé: $quantity $unit',
      );
    }

    // Mettre à jour le stock
    final updatedItem = StockItem(
      id: item.id,
      name: item.name,
      quantity: newQuantity,
      unit: item.unit,
      type: item.type,
      updatedAt: DateTime.now(),
    );
    await _inventoryRepository.updateStockItem(updatedItem);
  }

  /// Ajoute des produits finis (packs) au stock lors de la finalisation d'une production.
  Future<void> recordFinishedGoodsProduction({
    required int quantiteProduite,
    required String productionId,
    String? notes,
  }) async {
    // Récupérer tous les stocks pour trouver le stock de produits finis
    final stockItems = await _inventoryRepository.fetchStockItems();
    
    // Chercher le stock de produits finis (packs)
    StockItem? finishedGoodsStock;
    try {
      finishedGoodsStock = stockItems.firstWhere(
        (item) => item.type == StockType.finishedGoods &&
            (item.name.toLowerCase().contains('pack') ||
             item.name.toLowerCase().contains('sachet')),
      );
    } catch (_) {
      // Si pas trouvé avec "pack" ou "sachet", chercher n'importe quel produit fini
      try {
        finishedGoodsStock = stockItems.firstWhere(
          (item) => item.type == StockType.finishedGoods,
        );
      } catch (_) {
        // Aucun stock de produits finis trouvé, on en créera un nouveau
      }
    }
    
    if (finishedGoodsStock == null) {
      // Créer un nouveau stock de produits finis si aucun n'existe
      finishedGoodsStock = StockItem(
        id: 'pack-1',
        name: 'Pack',
        quantity: quantiteProduite.toDouble(),
        unit: 'unité',
        type: StockType.finishedGoods,
        updatedAt: DateTime.now(),
      );
    } else {
      // Mettre à jour le stock existant en ajoutant la quantité produite
      finishedGoodsStock = StockItem(
        id: finishedGoodsStock.id,
        name: finishedGoodsStock.name,
        quantity: finishedGoodsStock.quantity + quantiteProduite.toDouble(),
        unit: finishedGoodsStock.unit,
        type: finishedGoodsStock.type,
        updatedAt: DateTime.now(),
      );
    }
    
    // Sauvegarder la mise à jour
    await _inventoryRepository.updateStockItem(finishedGoodsStock);
  }
}

class StockState {
  const StockState({
    required this.items,
    required this.availableBobines,
    this.bobineStocks = const [],
    this.packagingStocks = const [],
    this.lowStockPackaging = const [],
  });

  final List<StockItem> items;
  final int availableBobines; // Nombre total de bobines disponibles (somme des quantités)
  final List<BobineStock> bobineStocks; // Stocks de bobines par type
  final List<PackagingStock> packagingStocks; // Stocks d'emballages
  final List<PackagingStock> lowStockPackaging; // Stocks d'emballages avec alerte

  StockItem? get finishedGoods {
    final finishedGoodsItems = items.where((i) => i.type == StockType.finishedGoods);
    return finishedGoodsItems.isNotEmpty ? finishedGoodsItems.first : null;
  }
}
