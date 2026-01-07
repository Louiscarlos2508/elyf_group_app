import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/isar_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../core/offline/collections/transaction_collection.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

/// Offline-first repository for Transaction entities.
class TransactionOfflineRepository extends OfflineRepository<Transaction>
    implements TransactionRepository {
  TransactionOfflineRepository({
    required super.isarService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'transactions';

  @override
  Transaction fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String? ?? map['localId'] as String,
      type: _parseType(map['type'] as String),
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      phoneNumber: map['phoneNumber'] as String,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      status: _parseStatus(map['status'] as String),
      customerName: map['customerName'] as String?,
      commission: (map['commission'] as num?)?.toInt(),
      fees: (map['fees'] as num?)?.toInt(),
      reference: map['reference'] as String?,
      notes: map['notes'] as String?,
      createdBy: map['createdBy'] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap(Transaction entity) {
    return {
      'id': entity.id,
      'type': entity.type.name,
      'amount': entity.amount.toDouble(),
      'phoneNumber': entity.phoneNumber,
      'date': entity.date.toIso8601String(),
      'status': entity.status.name,
      'customerName': entity.customerName,
      'commission': entity.commission?.toDouble(),
      'fees': entity.fees?.toDouble(),
      'reference': entity.reference,
      'notes': entity.notes,
      'createdBy': entity.createdBy,
    };
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
    final collection = TransactionCollection.fromMap(
      toMap(entity),
      enterpriseId: enterpriseId,
      localId: getLocalId(entity),
    );
    collection.remoteId = getRemoteId(entity);
    collection.localUpdatedAt = DateTime.now();

    await isarService.isar.writeTxn(() async {
      await isarService.isar.transactionCollections.put(collection);
    });
  }

  @override
  Future<void> deleteFromLocal(Transaction entity) async {
    final remoteId = getRemoteId(entity);
    await isarService.isar.writeTxn(() async {
      if (remoteId != null) {
        await isarService.isar.transactionCollections
            .filter()
            .remoteIdEqualTo(remoteId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      } else {
        final localId = getLocalId(entity);
        await isarService.isar.transactionCollections
            .filter()
            .localIdEqualTo(localId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      }
    });
  }

  @override
  Future<Transaction?> getByLocalId(String localId) async {
    var collection = await isarService.isar.transactionCollections
        .filter()
        .remoteIdEqualTo(localId)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .findFirst();

    if (collection != null) {
      return fromMap(collection.toMap());
    }

    collection = await isarService.isar.transactionCollections
        .filter()
        .localIdEqualTo(localId)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .findFirst();

    if (collection != null) {
      return fromMap(collection.toMap());
    }

    return null;
  }

  @override
  Future<List<Transaction>> getAllForEnterprise(String enterpriseId) async {
    final collections = await isarService.isar.transactionCollections
        .filter()
        .enterpriseIdEqualTo(enterpriseId)
        .findAll();

    return collections.map((c) => fromMap(c.toMap())).toList();
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
      developer.log(
        'Fetching transactions for enterprise: $enterpriseId',
        name: 'TransactionOfflineRepository',
      );
      var allTransactions = await getAllForEnterprise(enterpriseId);

      if (startDate != null) {
        allTransactions = allTransactions
            .where((t) => t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate))
            .toList();
      }

      if (endDate != null) {
        allTransactions = allTransactions
            .where((t) => t.date.isBefore(endDate) || t.date.isAtSameMomentAs(endDate))
            .toList();
      }

      if (type != null) {
        allTransactions = allTransactions
            .where((t) => t.type == type)
            .toList();
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
      developer.log(
        'Error fetching transactions',
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
      final collection = await isarService.isar.transactionCollections
          .filter()
          .remoteIdEqualTo(transactionId)
          .and()
          .enterpriseIdEqualTo(enterpriseId)
          .findFirst();

      if (collection != null) {
        return fromMap(collection.toMap());
      }

      return await getByLocalId(transactionId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting transaction: $transactionId',
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
      final transactionWithLocalId = Transaction(
        id: localId,
        type: transaction.type,
        amount: transaction.amount,
        phoneNumber: transaction.phoneNumber,
        date: transaction.date,
        status: transaction.status,
        customerName: transaction.customerName,
        commission: transaction.commission,
        fees: transaction.fees,
        reference: transaction.reference,
        notes: transaction.notes,
        createdBy: transaction.createdBy,
      );
      await save(transactionWithLocalId);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating transaction',
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
        final updatedTransaction = Transaction(
          id: transaction.id,
          type: transaction.type,
          amount: transaction.amount,
          phoneNumber: transaction.phoneNumber,
          date: transaction.date,
          status: status,
          customerName: transaction.customerName,
          commission: transaction.commission,
          fees: transaction.fees,
          reference: transaction.reference,
          notes: transaction.notes,
          createdBy: transaction.createdBy,
        );
        await save(updatedTransaction);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating transaction status: $transactionId',
        name: 'TransactionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
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
          .fold<int>(
            0,
            (sum, t) => sum + (t.commission ?? 0),
          );
      final totalFees = transactions
          .where((t) => t.fees != null)
          .fold<int>(
            0,
            (sum, t) => sum + (t.fees ?? 0),
          );

      return {
        'totalTransactions': transactions.length,
        'completedTransactions': transactions.where((t) => t.isCompleted).length,
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
      developer.log(
        'Error getting statistics',
        name: 'TransactionOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  TransactionType _parseType(String type) {
    switch (type) {
      case 'cashIn':
        return TransactionType.cashIn;
      case 'cashOut':
        return TransactionType.cashOut;
      default:
        return TransactionType.cashIn;
    }
  }

  TransactionStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      default:
        return TransactionStatus.pending;
    }
  }
}

