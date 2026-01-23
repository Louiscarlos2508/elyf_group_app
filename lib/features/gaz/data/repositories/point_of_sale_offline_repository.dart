import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/point_of_sale.dart';
import '../../domain/repositories/point_of_sale_repository.dart';

/// Offline-first repository for PointOfSale entities.
class PointOfSaleOfflineRepository extends OfflineRepository<PointOfSale>
    implements PointOfSaleRepository {
  PointOfSaleOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'pointOfSale';

  @override
  PointOfSale fromMap(Map<String, dynamic> map) {
    // Support pour l'ancien format (enterpriseId) et le nouveau (parentEnterpriseId)
    final parentEnterpriseId = map['parentEnterpriseId'] as String? ??
        map['enterpriseId'] as String? ??
        '';
    
    return PointOfSale(
      id: map['id'] as String? ?? map['localId'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      contact: map['contact'] as String,
      parentEnterpriseId: parentEnterpriseId,
      moduleId: map['moduleId'] as String,
      isActive: map['isActive'] as bool? ?? true,
      cylinderIds:
          (map['cylinderIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(PointOfSale entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'address': entity.address,
      'contact': entity.contact,
      'parentEnterpriseId': entity.parentEnterpriseId, // ⚠️ IMPORTANT : stocker explicitement
      'enterpriseId': entity.enterpriseId, // Pour compatibilité avec l'ancien format
      'moduleId': entity.moduleId,
      'isActive': entity.isActive,
      'cylinderIds': entity.cylinderIds,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(PointOfSale entity) {
    if (entity.id.startsWith('local_')) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(PointOfSale entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(PointOfSale entity) {
    // Utiliser parentEnterpriseId pour le stockage dans Drift
    // Cela permet de récupérer les points de vente depuis l'entreprise mère
    // via getAllForEnterprise('gaz_1')
    return entity.parentEnterpriseId;
  }

  @override
  Future<void> saveToLocal(PointOfSale entity) async {
    // Utiliser la méthode utilitaire pour trouver le localId existant
    final existingLocalId = await findExistingLocalId(entity, moduleType: moduleType);
    final localId = existingLocalId ?? getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId..['id'] = localId;
    
    // ⚠️ IMPORTANT : Utiliser getEnterpriseId(entity) qui retourne parentEnterpriseId
    // Cela permet de stocker le point de vente avec l'ID de l'entreprise mère
    // pour qu'il soit récupérable via getAllForEnterprise('gaz_1')
    final storageEnterpriseId = getEnterpriseId(entity) ?? enterpriseId;
    
    developer.log(
      'Sauvegarde PointOfSale: id=${entity.id}, parentEnterpriseId=${entity.parentEnterpriseId}, storageEnterpriseId=$storageEnterpriseId',
      name: 'PointOfSaleOfflineRepository.saveToLocal',
    );
    
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: storageEnterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(PointOfSale entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<PointOfSale?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<PointOfSale>> getAllForEnterprise(String enterpriseId) async {
    developer.log(
      'Récupération des points de vente pour enterpriseId: $enterpriseId',
      name: 'PointOfSaleOfflineRepository.getAllForEnterprise',
    );
    
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    
    developer.log(
      'Nombre de lignes trouvées: ${rows.length}',
      name: 'PointOfSaleOfflineRepository.getAllForEnterprise',
    );
    
    final entities = rows
        .map((r) {
          try {
            final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
            final entity = fromMap(map);
            developer.log(
              'PointOfSale trouvé: id=${entity.id}, parentEnterpriseId=${entity.parentEnterpriseId}',
              name: 'PointOfSaleOfflineRepository.getAllForEnterprise',
            );
            return entity;
          } catch (e) {
            developer.log(
              'Erreur lors du parsing: $e',
              name: 'PointOfSaleOfflineRepository.getAllForEnterprise',
              error: e,
            );
            return null;
          }
        })
        .whereType<PointOfSale>()
        .toList();

    // Dédupliquer par remoteId pour éviter les doublons
    final deduplicated = deduplicateByRemoteId(entities);
    
    developer.log(
      'Points de vente après déduplication: ${deduplicated.length}',
      name: 'PointOfSaleOfflineRepository.getAllForEnterprise',
    );
    
    return deduplicated;
  }

  // PointOfSaleRepository implementation

  @override
  Future<List<PointOfSale>> getPointsOfSale({
    required String enterpriseId,
    required String moduleId,
  }) async {
    try {
      final all = await getAllForEnterprise(enterpriseId);
      return all.where((pos) => pos.moduleId == moduleId).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting points of sale',
        name: 'PointOfSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<PointOfSale?> getPointOfSaleById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting point of sale: $id',
        name: 'PointOfSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> addPointOfSale(PointOfSale pointOfSale) async {
    try {
      final localId = getLocalId(pointOfSale);
      final posWithLocalId = pointOfSale.copyWith(
        id: localId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(posWithLocalId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error adding point of sale',
        name: 'PointOfSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updatePointOfSale(PointOfSale pointOfSale) async {
    try {
      final updated = pointOfSale.copyWith(updatedAt: DateTime.now());
      await save(updated);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating point of sale: ${pointOfSale.id}',
        name: 'PointOfSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deletePointOfSale(String id) async {
    try {
      final pos = await getPointOfSaleById(id);
      if (pos != null) {
        await delete(pos);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting point of sale: $id',
        name: 'PointOfSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
