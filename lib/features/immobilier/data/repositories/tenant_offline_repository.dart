import 'dart:developer' as developer;
import 'dart:convert';

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/tenant.dart';
import '../../domain/repositories/tenant_repository.dart';

/// Offline-first repository for Tenant entities.
class TenantOfflineRepository extends OfflineRepository<Tenant>
    implements TenantRepository {
  TenantOfflineRepository({
    required super.driftService,
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
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Tenant entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'immobilier',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
  }

  @override
  Future<Tenant?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
    if (byRemote != null) {
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<Tenant>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'immobilier',
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
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

