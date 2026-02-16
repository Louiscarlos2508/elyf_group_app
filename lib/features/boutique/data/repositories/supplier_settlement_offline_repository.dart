import 'dart:convert';
import '../../../../core/offline/offline_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/entities/supplier_settlement.dart';
import '../../domain/repositories/supplier_settlement_repository.dart';
import '../../domain/services/security/ledger_hash_service.dart';
import '../../../../core/logging/app_logger.dart';

class SupplierSettlementOfflineRepository extends OfflineRepository<SupplierSettlement> implements SupplierSettlementRepository {
  SupplierSettlementOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.auditTrailRepository,
    required this.enterpriseId,
    required this.moduleType,
    this.userId = 'system',
    this.shopSecret = 'DEFAULT_SECRET',
  });

  final String enterpriseId;
  final String moduleType;
  final AuditTrailRepository auditTrailRepository;
  final String userId;
  final String shopSecret;

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
    // 1. Chain hash if not already hashed
    SupplierSettlement toSave = entity;
    if (toSave.hash == null) {
      final lastSettlement = await _getLastSettlement();
      final hash = LedgerHashService.generateHash(
        previousHash: lastSettlement?.hash,
        entity: toSave,
        shopSecret: shopSecret,
      );
      toSave = toSave.copyWith(hash: hash, previousHash: lastSettlement?.hash);
    }

    final localId = getLocalId(toSave);
    final remoteId = getRemoteId(toSave);
    final map = toMap(toSave)..['localId'] = localId;
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

  Future<SupplierSettlement?> _getLastSettlement() async {
    final all = await getAllForEnterprise(enterpriseId);
    if (all.isEmpty) return null;
    all.sort((a, b) => b.date.compareTo(a.date));
    return all.first;
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
    
    // Generate Hash
    final lastSettlement = await _getLastSettlement();
    final hash = LedgerHashService.generateHash(
      previousHash: lastSettlement?.hash,
      entity: settlement,
      shopSecret: shopSecret,
    );

    final entity = settlement.copyWith(
      id: id, 
      enterpriseId: enterpriseId,
      hash: hash,
      previousHash: lastSettlement?.hash,
    );
    await save(entity);
    
    await _logAudit(
      action: 'create_supplier_settlement',
      entityId: id,
      metadata: {
        'supplierId': settlement.supplierId, 
        'amount': settlement.amount,
        'hash': hash,
      },
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

  @override
  Future<bool> verifyChain() async {
    try {
      final settlements = await getAllForEnterprise(enterpriseId);
      if (settlements.isEmpty) return true;

      settlements.sort((a, b) => b.date.compareTo(a.date));

      for (int i = 0; i < settlements.length; i++) {
        final current = settlements[i];
        final previous = i + 1 < settlements.length ? settlements[i + 1] : null;

        final isValid = LedgerHashService.verify(
          current,
          previous?.hash,
          shopSecret,
        );

        if (!isValid) {
          AppLogger.error(
            'Chain integrity violation at settlement ${current.id}.',
            name: 'SupplierSettlementOfflineRepository',
          );
          return false;
        }
      }
      return true;
    } catch (e) {
      AppLogger.error('Settlement chain verification failed', error: e);
      return false;
    }
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
      AppLogger.error('Failed to log settlement audit: $action', error: e);
    }
  }
}
