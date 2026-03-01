import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/collection_names.dart';
import '../../domain/entities/packaging_stock.dart';
import '../../domain/entities/packaging_stock_movement.dart';
import '../../domain/repositories/packaging_stock_repository.dart';

/// Offline-first repository for PackagingStock entities.
class PackagingStockOfflineRepository extends OfflineRepository<PackagingStock>
    implements PackagingStockRepository {
  PackagingStockOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => CollectionNames.packagingStocks;

  String get movementsCollection => CollectionNames.packagingStockMovements;

  @override
  PackagingStock fromMap(Map<String, dynamic> map) =>
      PackagingStock.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(PackagingStock entity) => entity.toMap();

  @override
  String getLocalId(PackagingStock entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    // If it's a fixed ID or a catalog ID, prefix it with local_ to mark it as local
    // This makes ID generation deterministic for the same input ID
    return 'local_${entity.id}';
  }

  @override
  String? getRemoteId(PackagingStock entity) {
    // Si l'ID commence par 'local_packaging-', extraire l'ID sans le préfixe 'local_'
    // pour permettre la synchronisation vers Firestore
    if (entity.id.startsWith('local_packaging-')) {
      return entity.id.substring(6); // Enlever 'local_' pour obtenir 'packaging-...'
    }
    // Si l'ID ne commence pas par 'local_', c'est un remoteId
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    // Sinon, c'est un ID local généré, pas encore synchronisé
    return null;
  }

  @override
  String? getEnterpriseId(PackagingStock entity) => enterpriseId;

  @override
  Future<void> saveToLocal(PackagingStock entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(PackagingStock entity, {String? userId}) async {
    // Soft-delete
    final deletedPackaging = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveToLocal(deletedPackaging, userId: syncManager.getUserId() ?? '');
    
    AppLogger.info(
      'Soft-deleted packaging stock: ${entity.id}',
      name: 'PackagingStockOfflineRepository',
    );
  }

  @override
  Future<PackagingStock?> getByLocalId(String localId) async {
    // Essayer d'abord par remoteId (au cas où l'ID fourni est un remoteId)
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      final stock = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return stock.isDeleted ? null : stock;
    }
    
    // Chercher par localId
    // Note: Si plusieurs enregistrements existent (doublons), prendre le plus récent
    final records = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    
    // Filtrer par localId et prendre le plus récent en cas de doublons
    final matchingRecords = records.where((r) => r.localId == localId).toList();
    
    if (matchingRecords.isEmpty) return null;
    
    // Si plusieurs enregistrements avec le même localId, prendre le plus récent
    if (matchingRecords.length > 1) {
      matchingRecords.sort((a, b) => 
        b.localUpdatedAt.compareTo(a.localUpdatedAt)
      );
      // Logger un avertissement pour détecter les doublons
      AppLogger.warning(
        'Multiple records found with localId $localId (${matchingRecords.length} duplicates), using most recent. Consider cleaning duplicates.',
        name: 'PackagingStockOfflineRepository',
      );
    }
    
    final record = matchingRecords.first;
    
    // Si des doublons existent, supprimer les anciens (garder seulement le plus récent)
    if (matchingRecords.length > 1) {
      // Supprimer les doublons (sauf le premier qui est le plus récent)
      for (var i = 1; i < matchingRecords.length; i++) {
        try {
          await driftService.records.deleteByLocalId(
            collectionName: collectionName,
            localId: matchingRecords[i].localId,
            enterpriseId: enterpriseId,
            moduleType: moduleType,
          );
        } catch (e) {
          // Logger mais continuer même si la suppression échoue
          AppLogger.warning(
            'Failed to delete duplicate record ${matchingRecords[i].localId}: $e',
            name: 'PackagingStockOfflineRepository',
            error: e,
          );
        }
      }
    }
    
    final stock = fromMap(jsonDecode(record.dataJson) as Map<String, dynamic>);
    return stock.isDeleted ? null : stock;
  }

  @override
  Future<List<PackagingStock>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows
        .map((r) {
          final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
          // Ajouter localId et remoteId au map pour la déduplication
          map['localId'] = r.localId;
          if (r.remoteId != null) {
            map['id'] = r.remoteId; // Utiliser remoteId comme ID principal
          }
          return fromMap(map);
        })
        .where((s) => !s.isDeleted)
        .toList();

    // Dédupliquer par remoteId d'abord (garde le plus récent pour chaque remoteId)
    // IMPORTANT: Ne PAS additionner les quantités - si plusieurs enregistrements ont le même remoteId,
    // ce sont des doublons et on doit garder seulement le plus récent
    final Map<String, PackagingStock> stocksByRemoteId = {};
    final List<PackagingStock> stocksWithoutRemoteId = [];
    
    for (final stock in entities) {
      final remoteId = getRemoteId(stock);
      if (remoteId != null && remoteId.isNotEmpty) {
        // Si on a déjà vu ce remoteId, garder seulement le plus récent (ne PAS additionner)
        if (stocksByRemoteId.containsKey(remoteId)) {
          final existing = stocksByRemoteId[remoteId]!;
          final existingUpdatedAt = existing.updatedAt ?? DateTime(1970);
          final stockUpdatedAt = stock.updatedAt ?? DateTime(1970);
          
          // Garder seulement le plus récent (c'est un doublon, pas une addition)
          if (stockUpdatedAt.isAfter(existingUpdatedAt)) {
            stocksByRemoteId[remoteId] = stock;
          }
          // Sinon, garder l'existant (déjà le plus récent)
        } else {
          stocksByRemoteId[remoteId] = stock;
        }
      } else {
        // Stocks sans remoteId : garder tous (créés localement)
        stocksWithoutRemoteId.add(stock);
      }
    }

    // IMPORTANT: Ne PAS fusionner par type si les stocks ont des remoteId différents
    // Chaque stock avec un remoteId unique doit être conservé séparément
    // La fusion par type n'est valide que si les stocks représentent le même document Firestore
    
    // Si plusieurs stocks avec le même remoteId existent, ils ont déjà été fusionnés ci-dessus
    // Maintenant, on garde tous les stocks uniques (par remoteId ou localId)
    final List<PackagingStock> finalStocks = [];
    
    // Ajouter tous les stocks avec remoteId (déjà dédupliqués par remoteId)
    finalStocks.addAll(stocksByRemoteId.values);
    
    // Ajouter les stocks sans remoteId (créés localement, pas encore synchronisés)
    finalStocks.addAll(stocksWithoutRemoteId);

    return finalStocks;
  }

  // PackagingStockRepository implementation

  @override
  Future<List<PackagingStock>> fetchAll() async {
    try {
      return await getAllForEnterprise(enterpriseId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching packaging stocks: ${appException.message}',
        name: 'PackagingStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<PackagingStock?> fetchById(String id) async {
    try {
      // Récupérer tous les enregistrements pour gérer les doublons
      final records = await driftService.records.listForEnterprise(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      
      // Chercher par remoteId d'abord
      final matchingByRemote = records.where((r) => r.remoteId == id).toList();
      if (matchingByRemote.isNotEmpty) {
        // Si plusieurs enregistrements avec le même remoteId, prendre le plus récent
        if (matchingByRemote.length > 1) {
          matchingByRemote.sort((a, b) => 
            b.localUpdatedAt.compareTo(a.localUpdatedAt)
          );
          AppLogger.warning(
            'Multiple records found with remoteId $id (${matchingByRemote.length} duplicates), using most recent.',
            name: 'PackagingStockOfflineRepository',
          );
          // Supprimer les doublons (garder seulement le plus récent)
          for (var i = 1; i < matchingByRemote.length; i++) {
            try {
              await driftService.records.deleteByLocalId(
                collectionName: collectionName,
                localId: matchingByRemote[i].localId,
                enterpriseId: enterpriseId,
                moduleType: moduleType,
              );
            } catch (e) {
              AppLogger.warning(
                'Failed to delete duplicate record ${matchingByRemote[i].localId}: $e',
                name: 'PackagingStockOfflineRepository',
                error: e,
              );
            }
          }
        }
        final record = matchingByRemote.first;
        final stock = fromMap(jsonDecode(record.dataJson) as Map<String, dynamic>);
        return stock.isDeleted ? null : stock;
      }
      
      // Chercher par localId
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching packaging stock: $id - ${appException.message}',
        name: 'PackagingStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<PackagingStock?> fetchByType(String type) async {
    try {
      final stocks = await fetchAll();
      try {
        return stocks.firstWhere((s) => s.type == type);
      } catch (_) {
        return null;
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching packaging stock by type: $type - ${appException.message}',
        name: 'PackagingStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<PackagingStock> save(PackagingStock entity) async {
    try {
      final localId = getLocalId(entity);
      final stockWithLocalId = entity.copyWith(
        id: localId,
        updatedAt: DateTime.now(),
        createdAt: entity.createdAt ?? DateTime.now(),
      );
      await super.save(stockWithLocalId);
      return stockWithLocalId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error saving packaging stock: ${appException.message}',
        name: 'PackagingStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> recordMovement(PackagingStockMovement movement) async {
    try {
      // Validation du mouvement AVANT toute opération de sauvegarde
      if (movement.packagingId.trim().isEmpty) {
        throw ValidationException('L\'ID d\'emballage est requis pour le mouvement.');
      }
      if (movement.packagingType.trim().isEmpty) {
        throw ValidationException('Le type d\'emballage est requis pour le mouvement.');
      }
      if (movement.quantite <= 0) {
        throw ValidationException('La quantité du mouvement doit être positive.');
      }

      final localId = movement.id.startsWith('local_')
          ? movement.id
          : LocalIdGenerator.generate();
      final remoteId = movement.id.startsWith('local_') ? null : movement.id;
      
      final movementWithAudit = movement.copyWith(
        id: localId,
        createdAt: movement.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        enterpriseId: enterpriseId,
      );
      
      final map = movementWithAudit.toMap()..['localId'] = localId;

      await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
        collectionName: movementsCollection,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Log pour déboguer
      AppLogger.info(
        'Saved packaging movement: ${movement.packagingType} - ${movement.type.name} - ${movement.quantite} units (localId: $localId, moduleType: $moduleType)',
        name: 'PackagingStockOfflineRepository.recordMovement',
      );

      // Queue sync operation
      if (remoteId == null) {
        await syncManager.queueCreate(
          collectionName: movementsCollection,
          localId: localId,
          data: map,
          enterpriseId: enterpriseId,
        );
        AppLogger.info(
          'Queued packaging movement for sync (create): $localId',
          name: 'PackagingStockOfflineRepository.recordMovement',
        );
      } else {
        await syncManager.queueUpdate(
          collectionName: movementsCollection,
          localId: localId,
          remoteId: remoteId,
          data: map,
          enterpriseId: enterpriseId,
        );
        AppLogger.info(
          'Queued packaging movement for sync (update): $localId -> $remoteId',
          name: 'PackagingStockOfflineRepository.recordMovement',
        );
      }

      // Mettre à jour automatiquement le stock en fonction du type de mouvement
      // (comme pour les bobines)
      // 1. Chercher le stock par ID (ID catalogue ou fixed ID)
      var stock = await fetchById(movement.packagingId);
      
      // 2. Fallback: Chercher par type si non trouvé par ID
      // Cela permet de récupérer les stocks créés avec l'ancienne logique (ID basé sur le type)
      stock ??= await fetchByType(movement.packagingType);
      
      if (stock == null) {
        // Si le stock n'existe pas du tout, le créer
        int initialQuantity = 0;
        if (movement.type == PackagingMovementType.entree) {
          initialQuantity = movement.quantite;
        }
        
        // Utiliser l'ID fourni (probablement l'ID du catalogue)
        final stockId = movement.packagingId;
        
        // Déterminer le facteur de lot à partir du mouvement si possible
        int movementUnitsPerLot = 1;
        if (movement.isInLots && movement.quantiteSaisie != null && movement.quantiteSaisie! > 0) {
          movementUnitsPerLot = (movement.quantite / movement.quantiteSaisie!).round();
          if (movementUnitsPerLot < 1) movementUnitsPerLot = 1;
        }

        stock = PackagingStock(
          id: stockId,
          enterpriseId: enterpriseId,
          type: movement.packagingType,
          quantity: initialQuantity,
          unit: 'unité',
          unitsPerLot: movementUnitsPerLot,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        // 3. Mettre à jour la quantité existante (ADDITION)
        int newQuantity = stock.quantity;
        
        // Mettre à jour le facteur de lot si le mouvement en apporte un nouveau plus précis
        int updatedUnitsPerLot = stock.unitsPerLot;
        if (movement.isInLots && movement.quantiteSaisie != null && movement.quantiteSaisie! > 0) {
          final computedUnitsPerLot = (movement.quantite / movement.quantiteSaisie!).round();
          if (computedUnitsPerLot > 1) {
             updatedUnitsPerLot = computedUnitsPerLot;
          }
        }

        switch (movement.type) {
          case PackagingMovementType.entree:
            newQuantity += movement.quantite;
            break;
          case PackagingMovementType.sortie:
          case PackagingMovementType.ajustement:
            newQuantity -= movement.quantite;
            if (newQuantity < 0) newQuantity = 0; // Sécurité
            break;
        }

        stock = stock.copyWith(
          quantity: newQuantity,
          unitsPerLot: updatedUnitsPerLot,
          updatedAt: DateTime.now(),
        );
      }

      // Sauvegarder le stock (création ou mise à jour) avec la bonne quantité
      await save(stock);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error recording packaging movement: ${appException.message}',
        name: 'PackagingStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<PackagingStockMovement>> fetchMovements({
    String? packagingId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: movementsCollection,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      
      // Log pour déboguer
      AppLogger.info(
        'Fetched ${rows.length} packaging movement records from collection $movementsCollection',
        name: 'PackagingStockOfflineRepository.fetchMovements',
      );
      
      final movements = rows.map((r) {
        try {
          final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
          final movement = PackagingStockMovement.fromMap(map, enterpriseId);
          return movement.isDeleted ? null : movement;
        } catch (e, stackTrace) {
          AppLogger.warning(
            'Error parsing packaging movement record ${r.localId}: $e',
            name: 'PackagingStockOfflineRepository.fetchMovements',
            error: e,
            stackTrace: stackTrace,
          );
          return null;
        }
      }).whereType<PackagingStockMovement>().toList();

      // Apply filters (comme pour les bobines)
      var filteredMovements = movements;
      if (packagingId != null) {
        filteredMovements = filteredMovements
            .where((m) => m.packagingId == packagingId)
            .toList();
      }
      if (startDate != null) {
        filteredMovements = filteredMovements
            .where((m) => m.date.isAfter(startDate.subtract(const Duration(days: 1))))
            .toList();
      }
      if (endDate != null) {
        filteredMovements = filteredMovements
            .where((m) => m.date.isBefore(endDate.add(const Duration(days: 1))))
            .toList();
      }

      // Sort by date descending (comme pour les bobines)
      filteredMovements.sort((a, b) => b.date.compareTo(a.date));

      AppLogger.info(
        'Returning ${filteredMovements.length} filtered packaging movements (from ${movements.length} total)',
        name: 'PackagingStockOfflineRepository.fetchMovements',
      );

      return filteredMovements;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching packaging movements: ${appException.message}',
        name: 'PackagingStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<PackagingStock>> fetchLowStockAlerts() async {
    try {
      final stocks = await fetchAll();
      return stocks.where((s) => s.estStockFaible).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching low stock alerts: ${appException.message}',
        name: 'PackagingStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
