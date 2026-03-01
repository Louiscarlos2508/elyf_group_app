import 'dart:developer' as developer;
import 'dart:convert';
import 'package:rxdart/rxdart.dart';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/drift/app_database.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/enterprise.dart';
import '../../domain/repositories/enterprise_repository.dart';
import 'optimized_queries.dart';

/// Offline-first repository for Enterprise entities.
///
/// Note: Enterprises are global (not enterprise-specific), so enterpriseId is not used.
class EnterpriseOfflineRepository extends OfflineRepository<Enterprise>
    implements EnterpriseRepository {
  EnterpriseOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
  });

  @override
  String get collectionName => 'enterprises';

  @override
  String getSyncCollectionName(Enterprise entity) {
    if (entity.type.isGas && !entity.type.isMain) {
      return 'pointOfSale';
    }
    if (entity.type.isMobileMoney && !entity.type.isMain) {
      return 'agences';
    }
    return collectionName;
  }

  @override
  Enterprise fromMap(Map<String, dynamic> map) {
    // Prioriser localId si disponible (pour cohérence avec saveToLocal)
    // Sinon utiliser id, puis localId comme fallback
    final id = map['localId'] as String? ?? 
                map['id'] as String? ?? 
                (throw ValidationException(
                  'Enterprise must have an id or localId',
                  'ENTERPRISE_ID_MISSING',
                ));
    
    return Enterprise(
      id: id,
      name: map['name'] as String,
      type: EnterpriseType.fromId(map['type'] as String),
      parentEnterpriseId: map['parentEnterpriseId'] as String?,
      hierarchyLevel: map['hierarchyLevel'] as int? ?? 0,
      hierarchyPath: map['hierarchyPath'] as String? ?? '',
      ancestorIds: (map['ancestorIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? const [],
      moduleId: map['moduleId'] as String?,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      description: map['description'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(Enterprise entity) {
    return {
      'id': entity.id,
      'name': entity.name,
      'type': entity.type.id,
      'parentEnterpriseId': entity.parentEnterpriseId,
      'hierarchyLevel': entity.hierarchyLevel,
      'hierarchyPath': entity.hierarchyPath,
      'ancestorIds': entity.ancestorIds,
      'moduleId': entity.moduleId,
      'metadata': entity.metadata,
      'latitude': entity.latitude,
      'longitude': entity.longitude,
      'description': entity.description,
      'address': entity.address,
      'phone': entity.phone,
      'email': entity.email,
      'isActive': entity.isActive,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(Enterprise entity) => entity.id;

  @override
  String? getRemoteId(Enterprise entity) => entity.id; // L'ID est le même pour local et remote

  @override
  String? getEnterpriseId(Enterprise entity) {
    // Pour les sous-tenants (POS/Agences), on retourne l'ID du parent
    // car ils sont stockés dans une sous-collection de l'entreprise parente
    if (!entity.type.isMain) {
      return entity.parentEnterpriseId;
    }
    return null;
  }

  @override
  Future<void> saveToLocal(Enterprise entity, {String? userId}) async {
    final targetCollection = getSyncCollectionName(entity);
    final syncEnterpriseId = getEnterpriseId(entity) ?? 'global';
    
    // Determine the module type for storage
    // If it's a sub-tenant, use its module, otherwise use 'administration'
    final moduleType = (!entity.type.isMain) 
        ? entity.type.module.id 
        : (entity.moduleId ?? 'administration');

    // Utiliser findExistingLocalId pour éviter les duplications
    final existingLocalId = await findExistingLocalId(entity, moduleType: moduleType);
    final localId = existingLocalId ?? getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId..['id'] = localId;
    
    developer.log(
      'Sauvegarde Enterprise: id=${entity.id}, localId=$localId, remoteId=$remoteId, collection=$targetCollection, syncId=$syncEnterpriseId, moduleType=$moduleType',
      name: 'EnterpriseOfflineRepository.saveToLocal',
    );
    
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
      collectionName: targetCollection,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: syncEnterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Enterprise entity, {String? userId}) async {
    final targetCollection = getSyncCollectionName(entity);
    final syncEnterpriseId = getEnterpriseId(entity) ?? 'global';
    final moduleType = (!entity.type.isMain) 
        ? entity.type.module.id 
        : (entity.moduleId ?? 'administration');
    
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: targetCollection,
      localId: localId,
      enterpriseId: syncEnterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<Enterprise?> getByLocalId(String localId) async {
    // Chercher d'abord dans les sous-tenants (plus spécifique)
    for (final subCollection in ['pointOfSale', 'agences']) {
      final posRecord = await driftService.records.findInCollectionByLocalId(
        collectionName: subCollection,
        localId: localId,
      );
      
      if (posRecord != null) {
        final map = jsonDecode(posRecord.dataJson) as Map<String, dynamic>;
        map['localId'] = posRecord.localId;
        return fromMap(map);
      }
    }

    // Sinon chercher dans les entreprises racines
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: 'global',
      moduleType: 'administration',
    );
    if (record == null) return null;
    final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
    map['localId'] = record.localId;
    return fromMap(map);
  }

  @override
  Future<List<Enterprise>> getAllForEnterprise(String enterpriseId) {
    // Retourne l'entreprise elle-même et ses POS rattachés
    return getAllEnterprises().then((list) => list.where((e) => 
      e.id == enterpriseId || e.parentEnterpriseId == enterpriseId
    ).toList());
  }


  @override
  Future<List<Enterprise>> getAllEnterprises() async {
    try {
      // 1. Fetch from 'enterprises' (administration)
      final enterpriseRecords = await driftService.records.listForEnterprise(
        collectionName: 'enterprises',
        enterpriseId: 'global',
        moduleType: 'administration',
      );
      
      // 2. Fetch from sub-tenant collections (all modules)
      final posRecords = <OfflineRecord>[];
      for (final subCollection in ['pointOfSale', 'agences']) {
        final records = await driftService.records.listForCollection(
          collectionName: subCollection,
        );
        posRecords.addAll(records);
      }
      
      final allRecords = [...enterpriseRecords, ...posRecords];
      
      return allRecords.map((record) {
        try {
          final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
          map['localId'] = record.localId;
          return fromMap(map);
        } catch (e) {
          return null;
        }
      }).whereType<Enterprise>().toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<List<Enterprise>> watchAllEnterprises() {
    // 1. Écoute les entreprises racines
    final enterprisesStream = driftService.records.watchForEnterprise(
      collectionName: 'enterprises',
      enterpriseId: 'global',
      moduleType: 'administration',
    );
    
    // 2. Écoute les sous-tenants (pointOfSale pour Gaz, agences pour Mobile Money)
    final subTenantsStreams = ['pointOfSale', 'agences'].map(
      (subName) => driftService.records.watchForCollection(collectionName: subName)
    ).toList();
 
    return Rx.combineLatest2<List<OfflineRecord>, List<List<OfflineRecord>>, List<Enterprise>>(
      enterprisesStream,
      Rx.combineLatestList(subTenantsStreams),
      (enterpriseRecords, subTenantsRecordsList) {
        final allPosRecords = subTenantsRecordsList.expand((list) => list).toList();
        final allRecords = [...enterpriseRecords, ...allPosRecords];
        
        final enterprises = allRecords.map((record) {
          try {
            final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
            map['localId'] = record.localId;
            return fromMap(map);
          } catch (e) {
            AppLogger.warning('Error parsing enterprise record ${record.localId}: $e');
            return null;
          }
        }).whereType<Enterprise>().toList();

        // Déduplication finale par ID
        final unique = <String, Enterprise>{};
        for (final ent in enterprises) {
          unique[ent.id] = ent;
        }
        return unique.values.toList();
      },
    );
  }

  @override
  Future<({List<Enterprise> enterprises, int totalCount})>
  getEnterprisesPaginated({int page = 0, int limit = 50}) async {
    try {
      // Validate and clamp pagination parameters
      final validated = OptimizedQueries.validatePagination(
        page: page,
        limit: limit,
      );
      final offset = OptimizedQueries.calculateOffset(
        validated.page,
        validated.limit,
      );

      // Get paginated records using LIMIT/OFFSET at Drift level
      final records = await driftService.records.listForEnterprisePaginated(
        collectionName: collectionName,
        enterpriseId: 'global',
        moduleType: 'administration',
        limit: validated.limit,
        offset: offset,
      );

      // Get total count for pagination info
      final totalCount = await driftService.records.countForEnterprise(
        collectionName: collectionName,
        enterpriseId: 'global',
        moduleType: 'administration',
      );

      final enterprises = records.map<Enterprise>((record) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        return fromMap(map);
      }).toList();

      return (enterprises: enterprises, totalCount: totalCount);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        'Error fetching paginated enterprises from offline storage: ${appException.message}',
        name: 'admin.enterprise.repository',
        error: e,
        stackTrace: stackTrace,
      );
      return (enterprises: <Enterprise>[], totalCount: 0);
    }
  }

  @override
  Future<List<Enterprise>> getEnterprisesByType(String type) async {
    final allEnterprises = await getAllEnterprises();
    return allEnterprises.where((e) => e.type.id == type).toList();
  }

  @override
  Future<Enterprise?> getEnterpriseById(String id) async {
    try {
      // 1. Try 'enterprises' collection
      final record = await driftService.records.findByRemoteId(
        collectionName: 'enterprises',
        remoteId: id,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
      
      if (record != null) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        return fromMap(map);
      }
      
      // 2. Try sub-tenant collections
      for (final subCollection in ['pointOfSale', 'agences']) {
        final posRecord = await driftService.records.findInCollectionByRemoteId(
          collectionName: subCollection,
          remoteId: id,
        );
        
        if (posRecord != null) {
          final map = jsonDecode(posRecord.dataJson) as Map<String, dynamic>;
          map['localId'] = posRecord.localId;
          return fromMap(map);
        }
      }

      // 3. Try by local ID (fallback)
      return await getByLocalId(id);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.warning(
        'Error fetching enterprise by ID: $id - ${appException.message}',
        name: 'admin.enterprise.repository',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<String> createEnterprise(Enterprise enterprise) async {
    await save(enterprise);
    return enterprise.id;
  }

  @override
  Future<void> updateEnterprise(Enterprise enterprise) async {
    await save(enterprise);
  }

  @override
  Future<void> deleteEnterprise(String id) async {
    final enterprise = await getEnterpriseById(id);
    if (enterprise != null) {
      await delete(enterprise);
    }
  }

  @override
  Future<void> toggleEnterpriseStatus(
    String enterpriseId,
    bool isActive,
  ) async {
    final enterprise = await getEnterpriseById(enterpriseId);
    if (enterprise != null) {
      final updatedEnterprise = enterprise.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
      await save(updatedEnterprise);
    }
  }
}
