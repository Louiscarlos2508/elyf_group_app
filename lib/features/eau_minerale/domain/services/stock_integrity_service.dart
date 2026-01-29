import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/bobine_stock_movement.dart';
import '../../domain/entities/packaging_stock.dart';
import '../../domain/entities/packaging_stock_movement.dart';
import '../../domain/repositories/bobine_stock_quantity_repository.dart';
import '../../domain/repositories/packaging_stock_repository.dart';

/// Résultat d'une vérification d'intégrité du stock.
class StockIntegrityResult {
  const StockIntegrityResult({
    required this.isValid,
    required this.stockId,
    required this.stockType,
    required this.storedQuantity,
    required this.calculatedQuantity,
    this.discrepancy,
    this.movementsCount,
  });

  final bool isValid;
  final String stockId;
  final String stockType; // 'bobine' ou 'packaging'
  final int storedQuantity;
  final int calculatedQuantity;
  final int? discrepancy;
  final int? movementsCount;

  /// Différence entre la quantité stockée et calculée.
  int get difference => storedQuantity - calculatedQuantity;
}

/// Service de vérification d'intégrité des stocks.
///
/// Permet de :
/// - Vérifier que les quantités stockées correspondent à la somme des mouvements
/// - Détecter les corruptions de données
/// - Recalculer les quantités à partir des mouvements si nécessaire
class StockIntegrityService {
  StockIntegrityService({
    required this.bobineRepository,
    required this.packagingRepository,
  });

  final BobineStockQuantityRepository bobineRepository;
  final PackagingStockRepository packagingRepository;

  /// Vérifie l'intégrité de tous les stocks (bobines et emballages).
  ///
  /// Retourne une liste de résultats avec les incohérences détectées.
  Future<List<StockIntegrityResult>> verifyAllStocks() async {
    final results = <StockIntegrityResult>[];

    // Vérifier les stocks de bobines
    final bobineResults = await verifyBobineStocks();
    results.addAll(bobineResults);

    // Vérifier les stocks d'emballages
    final packagingResults = await verifyPackagingStocks();
    results.addAll(packagingResults);

    return results;
  }

  /// Vérifie l'intégrité des stocks de bobines.
  Future<List<StockIntegrityResult>> verifyBobineStocks() async {
    final results = <StockIntegrityResult>[];
    final stocks = await bobineRepository.fetchAll();

    for (final stock in stocks) {
      final result = await verifyBobineStock(stock);
      results.add(result);
    }

    return results;
  }

  /// Vérifie l'intégrité d'un stock de bobine spécifique.
  Future<StockIntegrityResult> verifyBobineStock(BobineStock stock) async {
    // Récupérer tous les mouvements pour ce stock
    final movements = await bobineRepository.fetchMovements(
      bobineStockId: stock.id,
    );

    // Calculer la quantité à partir des mouvements
    int calculatedQuantity = 0;
    for (final movement in movements) {
      switch (movement.type) {
        case BobineMovementType.entree:
          calculatedQuantity += movement.quantite.toInt();
          break;
        case BobineMovementType.sortie:
        case BobineMovementType.retrait:
          calculatedQuantity -= movement.quantite.toInt();
          break;
      }
    }

    // S'assurer que la quantité calculée n'est pas négative
    if (calculatedQuantity < 0) {
      calculatedQuantity = 0;
    }

    final discrepancy = stock.quantity - calculatedQuantity;
    final isValid = discrepancy == 0;

    return StockIntegrityResult(
      isValid: isValid,
      stockId: stock.id,
      stockType: 'bobine',
      storedQuantity: stock.quantity,
      calculatedQuantity: calculatedQuantity,
      discrepancy: isValid ? null : discrepancy,
      movementsCount: movements.length,
    );
  }

  /// Vérifie l'intégrité des stocks d'emballages.
  Future<List<StockIntegrityResult>> verifyPackagingStocks() async {
    final results = <StockIntegrityResult>[];
    final stocks = await packagingRepository.fetchAll();

    // fetchAll() déduplique déjà par remoteId et type, donc on peut vérifier directement
    for (final stock in stocks) {
      final result = await verifyPackagingStock(stock);
      results.add(result);
    }

    return results;
  }

  /// Vérifie l'intégrité d'un stock d'emballage spécifique.
  Future<StockIntegrityResult> verifyPackagingStock(
    PackagingStock stock,
  ) async {
    // Récupérer tous les mouvements pour ce stock
    final movements = await packagingRepository.fetchMovements(
      packagingId: stock.id,
    );

    // Calculer la quantité à partir des mouvements
    int calculatedQuantity = 0;
    for (final movement in movements) {
      switch (movement.type) {
        case PackagingMovementType.entree:
          calculatedQuantity += movement.quantite;
          break;
        case PackagingMovementType.sortie:
        case PackagingMovementType.ajustement:
          calculatedQuantity -= movement.quantite;
          break;
      }
    }

    // S'assurer que la quantité calculée n'est pas négative
    if (calculatedQuantity < 0) {
      calculatedQuantity = 0;
    }

    final discrepancy = stock.quantity - calculatedQuantity;
    final isValid = discrepancy == 0;

    return StockIntegrityResult(
      isValid: isValid,
      stockId: stock.id,
      stockType: 'packaging',
      storedQuantity: stock.quantity,
      calculatedQuantity: calculatedQuantity,
      discrepancy: isValid ? null : discrepancy,
      movementsCount: movements.length,
    );
  }

  /// Corrige un stock en recalculant sa quantité à partir des mouvements.
  ///
  /// Lance une exception si le stock n'est pas trouvé.
  Future<void> repairStock(StockIntegrityResult result) async {
    if (result.isValid) {
      AppLogger.info(
        'Stock ${result.stockId} is already valid, no repair needed',
        name: 'StockIntegrityService',
      );
      return;
    }

    try {
      switch (result.stockType) {
        case 'bobine':
          await _repairBobineStock(result);
          break;
        case 'packaging':
          await _repairPackagingStock(result);
          break;
        default:
          throw ValidationException(
            'Unknown stock type: ${result.stockType}',
            'UNKNOWN_STOCK_TYPE',
          );
      }

      AppLogger.info(
        'Stock ${result.stockId} repaired: ${result.storedQuantity} -> ${result.calculatedQuantity}',
        name: 'StockIntegrityService',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error repairing stock ${result.stockId}: $e',
        name: 'StockIntegrityService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _repairBobineStock(StockIntegrityResult result) async {
    final stock = await bobineRepository.fetchById(result.stockId);
    if (stock == null) {
      throw NotFoundException(
        'Bobine stock not found: ${result.stockId}',
        'STOCK_NOT_FOUND',
      );
    }

    final repairedStock = stock.copyWith(
      quantity: result.calculatedQuantity,
      updatedAt: DateTime.now(),
    );

    await bobineRepository.save(repairedStock);
  }

  Future<void> _repairPackagingStock(StockIntegrityResult result) async {
    // Récupérer tous les stocks pour trouver celui à réparer
    final allStocks = await packagingRepository.fetchAll();
    
    // Chercher le stock par ID (peut être remoteId ou localId)
    PackagingStock? stockToRepair;
    
    // Essayer d'abord par ID exact
    try {
      stockToRepair = allStocks.firstWhere(
        (s) => s.id == result.stockId,
      );
    } catch (_) {
      // Si pas trouvé, chercher par remoteId (si l'ID fourni est un remoteId)
      try {
        // Vérifier si l'ID est un remoteId en cherchant dans tous les stocks
        for (final stock in allStocks) {
          // Utiliser fetchById pour obtenir le remoteId réel
          final stockWithRemoteId = await packagingRepository.fetchById(result.stockId);
          if (stockWithRemoteId != null && stockWithRemoteId.id == stock.id) {
            stockToRepair = stock;
            break;
          }
        }
      } catch (_) {
        // Dernier recours : chercher par type
        try {
          stockToRepair = allStocks.firstWhere(
            (s) => s.type.toLowerCase() == result.stockType.toLowerCase(),
          );
        } catch (_) {
          throw NotFoundException(
            'Packaging stock not found: ${result.stockId}',
            'STOCK_NOT_FOUND',
          );
        }
      }
    }
    
    if (stockToRepair == null) {
      throw NotFoundException(
        'Packaging stock not found: ${result.stockId}',
        'STOCK_NOT_FOUND',
      );
    }

    // Vérifier s'il y a d'autres stocks avec le même remoteId
    // Note: La déduplication est déjà gérée dans getAllForEnterprise(),
    // donc on ne devrait pas avoir de doublons ici. Mais on vérifie quand même.
    final remoteId = _getRemoteIdForStock(stockToRepair);
    if (remoteId != null) {
      // Compter les stocks avec le même remoteId
      int duplicateCount = 0;
      for (final stock in allStocks) {
        if (stock.id != stockToRepair.id) {
          final otherRemoteId = _getRemoteIdForStock(stock);
          if (otherRemoteId == remoteId) {
            duplicateCount++;
          }
        }
      }
      
      if (duplicateCount > 0) {
        AppLogger.warning(
          'Found $duplicateCount duplicate stock(s) with remoteId $remoteId. '
          'They will be handled by getAllForEnterprise() deduplication.',
          name: 'StockIntegrityService',
        );
      }
    }

    final repairedStock = stockToRepair.copyWith(
      quantity: result.calculatedQuantity,
      updatedAt: DateTime.now(),
    );

    await packagingRepository.save(repairedStock);
  }
  
  /// Récupère le remoteId d'un stock en utilisant la logique du repository.
  String? _getRemoteIdForStock(PackagingStock stock) {
    // Utiliser la même logique que PackagingStockOfflineRepository.getRemoteId()
    // Si l'ID commence par 'local_packaging-', extraire l'ID sans le préfixe 'local_'
    if (stock.id.startsWith('local_packaging-')) {
      return stock.id.substring(6); // Enlever 'local_' pour obtenir 'packaging-...'
    }
    // Si l'ID ne commence pas par 'local_', c'est un remoteId
    if (!stock.id.startsWith('local_')) {
      return stock.id;
    }
    // Sinon, c'est un ID local généré, pas encore synchronisé
    return null;
  }

  /// Corrige automatiquement tous les stocks avec des incohérences.
  ///
  /// Retourne le nombre de stocks corrigés.
  Future<int> repairAllInvalidStocks() async {
    final results = await verifyAllStocks();
    final invalidStocks = results.where((r) => !r.isValid).toList();

    if (invalidStocks.isEmpty) {
      AppLogger.info(
        'All stocks are valid, no repair needed',
        name: 'StockIntegrityService',
      );
      return 0;
    }

    int repairedCount = 0;
    for (final result in invalidStocks) {
      try {
        await repairStock(result);
        repairedCount++;
      } catch (e) {
        AppLogger.error(
          'Failed to repair stock ${result.stockId}: $e',
          name: 'StockIntegrityService',
          error: e,
        );
        // Continue avec les autres stocks même si un échoue
      }
    }

    AppLogger.info(
      'Repaired $repairedCount out of ${invalidStocks.length} invalid stocks',
      name: 'StockIntegrityService',
    );

    return repairedCount;
  }
}
