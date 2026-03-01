import 'dart:convert';
import '../../../../core/offline/offline_repository.dart';
import '../../../../shared/domain/entities/payment_method.dart';
import '../../../../shared/domain/entities/treasury_operation.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/repositories/treasury_repository.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/collection_names.dart';

class TreasuryOfflineRepository extends OfflineRepository<TreasuryOperation> implements TreasuryRepository {
  TreasuryOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.auditTrailRepository,
    required this.enterpriseId,
    required this.moduleType,
    this.userId = 'system',
  });

  final String enterpriseId;
  final String moduleType;
  final AuditTrailRepository auditTrailRepository;
  final String userId;

  @override
  String get collectionName => CollectionNames.eauMineraleTreasuryOperations;

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
    return entity.id;
  }

  @override
  String? getRemoteId(TreasuryOperation entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(TreasuryOperation entity) => enterpriseId;

  @override
  Future<void> saveToLocal(TreasuryOperation entity, {String? userId}) async {
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
  Future<void> deleteFromLocal(TreasuryOperation entity, {String? userId}) async {
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
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (record == null) return null;
    return fromMap(jsonDecode(record.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<TreasuryOperation>> getAllForEnterprise(String enterpriseId) async {
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
  Future<List<TreasuryOperation>> fetchOperations({int limit = 50}) async {
    return getAllForEnterprise(enterpriseId);
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
      userId: syncManager.getUserId() ?? '',
    );
    
    await save(entity);
    
    await _logAudit(
      action: 'create_treasury_operation',
      entityId: id,
      metadata: {
        'type': operation.type.name, 
        'amount': operation.amount,
      },
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
        .map((rows) => rows
            .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
            .toList());
  }

  @override
  Future<Map<String, int>> getBalances() async {
    final ops = await fetchOperations();
    return _calculateBalances(ops);
  }

  @override
  Stream<Map<String, int>> watchBalances() {
    return watchOperations().map((ops) => _calculateBalances(ops));
  }

  Map<String, int> _calculateBalances(List<TreasuryOperation> ops) {
    int cash = 0;
    int mm = 0;

    for (final op in ops) {
      switch (op.type) {
        case TreasuryOperationType.supply:
        case TreasuryOperationType.adjustment: // Treating adjustment as delta for simplicity if no better rule
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
          userId: syncManager.getUserId() ?? '',
          module: 'eau_minerale',
          action: action,
          entityId: entityId,
          entityType: 'treasury_operation',
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to log treasury audit: $action', error: e);
    }
  }
}
