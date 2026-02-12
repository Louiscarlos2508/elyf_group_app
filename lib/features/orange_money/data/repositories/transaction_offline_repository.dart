import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

/// Offline-first repository for Transaction entities.
class TransactionOfflineRepository extends OfflineRepository<Transaction>
    implements TransactionRepository {
  TransactionOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.auditTrailRepository,
    required this.userId,
  });

  final String enterpriseId;
  final AuditTrailRepository auditTrailRepository;
  final String userId;

  @override
  String get collectionName => 'transactions';

  @override
  Transaction fromMap(Map<String, dynamic> map) {
    return Transaction.fromMap(map, enterpriseId);
  }

  @override
  Map<String, dynamic> toMap(Transaction entity) {
    return entity.toMap();
  }

  @override
  String getLocalId(Transaction entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Transaction entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(Transaction entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Transaction entity) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Transaction entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'orange_money',
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
  }

  @override
  Future<Transaction?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
    if (byRemote != null) {
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<Transaction>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
    final transactions = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((t) => !t.isDeleted)
        .toList();

    return deduplicateByRemoteId(transactions);
  }

  Future<List<Transaction>> getAllDeletedForEnterprise(
    String enterpriseId,
  ) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'orange_money',
    );
    final transactions = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((t) => t.isDeleted)
        .toList();

    return deduplicateByRemoteId(transactions);
  }

  // TransactionRepository interface implementation

  @override
  Future<List<Transaction>> fetchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    TransactionStatus? status,
  }) async {
    try {
      AppLogger.debug(
        'Fetching transactions for enterprise: $enterpriseId',
        name: 'TransactionOfflineRepository',
      );
      var allTransactions = await getAllForEnterprise(enterpriseId);

      if (startDate != null) {
        allTransactions = allTransactions
            .where(
              (t) =>
                  t.date.isAfter(startDate) ||
                  t.date.isAtSameMomentAs(startDate),
            )
            .toList();
      }

      if (endDate != null) {
        allTransactions = allTransactions
            .where(
              (t) =>
                  t.date.isBefore(endDate) || t.date.isAtSameMomentAs(endDate),
            )
            .toList();
      }

      if (type != null) {
        allTransactions = allTransactions.where((t) => t.type == type).toList();
      }

      if (status != null) {
        allTransactions = allTransactions
            .where((t) => t.status == status)
            .toList();
      }

      // Sort by date descending
      allTransactions.sort((a, b) => b.date.compareTo(a.date));

      return allTransactions;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching transactions: ${appException.message}',
        name: 'TransactionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Transaction?> getTransaction(String transactionId) async {
    try {
      return await getByLocalId(transactionId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting transaction: $transactionId - ${appException.message}',
        name: 'TransactionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createTransaction(Transaction transaction) async {
    try {
      final localId = getLocalId(transaction);
      final now = DateTime.now();
      final transactionWithLocalId = transaction.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: transaction.createdAt ?? now,
        updatedAt: now,
        createdBy: transaction.createdBy ?? userId,
      );
      await save(transactionWithLocalId);

      // Audit Log
      await auditTrailRepository.log(
        AuditRecord(
          id: LocalIdGenerator.generate(),
          enterpriseId: enterpriseId,
          userId: userId,
          module: 'orange_money',
          action: 'create_transaction',
          entityId: localId,
          entityType: 'transaction',
          metadata: {
            'type': transaction.type.name,
            'amount': transaction.amount,
            'phoneNumber': transaction.phoneNumber,
          },
          timestamp: now,
        ),
      );

      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating transaction: ${appException.message}',
        name: 'TransactionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateTransactionStatus(
    String transactionId,
    TransactionStatus status,
  ) async {
    try {
      final transaction = await getTransaction(transactionId);
      if (transaction != null) {
        final now = DateTime.now();
        final prevStatus = transaction.status;
        final updatedTransaction = transaction.copyWith(
          status: status,
          updatedAt: now,
        );
        await save(updatedTransaction);

        // Audit Log
        if (prevStatus != status) {
          await auditTrailRepository.log(
            AuditRecord(
              id: LocalIdGenerator.generate(),
              enterpriseId: enterpriseId,
              userId: userId,
              module: 'orange_money',
              action: 'update_transaction_status',
              entityId: transactionId,
              entityType: 'transaction',
              metadata: {
                'oldStatus': prevStatus.name,
                'newStatus': status.name,
              },
              timestamp: now,
            ),
          );
        }
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating transaction status: $transactionId - ${appException.message}',
        name: 'TransactionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId, String userId) async {
    try {
      final transaction = await getTransaction(transactionId);
      if (transaction != null) {
        final now = DateTime.now();
        final updatedTransaction = transaction.copyWith(
          deletedAt: now,
          deletedBy: userId,
          updatedAt: now,
        );
        await save(updatedTransaction);

        // Audit Log
        await auditTrailRepository.log(
          AuditRecord(
            id: LocalIdGenerator.generate(),
            enterpriseId: enterpriseId,
            userId: userId,
            module: 'orange_money',
            action: 'delete_transaction',
            entityId: transactionId,
            entityType: 'transaction',
            metadata: {'amount': transaction.amount, 'type': transaction.type.name},
            timestamp: now,
          ),
        );
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting transaction: $transactionId',
        name: 'TransactionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> restoreTransaction(String transactionId) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleType: 'orange_money',
      );
      
      final transactionRow = rows.firstWhere(
        (r) {
          final data = jsonDecode(r.dataJson) as Map<String, dynamic>;
          return data['id'] == transactionId || r.localId == transactionId;
        },
      );

      final transaction = fromMap(jsonDecode(transactionRow.dataJson) as Map<String, dynamic>);
      
      final now = DateTime.now();
      final updatedTransaction = transaction.copyWith(
        deletedAt: null,
        deletedBy: null,
        updatedAt: now,
      );
      await save(updatedTransaction);

      // Audit Log
      await auditTrailRepository.log(
        AuditRecord(
          id: LocalIdGenerator.generate(),
          enterpriseId: enterpriseId,
          userId: userId,
          module: 'orange_money',
          action: 'restore_transaction',
          entityId: transactionId,
          entityType: 'transaction',
          timestamp: now,
        ),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error restoring transaction: $transactionId',
        name: 'TransactionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<List<Transaction>> watchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    TransactionStatus? status,
  }) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: 'orange_money',
        )
        .map((rows) {
      var transactions = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((t) => !t.isDeleted)
          .toList();

      if (startDate != null) {
        transactions = transactions
            .where((t) => t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate))
            .toList();
      }
      if (endDate != null) {
        transactions = transactions
            .where((t) => t.date.isBefore(endDate) || t.date.isAtSameMomentAs(endDate))
            .toList();
      }
      if (type != null) {
        transactions = transactions.where((t) => t.type == type).toList();
      }
      if (status != null) {
        transactions = transactions.where((t) => t.status == status).toList();
      }

      transactions.sort((a, b) => b.date.compareTo(a.date));
      return deduplicateByRemoteId(transactions);
    });
  }

  @override
  Stream<List<Transaction>> watchTransactionsByAgent(String agentId) {
    // Currently Transactions don't have agentId field directly, 
    // but they might be filtered by notes or other metadata if they were linked.
    // If agentId is the same as createdBy, we use that.
    return watchTransactions().map((list) {
      return list.where((t) => t.createdBy == agentId).toList();
    });
  }

  @override
  Stream<List<Transaction>> watchTransactionsByPeriod(
    DateTime start,
    DateTime end,
  ) {
    return watchTransactions().map((list) {
      return list.where((t) {
        return (t.date.isAfter(start) || t.date.isAtSameMomentAs(start)) &&
            (t.date.isBefore(end) || t.date.isAtSameMomentAs(end));
      }).toList();
    });
  }

  @override
  Stream<List<Transaction>> watchDeletedTransactions() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: 'orange_money',
        )
        .map((rows) {
      final transactions = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((t) => t.isDeleted)
          .toList();

      transactions.sort((a, b) => (b.deletedAt ?? b.date).compareTo(a.deletedAt ?? a.date));
      return deduplicateByRemoteId(transactions);
    });
  }

  @override
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await fetchTransactions(
        startDate: startDate,
        endDate: endDate,
      );

      final cashInTransactions = transactions
          .where((t) => t.isCashIn && t.isCompleted)
          .toList();
      final cashOutTransactions = transactions
          .where((t) => t.isCashOut && t.isCompleted)
          .toList();

      final totalCashIn = cashInTransactions.fold<int>(
        0,
        (sum, t) => sum + t.amount,
      );
      final totalCashOut = cashOutTransactions.fold<int>(
        0,
        (sum, t) => sum + t.amount,
      );
      final totalCommission = transactions
          .where((t) => t.commission != null)
          .fold<int>(0, (sum, t) => sum + (t.commission ?? 0));
      final totalFees = transactions
          .where((t) => t.fees != null)
          .fold<int>(0, (sum, t) => sum + (t.fees ?? 0));

      return {
        'totalTransactions': transactions.length,
        'completedTransactions': transactions
            .where((t) => t.isCompleted)
            .length,
        'pendingTransactions': transactions.where((t) => t.isPending).length,
        'failedTransactions': transactions.where((t) => t.isFailed).length,
        'totalCashIn': totalCashIn,
        'totalCashOut': totalCashOut,
        'netAmount': totalCashIn - totalCashOut,
        'totalCommission': totalCommission,
        'totalFees': totalFees,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting statistics: ${appException.message}',
        name: 'TransactionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Transaction>> fetchTransactionsByEnterprises(
    List<String> enterpriseIds, {
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    TransactionStatus? status,
  }) async {
    try {
      AppLogger.debug(
        'Fetching transactions for ${enterpriseIds.length} enterprises',
        name: 'TransactionOfflineRepository',
      );
      
      final rows = await driftService.records.listForEnterprises(
        collectionName: collectionName,
        enterpriseIds: enterpriseIds,
        moduleType: 'orange_money',
      );
      
      var allTransactions = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((t) => !t.isDeleted)
          .toList();

      if (startDate != null) {
        allTransactions = allTransactions
            .where(
              (t) =>
                  t.date.isAfter(startDate) ||
                  t.date.isAtSameMomentAs(startDate),
            )
            .toList();
      }

      if (endDate != null) {
        allTransactions = allTransactions
            .where(
              (t) =>
                  t.date.isBefore(endDate) || t.date.isAtSameMomentAs(endDate),
            )
            .toList();
      }

      if (type != null) {
        allTransactions = allTransactions.where((t) => t.type == type).toList();
      }

      if (status != null) {
        allTransactions = allTransactions
            .where((t) => t.status == status)
            .toList();
      }

      // Sort by date descending
      allTransactions.sort((a, b) => b.date.compareTo(a.date));

      return deduplicateByRemoteId(allTransactions);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching transactions for enterprises: ${appException.message}',
        name: 'TransactionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<List<Transaction>> watchTransactionsByEnterprises(
    List<String> enterpriseIds, {
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    TransactionStatus? status,
  }) {
    return driftService.records
        .watchForEnterprises(
          collectionName: collectionName,
          enterpriseIds: enterpriseIds,
          moduleType: 'orange_money',
        )
        .map((rows) {
      var transactions = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .where((t) => !t.isDeleted)
          .toList();

      if (startDate != null) {
        transactions = transactions
            .where((t) => t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate))
            .toList();
      }
      if (endDate != null) {
        transactions = transactions
            .where((t) => t.date.isBefore(endDate) || t.date.isAtSameMomentAs(endDate))
            .toList();
      }
      if (type != null) {
        transactions = transactions.where((t) => t.type == type).toList();
      }
      if (status != null) {
        transactions = transactions.where((t) => t.status == status).toList();
      }

      transactions.sort((a, b) => b.date.compareTo(a.date));
      return deduplicateByRemoteId(transactions);
    });
  }
}
