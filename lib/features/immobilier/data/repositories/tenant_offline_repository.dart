import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
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
  String get collectionName => 'tenants';

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
  Future<void> saveToLocal(Tenant entity) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
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
  Future<void> deleteFromLocal(Tenant entity) async {
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
  Future<Tenant?> getByLocalId(String localId) async {
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    ) ?? await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );

    if (record == null) return null;
    final map = safeDecodeJson(record.dataJson, record.localId);
    return map != null ? fromMap(map) : null;
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
    final tenants = rows
        .map((r) => safeDecodeJson(r.dataJson, r.localId))
        .where((m) => m != null)
        .map((m) => fromMap(m!))
        .toList();
    
    return deduplicateByRemoteId(tenants);
  }

  // TenantRepository interface implementation

  @override
  Stream<List<Tenant>> watchTenants() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final entities = rows
              .map((r) => safeDecodeJson(r.dataJson, r.localId))
              .where((m) => m != null)
              .map((m) => fromMap(m!))
              .where((e) => !e.isDeleted)
              .toList();
          return deduplicateByRemoteId(entities);
        });
  }

  @override
  Stream<List<Tenant>> watchDeletedTenants() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final entities = rows
              .map((r) => safeDecodeJson(r.dataJson, r.localId))
              .where((m) => m != null)
              .map((m) => fromMap(m!))
              .where((e) => e.isDeleted)
              .toList();
          return deduplicateByRemoteId(entities);
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
        await save(tenant.copyWith(
          deletedAt: DateTime.now(),
          deletedBy: 'system',
        ));
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
