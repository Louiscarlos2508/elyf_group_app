import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
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
  PointOfSale fromMap(Map<String, dynamic> map) =>
      PointOfSale.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(PointOfSale entity) => entity.toMap();

  @override
  String getLocalId(PointOfSale entity) {
    if (entity.id.isNotEmpty) return entity.id;
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
    
    AppLogger.debug(
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
    // Soft-delete
    final deletedPos = entity.copyWith(
      deletedAt: DateTime.now(),
    );
    await saveToLocal(deletedPos);
    
    AppLogger.info(
      'Soft-deleted point of sale: ${entity.id}',
      name: 'PointOfSaleOfflineRepository',
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
      final pos = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return pos.isDeleted ? null : pos;
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    final pos = fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    return pos.isDeleted ? null : pos;
  }

  @override
  Future<List<PointOfSale>> getAllForEnterprise(String enterpriseId) async {
    AppLogger.debug(
      'Récupération des points de vente pour enterpriseId: $enterpriseId, moduleType: $moduleType',
      name: 'PointOfSaleOfflineRepository.getAllForEnterprise',
    );
    
    // Les points de vente sont stockés dans l'entreprise gaz (enterpriseId)
    // et sont synchronisés avec cet ID dans Drift
    // Note: Dans Firestore, les points de vente ont enterpriseId=parentEnterpriseId dans les données,
    // mais ils sont stockés physiquement sous enterprises/{gaz_enterprise_id}/pointsOfSale/
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    
    AppLogger.debug(
      'Nombre de lignes trouvées dans Drift: ${rows.length} pour enterpriseId=$enterpriseId, moduleType=$moduleType',
      name: 'PointOfSaleOfflineRepository.getAllForEnterprise',
    );
    
    // Debug: Vérifier aussi toutes les collections pour voir s'il y a des points de vente ailleurs
    try {
      final allRows = await driftService.records.listForCollection(
        collectionName: collectionName,
        moduleType: moduleType,
      );
      AppLogger.debug(
        'Total de points de vente dans Drift (toutes entreprises): ${allRows.length}',
        name: 'PointOfSaleOfflineRepository.getAllForEnterprise',
      );
      
      // Afficher les enterpriseId de tous les points de vente trouvés
      for (final row in allRows.take(10)) { // Limiter à 10 pour ne pas surcharger les logs
        try {
          final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
          final posParentEnterpriseId = map['parentEnterpriseId'] as String? ?? 
                                        map['enterpriseId'] as String? ?? 
                                        'unknown';
          final posEnterpriseId = map['enterpriseId'] as String?;
          AppLogger.debug(
            'Point de vente trouvé - id: ${row.localId}, enterpriseId dans Drift: ${row.enterpriseId}, parentEnterpriseId dans data: $posParentEnterpriseId, enterpriseId dans data: $posEnterpriseId',
            name: 'PointOfSaleOfflineRepository.getAllForEnterprise',
          );
        } catch (e) {
          // Ignorer les erreurs de parsing pour le debug
        }
      }
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Erreur lors de la vérification de toutes les collections: ${appException.message}',
        name: 'PointOfSaleOfflineRepository.getAllForEnterprise',
        error: e,
        stackTrace: stackTrace,
      );
    }
    
    final entities = rows
        .map((r) {
          try {
            final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
            final entity = fromMap(map);
            if (entity.isDeleted) return null;
            AppLogger.debug(
              'PointOfSale trouvé: id=${entity.id}, name=${entity.name}, parentEnterpriseId=${entity.parentEnterpriseId}',
              name: 'PointOfSaleOfflineRepository.getAllForEnterprise',
            );
            return entity;
          } catch (e, stackTrace) {
            final appException = ErrorHandler.instance.handleError(e, stackTrace);
            AppLogger.warning(
              'Erreur lors du parsing: ${appException.message}',
              name: 'PointOfSaleOfflineRepository.getAllForEnterprise',
              error: e,
              stackTrace: stackTrace,
            );
            return null;
          }
        })
        .whereType<PointOfSale>()
        .toList();

    // Dédupliquer par remoteId pour éviter les doublons
    final deduplicated = deduplicateByRemoteId(entities);
    
    AppLogger.debug(
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
      return all.where((pos) => pos.moduleId == moduleId).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting points of sale: ${appException.message}',
        name: 'PointOfSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Stream<List<PointOfSale>> watchPointsOfSale({
    required String enterpriseId,
    required String moduleId,
  }) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final entities = rows
              .map((r) {
                try {
                  final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
                  final pos = fromMap(map);
                  return pos.isDeleted ? null : pos;
                } catch (e) {
                  return null;
                }
              })
              .whereType<PointOfSale>()
              .toList();

          final deduplicated = deduplicateByRemoteId(entities);
          return deduplicated.where((pos) => pos.moduleId == moduleId).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
        });
  }

  @override
  Future<PointOfSale?> getPointOfSaleById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting point of sale: $id - ${appException.message}',
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
      AppLogger.error(
        'Error adding point of sale: ${appException.message}',
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
      AppLogger.error(
        'Error updating point of sale: ${pointOfSale.id} - ${appException.message}',
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
      AppLogger.error(
        'Error deleting point of sale: $id - ${appException.message}',
        name: 'PointOfSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
