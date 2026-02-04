import 'dart:developer' as developer;
import 'dart:convert';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
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
      type: map['type'] as String,
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
      'type': entity.type,
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
  String getLocalId(Enterprise entity) {
    // Si l'ID commence par 'local_', c'est déjà un localId
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    // Pour les entreprises avec un ID non-local (ex: pos_gaz_1_1234567890),
    // utiliser l'ID directement comme localId pour éviter les duplications
    // Le système upsert se chargera de mettre à jour l'enregistrement existant
    // si il existe déjà (par remoteId ou localId)
    return entity.id;
  }

  @override
  String? getRemoteId(Enterprise entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(Enterprise entity) => null; // Enterprises are global

  @override
  Future<void> saveToLocal(Enterprise entity) async {
    // Utiliser findExistingLocalId pour éviter les duplications
    final existingLocalId = await findExistingLocalId(entity, moduleType: 'administration');
    final localId = existingLocalId ?? getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId..['id'] = localId;
    
    developer.log(
      'Sauvegarde Enterprise: id=${entity.id}, localId=$localId, remoteId=$remoteId',
      name: 'EnterpriseOfflineRepository.saveToLocal',
    );
    
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: 'global', // Enterprises are global
      moduleType: 'administration',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Enterprise entity) async {
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: 'global',
      moduleType: 'administration',
    );
  }

  @override
  Future<Enterprise?> getByLocalId(String localId) async {
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: 'global',
      moduleType: 'administration',
    );
    if (record == null) return null;
    final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
    return fromMap(map);
  }

  @override
  Future<List<Enterprise>> getAllForEnterprise(String enterpriseId) {
    // Enterprises are global, not enterprise-specific
    return getAllEnterprises();
  }

  // EnterpriseRepository implementation
    }
  }

  @override
  Future<List<Enterprise>> getAllEnterprises() async {
    try {
      final records = await driftService.records.listForEnterprise(
        collectionName: collectionName,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
      
      return records.map((record) {
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
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: 'global',
          moduleType: 'administration',
        )
        .map((records) {
      return records.map((record) {
        try {
          final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
          map['localId'] = record.localId;
          return fromMap(map);
        } catch (e) {
          return null;
        }
      }).whereType<Enterprise>().toList();
    });
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
    return allEnterprises.where((e) => e.type == type).toList();
  }

  @override
  Future<Enterprise?> getEnterpriseById(String id) async {
    try {
      // Try to find by remote ID first
      final record = await driftService.records.findByRemoteId(
        collectionName: collectionName,
        remoteId: id,
        enterpriseId: 'global',
        moduleType: 'administration',
      );
      if (record != null) {
        final map = jsonDecode(record.dataJson) as Map<String, dynamic>;
        return fromMap(map);
      }
      // Try by local ID
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
