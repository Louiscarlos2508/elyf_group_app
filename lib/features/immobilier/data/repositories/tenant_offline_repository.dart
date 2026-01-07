import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/isar_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../core/offline/collections/tenant_collection.dart';
import '../../domain/entities/tenant.dart';
import '../../domain/repositories/tenant_repository.dart';

/// Offline-first repository for Tenant entities.
class TenantOfflineRepository extends OfflineRepository<Tenant>
    implements TenantRepository {
  TenantOfflineRepository({
    required super.isarService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'tenants';

  @override
  Tenant fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'] as String? ?? map['localId'] as String,
      fullName: map['fullName'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
      address: map['address'] as String?,
      idNumber: map['idNumber'] as String?,
      emergencyContact: map['emergencyContact'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(Tenant entity) {
    return {
      'id': entity.id,
      'fullName': entity.fullName,
      'phone': entity.phone,
      'email': entity.email,
      'address': entity.address,
      'idNumber': entity.idNumber,
      'emergencyContact': entity.emergencyContact,
      'notes': entity.notes,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(Tenant entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Tenant entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(Tenant entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Tenant entity) async {
    final collection = TenantCollection.fromMap(
      toMap(entity),
      enterpriseId: enterpriseId,
      localId: getLocalId(entity),
    );
    collection.remoteId = getRemoteId(entity);
    collection.localUpdatedAt = DateTime.now();

    await isarService.isar.writeTxn(() async {
      await isarService.isar.tenantCollections.put(collection);
    });
  }

  @override
  Future<void> deleteFromLocal(Tenant entity) async {
    final remoteId = getRemoteId(entity);
    await isarService.isar.writeTxn(() async {
      if (remoteId != null) {
        await isarService.isar.tenantCollections
            .filter()
            .remoteIdEqualTo(remoteId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      } else {
        final localId = getLocalId(entity);
        await isarService.isar.tenantCollections
            .filter()
            .localIdEqualTo(localId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      }
    });
  }

  @override
  Future<Tenant?> getByLocalId(String localId) async {
    var collection = await isarService.isar.tenantCollections
        .filter()
        .remoteIdEqualTo(localId)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .findFirst();

    if (collection != null) {
      return fromMap(collection.toMap());
    }

    collection = await isarService.isar.tenantCollections
        .filter()
        .localIdEqualTo(localId)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .findFirst();

    if (collection != null) {
      return fromMap(collection.toMap());
    }

    return null;
  }

  @override
  Future<List<Tenant>> getAllForEnterprise(String enterpriseId) async {
    final collections = await isarService.isar.tenantCollections
        .filter()
        .enterpriseIdEqualTo(enterpriseId)
        .findAll();

    return collections.map((c) => fromMap(c.toMap())).toList();
  }

  // TenantRepository interface implementation

  @override
  Future<List<Tenant>> getAllTenants() async {
    try {
      developer.log(
        'Fetching tenants for enterprise: $enterpriseId',
        name: 'TenantOfflineRepository',
      );
      return await getAllForEnterprise(enterpriseId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching tenants',
        name: 'TenantOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Tenant?> getTenantById(String id) async {
    try {
      final collection = await isarService.isar.tenantCollections
          .filter()
          .remoteIdEqualTo(id)
          .and()
          .enterpriseIdEqualTo(enterpriseId)
          .findFirst();

      if (collection != null) {
        return fromMap(collection.toMap());
      }

      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting tenant: $id',
        name: 'TenantOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Tenant>> searchTenants(String query) async {
    try {
      final allTenants = await getAllForEnterprise(enterpriseId);
      final lowerQuery = query.toLowerCase();
      return allTenants.where((tenant) {
        return tenant.fullName.toLowerCase().contains(lowerQuery) ||
            tenant.phone.contains(query) ||
            (tenant.email.toLowerCase().contains(lowerQuery));
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error searching tenants',
        name: 'TenantOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Tenant> createTenant(Tenant tenant) async {
    try {
      final localId = getLocalId(tenant);
      final tenantWithLocalId = Tenant(
        id: localId,
        fullName: tenant.fullName,
        phone: tenant.phone,
        email: tenant.email,
        address: tenant.address,
        idNumber: tenant.idNumber,
        emergencyContact: tenant.emergencyContact,
        notes: tenant.notes,
        createdAt: tenant.createdAt,
        updatedAt: tenant.updatedAt,
      );
      await save(tenantWithLocalId);
      return tenantWithLocalId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating tenant',
        name: 'TenantOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Tenant> updateTenant(Tenant tenant) async {
    try {
      await save(tenant);
      return tenant;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating tenant: ${tenant.id}',
        name: 'TenantOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteTenant(String id) async {
    try {
      final tenant = await getTenantById(id);
      if (tenant != null) {
        await delete(tenant);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting tenant: $id',
        name: 'TenantOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}

