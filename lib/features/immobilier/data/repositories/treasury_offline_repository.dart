import 'dart:convert';
import '../../../../core/offline/offline_repository.dart';
import '../../../../shared/domain/entities/payment_method.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import '../../domain/repositories/treasury_repository.dart';

class TreasuryOfflineRepository extends OfflineRepository<TreasuryOperation> implements TreasuryRepository {
  TreasuryOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.auditTrailRepository,
    this.userId = 'system',
  });

  final String enterpriseId;
  final AuditTrailRepository auditTrailRepository;
  final String userId;

  @override
  String get collectionName => 'immobilier_treasury';

  String get moduleType => 'immobilier';

  @override
  TreasuryOperation fromMap(Map<String, dynamic> map) {
    return TreasuryOperation.fromMap(map, enterpriseId);
  }

  @override
  Map<String, dynamic> toMap(TreasuryOperation entity) {
    return entity.toMap();
  }

  @override
  String getLocalId(TreasuryOperation entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(TreasuryOperation entity) {
    if (!LocalIdGenerator.isLocalId(entity.id)) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(TreasuryOperation entity) => enterpriseId;

  @override
  Future<void> saveToLocal(TreasuryOperation entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
    
    // Ensure ID is consistent in map
    map['id'] = localId;

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
  Future<void> deleteFromLocal(TreasuryOperation entity) async {
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<TreasuryOperation?> getByLocalId(String localId) async {
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
  Future<List<TreasuryOperation>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final list = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
    // Sort by date descending
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<TreasuryOperation>> fetchOperations({int limit = 50}) async {
    // Basic implementation: fetch all and take limit.
    // For large datasets, we should implement pagination in DriftService.
    final all = await getAllForEnterprise(enterpriseId);
    if (all.length > limit) {
      return all.take(limit).toList();
    }
    return all;
  }

  @override
  Future<TreasuryOperation?> getOperation(String id) async {
    return getByLocalId(id);
  }

  @override
  Future<String> createOperation(TreasuryOperation operation) async {
    final id = operation.id.isEmpty ? LocalIdGenerator.generate() : operation.id;
    final entity = operation.copyWith(
      id: id, 
      enterpriseId: enterpriseId, 
      userId: operation.userId.isNotEmpty ? operation.userId : (userId.isEmpty ? 'system' : userId),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await save(entity);
    
    await _logAudit(
      action: 'create_treasury_operation',
      entityId: id,
      metadata: {'type': operation.type.name, 'amount': operation.amount},
    );
    
    return id;
  }

  @override
  Stream<List<TreasuryOperation>> watchOperations({int limit = 50}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final list = rows
              .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          if (list.length > limit) return list.take(limit).toList();
          return list;
        });
  }

  @override
  Future<Map<String, int>> getBalances() async {
    // Replay logic for balance calculation
    // This is expensive if history is long, but robust.
    // Optimization: Store snapshots of balance.
    final ops = await getAllForEnterprise(enterpriseId); // Need all ops for balance
    // Re-sort ascending for replay
    ops.sort((a, b) => a.date.compareTo(b.date));

    int cash = 0;
    int mm = 0;

    for (final op in ops) {
      switch (op.type) {
        case TreasuryOperationType.supply:
          if (op.toAccount == PaymentMethod.cash) cash += op.amount;
          if (op.toAccount == PaymentMethod.mobileMoney) mm += op.amount;
          break;
        case TreasuryOperationType.removal:
          if (op.fromAccount == PaymentMethod.cash) cash -= op.amount;
          if (op.fromAccount == PaymentMethod.mobileMoney) mm -= op.amount;
          break;
        case TreasuryOperationType.transfer:
          // Remove from source
          if (op.fromAccount == PaymentMethod.cash) cash -= op.amount;
          if (op.fromAccount == PaymentMethod.mobileMoney) mm -= op.amount;
          // Add to destination
          if (op.toAccount == PaymentMethod.cash) cash += op.amount;
          if (op.toAccount == PaymentMethod.mobileMoney) mm += op.amount;
          break;
        case TreasuryOperationType.adjustment:
          // Adjustments are treated as deltas
          if (op.toAccount == PaymentMethod.cash) cash += op.amount;
          if (op.toAccount == PaymentMethod.mobileMoney) mm += op.amount;
          break;
      }
    }
    
    return {'cash': cash, 'mobileMoney': mm};
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
          module: 'immobilier',
          action: action,
          entityId: entityId,
          entityType: 'treasury_operation',
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      // Silect fail
    }
  }
}
