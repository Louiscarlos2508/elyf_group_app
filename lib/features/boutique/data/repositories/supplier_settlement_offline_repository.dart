import 'dart:convert';
import '../../../../core/offline/offline_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/entities/supplier_settlement.dart';
import '../../domain/repositories/supplier_settlement_repository.dart';

class SupplierSettlementOfflineRepository extends OfflineRepository<SupplierSettlement> implements SupplierSettlementRepository {
  SupplierSettlementOfflineRepository({
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
  String get collectionName => 'supplier_settlements';

  @override
  SupplierSettlement fromMap(Map<String, dynamic> map) {
    return SupplierSettlement.fromMap(map, enterpriseId);
  }

  @override
  Map<String, dynamic> toMap(SupplierSettlement entity) {
    return entity.toMap();
  }

  @override
  String getLocalId(SupplierSettlement entity) {
    return entity.id;
  }

  @override
  String? getRemoteId(SupplierSettlement entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(SupplierSettlement entity) => enterpriseId;

  @override
  Future<void> saveToLocal(SupplierSettlement entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
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
  Future<void> deleteFromLocal(SupplierSettlement entity) async {
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<SupplierSettlement?> getByLocalId(String localId) async {
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
  Future<List<SupplierSettlement>> getAllForEnterprise(String enterpriseId) async {
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
  Future<List<SupplierSettlement>> fetchSettlements({String? supplierId, int limit = 100}) async {
    final all = await getAllForEnterprise(enterpriseId);
    final active = all.where((s) => !s.isDeleted).toList();
    if (supplierId != null) {
      return active.where((s) => s.supplierId == supplierId).toList();
    }
    return active;
  }

  @override
  Future<SupplierSettlement?> getSettlement(String id) async {
    return getByLocalId(id);
  }

  @override
  Future<void> deleteSettlement(String id, {String? deletedBy}) async {
    final settlement = await getSettlement(id);
    if (settlement == null) return;

    final updated = settlement.copyWith(
      deletedAt: DateTime.now(),
      deletedBy: deletedBy,
      updatedAt: DateTime.now(),
    );
    await save(updated);

    await _logAudit(
      action: 'delete_supplier_settlement',
      entityId: id,
      metadata: {'supplierId': settlement.supplierId, 'amount': settlement.amount},
    );
  }

  @override
  Future<int> getCountForDate(DateTime date) async {
    final all = await getAllForEnterprise(enterpriseId);
    final count = all.where((s) => 
      !s.isDeleted &&
      s.date.year == date.year && 
      s.date.month == date.month && 
      s.date.day == date.day
    ).length;
    return count;
  }

  @override
  Future<String> createSettlement(SupplierSettlement settlement) async {
    final id = settlement.id.isEmpty ? LocalIdGenerator.generate() : settlement.id;
    final entity = settlement.copyWith(id: id, enterpriseId: enterpriseId);
    await save(entity);
    
    await _logAudit(
      action: 'create_supplier_settlement',
      entityId: id,
      metadata: {'supplierId': settlement.supplierId, 'amount': settlement.amount},
    );
    
    return id;
  }

  Stream<List<SupplierSettlement>> watchAll() {
    return driftService.records.watchForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    ).map((rows) => rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList());
  }

  @override
  Stream<List<SupplierSettlement>> watchSettlements({String? supplierId, int limit = 100}) {
    return watchAll()
        .map((settlements) {
      final active = settlements.where((s) => !s.isDeleted).toList();
      if (supplierId != null) {
        return active.where((s) => s.supplierId == supplierId).toList();
      }
      return active;
    });
  }

  @override
  Stream<List<SupplierSettlement>> watchDeletedSettlements({String? supplierId}) {
    return watchAll()
        .map((settlements) {
      final deleted = settlements.where((s) => s.isDeleted).toList();
      if (supplierId != null) {
        return deleted.where((s) => s.supplierId == supplierId).toList();
      }
      return deleted;
    });
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
          userId: userId,
          module: 'boutique',
          action: action,
          entityId: entityId,
          entityType: 'supplier_settlement',
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      // Log error
    }
  }
}
