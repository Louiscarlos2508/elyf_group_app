import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../../core/offline/drift/app_database.dart';
import '../../../../core/offline/sync_manager.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';
import '../../domain/repositories/treasury_repository.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

class GazTreasuryOfflineRepository implements GazTreasuryRepository {
  GazTreasuryOfflineRepository(this._db, this.syncManager);

  final AppDatabase _db;
  final SyncManager syncManager;
  static const String _collectionName = 'gaz_treasury_operations';

  @override
  Future<List<TreasuryOperation>> getOperations(String enterpriseId, {DateTime? from, DateTime? to, List<String>? enterpriseIds}) async {
    final query = _db.select(_db.offlineRecords)
      ..where((t) => t.collectionName.equals(_collectionName));

    if (enterpriseIds != null && enterpriseIds.isNotEmpty) {
      query.where((t) => t.enterpriseId.isIn(enterpriseIds));
    } else {
      query.where((t) => t.enterpriseId.equals(enterpriseId));
    }

    final results = await query.get();
    return results
        .map((r) => TreasuryOperation.fromMap(jsonDecode(r.dataJson), r.enterpriseId))
        .where((op) {
      if (from != null && op.date.isBefore(from)) return false;
      if (to != null && op.date.isAfter(to)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Stream<List<TreasuryOperation>> watchOperations(String enterpriseId, {DateTime? from, DateTime? to, List<String>? enterpriseIds}) {
    final query = _db.select(_db.offlineRecords)
      ..where((t) => t.collectionName.equals(_collectionName));

    if (enterpriseIds != null && enterpriseIds.isNotEmpty) {
      query.where((t) => t.enterpriseId.isIn(enterpriseIds));
    } else {
      query.where((t) => t.enterpriseId.equals(enterpriseId));
    }

    return query.watch()
        .map((results) {
      return results
          .map((r) => TreasuryOperation.fromMap(jsonDecode(r.dataJson), r.enterpriseId))
          .where((op) {
        if (from != null && op.date.isBefore(from)) return false;
        if (to != null && op.date.isAfter(to)) return false;
        return true;
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  @override
  Future<void> saveOperation(TreasuryOperation operation) async {
    final now = DateTime.now();
    final data = operation.toMap();

    await _db.into(_db.offlineRecords).insertOnConflictUpdate(
          OfflineRecordsCompanion(
            collectionName: const Value(_collectionName),
            localId: Value(operation.id),
            enterpriseId: Value(operation.enterpriseId),
            moduleType: const Value('gaz'),
            dataJson: Value(jsonEncode(data)),
            localUpdatedAt: Value(now),
          ),
        );

    // Queue sync
    await syncManager.queueCreate(
      collectionName: _collectionName,
      localId: operation.id,
      data: data,
      enterpriseId: operation.enterpriseId,
    );
  }

  @override
  Future<void> deleteOperation(String id) async {
    final record = await (_db.select(_db.offlineRecords)
          ..where((t) => t.collectionName.equals(_collectionName))
          ..where((t) => t.localId.equals(id)))
        .getSingleOrNull();

    if (record == null) return;

    await (_db.delete(_db.offlineRecords)
          ..where((t) => t.collectionName.equals(_collectionName))
          ..where((t) => t.localId.equals(id)))
        .go();

    await syncManager.queueDelete(
      collectionName: _collectionName,
      localId: id,
      remoteId: record.remoteId ?? '',
      enterpriseId: record.enterpriseId,
    );
  }

  @override
  Future<Map<String, int>> getBalances(String enterpriseId, {List<String>? enterpriseIds}) async {
    final operations = await getOperations(enterpriseId, enterpriseIds: enterpriseIds);
    int cashBalance = 0;
    int mobileMoneyBalance = 0;

    for (final op in operations) {
      switch (op.type) {
        case TreasuryOperationType.supply:
          if (op.toAccount == PaymentMethod.cash) cashBalance += op.amount;
          if (op.toAccount == PaymentMethod.mobileMoney) mobileMoneyBalance += op.amount;
          break;
        case TreasuryOperationType.removal:
          if (op.fromAccount == PaymentMethod.cash) cashBalance -= op.amount;
          if (op.fromAccount == PaymentMethod.mobileMoney) mobileMoneyBalance -= op.amount;
          break;
        case TreasuryOperationType.transfer:
          // Subtract from source
          if (op.fromAccount == PaymentMethod.cash) cashBalance -= op.amount;
          if (op.fromAccount == PaymentMethod.mobileMoney) mobileMoneyBalance -= op.amount;
          // Add to destination
          if (op.toAccount == PaymentMethod.cash) cashBalance += op.amount;
          if (op.toAccount == PaymentMethod.mobileMoney) mobileMoneyBalance += op.amount;
          break;
        case TreasuryOperationType.adjustment:
          if (op.toAccount == PaymentMethod.cash) cashBalance += op.amount;
          if (op.toAccount == PaymentMethod.mobileMoney) mobileMoneyBalance += op.amount;
          break;
      }
    }

    return {
      'cash': cashBalance,
      'mobileMoney': mobileMoneyBalance,
    };
  }
}
