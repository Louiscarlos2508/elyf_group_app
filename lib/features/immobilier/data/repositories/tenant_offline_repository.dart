import 'package:drift/drift.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/drift/app_database.dart';
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
  Future<void> saveToLocal(Tenant entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final companion = TenantsTableCompanion(
      id: Value(localId),
      enterpriseId: Value(enterpriseId),
      fullName: Value(entity.fullName),
      phone: Value(entity.phone),
      address: Value(entity.address),
      idNumber: Value(entity.idNumber),
      emergencyContact: Value(entity.emergencyContact),
      idCardPath: Value(entity.idCardPath),
      notes: Value(entity.notes),
      createdAt: Value(entity.createdAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
      deletedAt: Value(entity.deletedAt),
      deletedBy: Value(entity.deletedBy),
    );

    await driftService.db.into(driftService.db.tenantsTable).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> deleteFromLocal(Tenant entity, {String? userId}) async {
    final localId = getLocalId(entity);
    await (driftService.db.delete(driftService.db.tenantsTable)
          ..where((t) => t.id.equals(localId)))
        .go();
  }

  @override
  Future<Tenant?> getByLocalId(String localId) async {
    final query = driftService.db.select(driftService.db.tenantsTable)
      ..where((t) => t.id.equals(localId));
    final row = await query.getSingleOrNull();

    if (row == null) return null;
    return _fromEntity(row);
  }

  Tenant _fromEntity(TenantEntity entity) {
    return Tenant(
      id: entity.id,
      enterpriseId: entity.enterpriseId,
      fullName: entity.fullName,
      phone: entity.phone,
      address: entity.address,
      idNumber: entity.idNumber,
      emergencyContact: entity.emergencyContact,
      idCardPath: entity.idCardPath,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      deletedBy: entity.deletedBy,
    );
  }

  @override
  Future<List<Tenant>> getAllTenants() async {
    return getAllForEnterprise(enterpriseId);
  }

  @override
  Future<List<Tenant>> getAllForEnterprise(String enterpriseId) async {
    final query = driftService.db.select(driftService.db.tenantsTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId));
    final rows = await query.get();
    return rows.map(_fromEntity).toList();
  }

  // TenantRepository interface implementation

  @override
  Stream<List<Tenant>> watchTenants({bool? isDeleted = false}) {
    var query = driftService.db.select(driftService.db.tenantsTable)
      ..where((t) => t.enterpriseId.equals(enterpriseId));

    if (isDeleted != null) {
      if (isDeleted) {
        query.where((t) => t.deletedAt.isNotNull());
      } else {
        query.where((t) => t.deletedAt.isNull());
      }
    }

    return query.watch().map((rows) => rows.map(_fromEntity).toList());
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
          updatedAt: DateTime.now(),
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
