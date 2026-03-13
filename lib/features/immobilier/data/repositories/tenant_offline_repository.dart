import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/collection_names.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/tenant.dart';
import '../../domain/repositories/tenant_repository.dart';

/// Offline-first repository for Tenant entities (immobilier module).
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
  String get collectionName => CollectionNames.tenants;

  String get moduleType => 'immobilier';

  @override
  Tenant fromMap(Map<String, dynamic> map) => Tenant.fromMap(map);

  @override
  Map<String, dynamic> toMap(Tenant entity) => entity.toMap();

  @override
  String getLocalId(Tenant entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Tenant entity) {
    if (!LocalIdGenerator.isLocalId(entity.id)) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(Tenant entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Tenant entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final map = toMap(entity);
    map['localId'] = localId;

    await driftService.records.upsert(
      userId: syncManager.getUserId() ?? '',
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Tenant entity, {String? userId}) async {
    final localId = getLocalId(entity);
    // Soft-delete
    final deletedTenant = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deletedBy: 'system',
    );
    await saveToLocal(deletedTenant, userId: userId);
  }

  @override
  Future<Tenant?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      final tenant = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return tenant.isDeleted ? null : tenant;
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
  Future<List<Tenant>> getAllTenants() async {
    return getAllForEnterprise(enterpriseId);
  }

  @override
  Future<List<Tenant>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((t) => !t.isDeleted)
        .toList();
  }

  // TenantRepository interface implementation

  @override
  Stream<List<Tenant>> watchTenants({bool? isDeleted = false}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      return rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((t) {
        if (isDeleted == null) return true;
        return t.isDeleted == isDeleted;
      }).toList();
    });
  }

  @override
  Future<Tenant?> getTenantById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<List<Tenant>> searchTenants(String query) async {
    final all = await getAllTenants();
    final lowerQuery = query.toLowerCase();
    return all.where((t) => 
      t.fullName.toLowerCase().contains(lowerQuery) || 
      t.phone.contains(query)
    ).toList();
  }

  @override
  Future<Tenant> createTenant(Tenant tenant) async {
    try {
      final localId = tenant.id.isEmpty ? LocalIdGenerator.generate() : tenant.id;
      final newTenant = tenant.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: tenant.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(newTenant);
      return newTenant;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<Tenant> updateTenant(Tenant tenant) async {
    try {
      final updatedTenant = tenant.copyWith(updatedAt: DateTime.now());
      await save(updatedTenant);
      return updatedTenant;
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
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
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }

  @override
  Future<void> restoreTenant(String id) async {
    try {
      final tenant = await getTenantById(id);
      if (tenant != null) {
        await save(tenant.copyWith(
          deletedAt: null,
          deletedBy: null,
        ));
      }
    } catch (error, stackTrace) {
      throw ErrorHandler.instance.handleError(error, stackTrace);
    }
  }
}
