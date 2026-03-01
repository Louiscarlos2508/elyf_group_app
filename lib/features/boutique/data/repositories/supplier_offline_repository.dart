import 'dart:convert';
import '../../../../core/offline/offline_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';

class SupplierOfflineRepository extends OfflineRepository<Supplier> implements SupplierRepository {
  SupplierOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
    required this.auditTrailRepository,
    this.userId = 'system',
  });

  final String enterpriseId;
  final String moduleType;
  final AuditTrailRepository auditTrailRepository;
  final String userId;

  @override
  String get collectionName => 'suppliers';

  @override
  Supplier fromMap(Map<String, dynamic> map) {
    return Supplier.fromMap(map, enterpriseId);
  }

  @override
  Map<String, dynamic> toMap(Supplier entity) {
    return entity.toMap();
  }

  @override
  String getLocalId(Supplier entity) {
    return entity.id;
  }

  @override
  String? getRemoteId(Supplier entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(Supplier entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Supplier entity, {String? userId}) async {
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
  Future<void> deleteFromLocal(Supplier entity, {String? userId}) async {
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<Supplier?> getByLocalId(String localId) async {
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
  Future<List<Supplier>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Supplier>> fetchSuppliers({int limit = 100}) async {
    return getAllForEnterprise(enterpriseId);
  }

  @override
  Future<Supplier?> getSupplier(String id) async {
    return getByLocalId(id);
  }

  @override
  Future<String> createSupplier(Supplier supplier) async {
    final id = supplier.id.isEmpty ? LocalIdGenerator.generate() : supplier.id;
    final entity = supplier.copyWith(id: id, enterpriseId: enterpriseId);
    await save(entity);
    
    await _logAudit(
      action: 'create_supplier',
      entityId: id,
      metadata: {'name': supplier.name},
    );
    
    return id;
  }

  @override
  Future<void> updateSupplier(Supplier supplier) async {
    await save(supplier);
    await _logAudit(
      action: 'update_supplier',
      entityId: supplier.id,
      metadata: {'name': supplier.name},
    );
  }

  @override
  Future<void> deleteSupplier(String id) async {
    final supplier = await getSupplier(id);
    if (supplier != null) {
      await delete(supplier);
      await _logAudit(
        action: 'delete_supplier',
        entityId: id,
      );
    }
  }

  @override
  Stream<List<Supplier>> watchSuppliers({int limit = 100}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) => rows
            .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
            .toList());
  }

  @override
  Future<List<Supplier>> searchSuppliers(String query) async {
    final all = await fetchSuppliers();
    final normalizedQuery = query.toLowerCase();
    return all.where((s) => 
      s.name.toLowerCase().contains(normalizedQuery) || 
      (s.phone?.contains(normalizedQuery) ?? false)
    ).toList();
  }

  Future<void> _logAudit({
    required String action,
    required String entityId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await auditTrailRepository.log(
        AuditRecord(
          id: '',
          enterpriseId: enterpriseId,
          userId: syncManager.getUserId() ?? '',
          module: 'boutique',
          action: action,
          entityId: entityId,
          entityType: 'supplier',
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      // Log error internally but don't crash
    }
  }
}
