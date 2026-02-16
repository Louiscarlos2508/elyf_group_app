import 'dart:convert';
import '../../../../core/offline/offline_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import '../../domain/repositories/treasury_repository.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import '../../domain/services/security/ledger_hash_service.dart';
import '../../../../core/logging/app_logger.dart';

class TreasuryOfflineRepository extends OfflineRepository<TreasuryOperation> implements TreasuryRepository {
  TreasuryOfflineRepository({
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
  String get collectionName => 'treasury_operations';

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
  Future<void> saveToLocal(TreasuryOperation entity) async {
    // 1. Chain hash if not already hashed (e.g. from createOperation)
    TreasuryOperation toSave = entity;
    if (toSave.hash == null) {
      final lastOp = await _getLastOperation();
      final hash = LedgerHashService.generateHash(
        previousHash: lastOp?.hash,
        entity: toSave,
        shopSecret: shopSecret,
      );
      toSave = toSave.copyWith(hash: hash, previousHash: lastOp?.hash);
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

  Future<TreasuryOperation?> _getLastOperation() async {
    final all = await getAllForEnterprise(enterpriseId);
    if (all.isEmpty) return null;
    all.sort((a, b) => b.date.compareTo(a.date));
    return all.first;
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
    
    // Generate Hash
    final lastOp = await _getLastOperation();
    final hash = LedgerHashService.generateHash(
      previousHash: lastOp?.hash,
      entity: operation,
      shopSecret: shopSecret,
    );
    
    final entity = operation.copyWith(
      id: id, 
      enterpriseId: enterpriseId, 
      userId: userId,
      hash: hash,
      previousHash: lastOp?.hash,
    );
    
    await save(entity);
    
    await _logAudit(
      action: 'create_treasury_operation',
      entityId: id,
      metadata: {
        'type': operation.type.name, 
        'amount': operation.amount,
        'hash': hash,
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
        case TreasuryOperationType.adjustment: // Treating adjustment as delta
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
          userId: userId,
          module: 'boutique',
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

  @override
  Future<bool> verifyChain() async {
    try {
      final ops = await getAllForEnterprise(enterpriseId);
      if (ops.isEmpty) return true;

      // Sort chronological ascending for chain verification 
      ops.sort((a, b) => a.date.compareTo(b.date));

      for (int i = 0; i < ops.length; i++) {
        final current = ops[i];
        final previous = i > 0 ? ops[i - 1] : null;

        final isValid = LedgerHashService.verify(
          current,
          previous?.hash,
          shopSecret,
        );

        if (!isValid) {
          AppLogger.error(
            'Chain integrity violation at treasury op ${current.id}.',
            name: 'TreasuryOfflineRepository',
          );
          return false;
        }
      }
      return true;
    } catch (e) {
      AppLogger.error('Treasury chain verification failed', error: e);
      return false;
    }
  }
}
