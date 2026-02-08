import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/bobine_stock.dart';
import '../../domain/pack_constants.dart';
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
    final totalBobines = bobineStocks.fold<int>(
      0,
      (sum, stock) => sum + stock.quantity,
    );
    final packagingStocks = await _packagingStockRepository.fetchAll();
    final lowStockPackaging = await _packagingStockRepository
        .fetchLowStockAlerts();

    return StockState(
      items: items,
      availableBobines: totalBobines,
      bobineStocks: bobineStocks,
      packagingStocks: packagingStocks,
      lowStockPackaging: lowStockPackaging,
    );
  }

  /// Enregistre une entrée de bobine en stock (livraison).
  /// Utilise le nouveau système de stock par quantité.
  Future<void> recordBobineEntry({
    required String bobineType, // Type de bobine (ex: "Bobine standard")
    required int quantite, // Quantité en unités
    int? prixUnitaire, // Optionnel
    String? fournisseur,
    String? notes,
  }) async {
    // Validation des paramètres
    if (bobineType.trim().isEmpty) {
      throw ValidationException('Le type de bobine est requis.');
    }
    if (quantite <= 0 || quantite > 1000000) {
      throw ValidationException(
        'La quantité de bobines doit être un nombre entier positif et inférieur à 1 000 000.',
      );
    }

    // Récupérer ou créer le stock (sans le sauvegarder encore)
    var stock = await _bobineStockQuantityRepository.fetchByType(bobineType);
    final isNewStock = stock == null;
    
    // Utiliser l'ID du stock existant s'il existe, sinon créer un ID fixe basé sur le type
    // Cela garantit qu'on utilise toujours le même stock pour le même type
    final stockId = stock?.id ?? 'bobine-${bobineType.toLowerCase().replaceAll(' ', '-')}';
    
    if (isNewStock) {
      // Créer le stock en mémoire seulement (ne pas sauvegarder avec quantity: 0)
      stock = BobineStock(
        id: stockId, // ID fixe basé sur le type pour garantir la cohérence
        type: bobineType,
        quantity: 0, // Sera mis à jour par recordMovement
        unit: 'unité',
        fournisseur: fournisseur,
        prixUnitaire: prixUnitaire,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else if (prixUnitaire != null) {
      // Mettre à jour le prix unitaire si fourni
      stock = stock.copyWith(
        prixUnitaire: prixUnitaire,
        updatedAt: DateTime.now(),
      );
    }

    // Enregistrer le mouvement (qui créera le stock s'il est nouveau et mettra à jour la quantité)
    final movement = BobineStockMovement(
      id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
      bobineId: stockId, // Utiliser l'ID du stock (existant ou nouvellement créé)
      bobineReference: bobineType,
      type: BobineMovementType.entree,
      date: DateTime.now(),
      quantite: quantite.toDouble(),
      raison: 'Livraison',
      notes: notes,
      createdAt: DateTime.now(),
    );
    // recordMovement créera le stock s'il est nouveau et mettra automatiquement à jour le stock
    // Il utilise maintenant save() au lieu de saveToLocal + queue sync, comme pour les emballages
    await _bobineStockQuantityRepository.recordMovement(movement);
  }

  /// Enregistre une sortie de bobine du stock (installation en production).
  /// Utilise le nouveau système de stock par quantité.
  /// [productionId] est optionnel car lors de l'installation, la session peut ne pas être encore créée.
  Future<void> recordBobineExit({
    required String bobineType, // Type de bobine (ex: "Bobine standard")
    required int quantite, // Quantité en unités (généralement 1)
    String?
    productionId, // Optionnel car peut être null lors de l'installation immédiate
    required String machineId,
    String? notes,
  }) async {
    // Récupérer le stock de bobines
    var stock = await _bobineStockQuantityRepository.fetchByType(bobineType);
    if (stock == null) {
      throw NotFoundException('Stock de bobine non trouvé pour le type: $bobineType');
    }

    // Vérifier que le stock est suffisant
    if (!stock.peutSatisfaire(quantite)) {
      throw ValidationException(
        'Stock insuffisant. Disponible: ${stock.quantity}, Demandé: $quantite',
      );
    }

    // Enregistrer le mouvement (qui mettra automatiquement à jour le stock)
    final movement = BobineStockMovement(
      id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
      bobineId:
          stock.id, // Utiliser l'ID du stock au lieu d'une bobine individuelle
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
    // recordMovement met automatiquement à jour le stock, donc pas besoin de save après
    await _bobineStockQuantityRepository.recordMovement(movement);
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
      throw NotFoundException('Stock d\'emballage non trouvé: $packagingId');
    }

    // Vérifier que le stock est suffisant
    if (!stock.peutSatisfaire(quantite)) {
      throw ValidationException(
        'Stock insuffisant. Disponible: ${stock.quantity}, Demandé: $quantite',
      );
    }

    // Enregistrer le mouvement
    // recordMovement met automatiquement à jour le stock (comme pour les bobines)
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
    // recordMovement met automatiquement à jour le stock, donc pas besoin de save après
    await _packagingStockRepository.recordMovement(movement);
  }

  /// Enregistre une entrée d'emballages en stock (livraison).
  Future<void> recordPackagingEntry({
    required String packagingId,
    required String packagingType,
    required int quantite,
    int? prixUnitaire, // Optionnel
    bool isInLots = false, // Vrai si la quantité fournie est en lots
    int? unitsPerLot, // Facteur de conversion explicite
    String? fournisseur,
    String? notes,
  }) async {
    // Validation des paramètres
    if (packagingId.trim().isEmpty) {
      throw ValidationException('L\'ID d\'emballage est requis.');
    }
    if (packagingType.trim().isEmpty) {
      throw ValidationException('Le type d\'emballage est requis.');
    }
    if (quantite <= 0 || quantite > 1000000) {
      throw ValidationException(
        'La quantité d\'emballages doit être un nombre entier positif et inférieur à 1 000 000.',
      );
    }

    // Utiliser un ID fixe basé sur le type pour garantir la cohérence
    final fixedPackagingId = packagingId.isEmpty 
        ? 'packaging-${packagingType.toLowerCase().replaceAll(' ', '-')}'
        : packagingId;
    
    // Récupérer le stock existant
    var stock = await _packagingStockRepository.fetchById(fixedPackagingId);
    final isNewStock = stock == null;
    
    // Déterminer le facteur de conversion
    // Priorité : Argument explicite > Stock existant > Défaut (1)
    final conversionFactor = unitsPerLot ?? (stock?.unitsPerLot ?? 1);
    
    // Calculer la quantité finale en unités
    int finalQuantityUnits = quantite;
    if (isInLots) {
      finalQuantityUnits = quantite * conversionFactor;
    }

    if (isNewStock) {
      // Créer le stock en mémoire seulement
      stock = PackagingStock(
        id: fixedPackagingId,
        type: packagingType,
        quantity: 0,
        unit: 'unité',
        unitsPerLot: conversionFactor, 
        fournisseur: fournisseur,
        prixUnitaire: prixUnitaire,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      // Préparer la mise à jour
      var updated = false;
      var newStock = stock;
      
      if (prixUnitaire != null) {
        newStock = newStock.copyWith(prixUnitaire: prixUnitaire);
        updated = true;
      }
      
      // Mettre à jour le facteur de lot si fourni change
      if (unitsPerLot != null && unitsPerLot != newStock.unitsPerLot) {
        newStock = newStock.copyWith(unitsPerLot: unitsPerLot);
        updated = true;
      }
      
      if (updated) {
        stock = newStock;
        newStock = newStock.copyWith(updatedAt: DateTime.now());
        await _packagingStockRepository.save(newStock);
      }
    }

    // Enregistrer le mouvement
    final movement = PackagingStockMovement(
      id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
      packagingId: fixedPackagingId,
      packagingType: packagingType,
      type: PackagingMovementType.entree,
      date: DateTime.now(),
      quantite: finalQuantityUnits, // Toujours stocker en UNITÉS
      isInLots: isInLots,
      quantiteSaisie: quantite,
      raison: 'Livraison',
      fournisseur: fournisseur,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _packagingStockRepository.recordMovement(movement);
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

    // Log pour déboguer
    developer.log(
      'Fetched ${bobineMovements.length} bobine movements and ${packagingMovements.length} packaging movements',
      name: 'StockController.fetchAllMovements',
    );

    // Convertir les mouvements de bobines
    final unifiedBobineMovements = bobineMovements.map((m) {
      return StockMovement(
        id: m.id,
        date: m.date,
        productName: m.bobineReference, // bobineReference est déjà "Bobine"
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
    
    developer.log(
      'Converted to ${unifiedBobineMovements.length} unified bobine movements and ${unifiedPackagingMovements.length} unified packaging movements',
      name: 'StockController.fetchAllMovements',
    );

    // Récupérer les mouvements de produits finis (ajustements, ventes) depuis StockRepository
    final stockItemMovements = await _stockRepository.fetchMovements(
      productId: null, // Récupérer tous les produits
      startDate: startDate,
      endDate: endDate,
    );

    // Combiner tous les mouvements et trier par date (plus récent en premier)
    final allMovements = [
      ...unifiedBobineMovements,
      ...unifiedPackagingMovements,
      ...stockItemMovements,
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
      throw NotFoundException(
        'Item non trouvé: $itemId',
        'STOCK_ITEM_NOT_FOUND',
      );
    }

    // Calculer la nouvelle quantité
    final newQuantity = type == StockMovementType.entry
        ? item.quantity + quantity
        : item.quantity - quantity;

    if (newQuantity < 0) {
      throw ValidationException(
        'Stock insuffisant. Stock actuel: ${item.quantity} $unit, '
        'Demandé: $quantity $unit',
        'INSUFFICIENT_STOCK',
      );
    }

    // Enregistrer le mouvement dans l'historique
    final movement = StockMovement(
      id: 'movement-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      productName: itemName,
      type: type,
      reason: reason,
      quantity: quantity,
      unit: unit,
      notes: notes,
    );
    await _stockRepository.recordMovement(movement);

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

    // Chercher le stock de produits finis (le Pack ou équivalent)
    StockItem? finishedGoodsStock;
    try {
      // 1. Chercher par ID pack-1
      finishedGoodsStock = stockItems.firstWhere((i) => i.id == packStockItemId);
    } catch (_) {
      try {
        // 2. Chercher par type PF et nom contenant 'pack'
        finishedGoodsStock = stockItems.firstWhere(
          (item) =>
              item.type == StockType.finishedGoods &&
              item.name.toLowerCase().contains('pack'),
        );
      } catch (_) {
        // 3. Si un seul item fini existe, c'est lui
        final allFG = stockItems.where((i) => i.type == StockType.finishedGoods).toList();
        if (allFG.length == 1) {
          finishedGoodsStock = allFG.first;
        }
      }
    }

    if (finishedGoodsStock == null) {
      finishedGoodsStock = StockItem(
        id: packStockItemId,
        name: packName,
        quantity: quantiteProduite.toDouble(),
        unit: packUnit,
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

  /// Retourne le StockItem approprié (Pack ou produit fini spécifié).
  /// Crée le Pack par défaut s'il n'y a rien du tout.
  Future<StockItem> ensurePackStockItem({String? productId}) async {
    final stockItems = await _inventoryRepository.fetchStockItems();
    
    // 1. Si productId fourni, chercher l'item exact
    if (productId != null) {
      try {
        return stockItems.firstWhere((i) => i.id == productId);
      } catch (_) {
        // Continue
      }
    }

    // 2. Chercher par ID pack-1 ou nom contenant 'pack'
    final packs = stockItems
        .where(
          (i) =>
              i.type == StockType.finishedGoods &&
              (i.id == packStockItemId || i.name.toLowerCase().contains('pack')),
        )
        .toList();
    
    if (packs.isNotEmpty) {
      return packs.any((i) => i.id == packStockItemId)
          ? packs.firstWhere((i) => i.id == packStockItemId)
          : packs.first;
    }

    // 3. Fallback: Si un seul item fini existe, c'est lui
    final allFG = stockItems.where((i) => i.type == StockType.finishedGoods).toList();
    if (allFG.length == 1) return allFG.first;

    // 4. Création d'un item Pack par défaut si rien trouvé
    final created = StockItem(
      id: packStockItemId,
      name: packName,
      quantity: 0,
      unit: packUnit,
      type: StockType.finishedGoods,
      updatedAt: DateTime.now(),
    );
    await _inventoryRepository.updateStockItem(created);
    return created;
  }

  /// Quantité Pack calculée depuis les mouvements (entrées − sorties).
  Future<double> computePackQuantityFromMovements() async {
    final movements = await fetchAllMovements();
    final pack =
        movements.where((m) => m.productName == packName).toList();
    double qty = 0;
    for (final m in pack) {
      if (m.type == StockMovementType.entry) {
        qty += m.quantity;
      } else {
        qty -= m.quantity;
      }
    }
    return qty;
  }

  /// Recalcule Pack.quantity depuis les mouvements et met à jour l'inventaire si
  /// différent. Utile quand suivi (journalier) affiche 151 mais stock Pack = 1.
  Future<bool> reconcilePackQuantityFromMovements() async {
    final pack = await ensurePackStockItem();
    final expected = await computePackQuantityFromMovements();
    if (expected < 0 || pack.quantity == expected) return false;
    final updated = StockItem(
      id: pack.id,
      name: pack.name,
      quantity: expected,
      unit: pack.unit,
      type: pack.type,
      updatedAt: DateTime.now(),
    );
    await _inventoryRepository.updateStockItem(updated);
    return true;
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
  final int
  availableBobines; // Nombre total de bobines disponibles (somme des quantités)
  final List<BobineStock> bobineStocks; // Stocks de bobines par type
  final List<PackagingStock> packagingStocks; // Stocks d'emballages
  final List<PackagingStock>
  lowStockPackaging; // Stocks d'emballages avec alerte

  StockItem? get finishedGoods {
    final finishedGoodsItems = items.where(
      (i) => i.type == StockType.finishedGoods,
    );
    return finishedGoodsItems.isNotEmpty ? finishedGoodsItems.first : null;
  }
}
