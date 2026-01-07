import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/isar_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../core/offline/collections/payment_collection.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

/// Offline-first repository for Payment entities.
class PaymentOfflineRepository extends OfflineRepository<Payment>
    implements PaymentRepository {
  PaymentOfflineRepository({
    required super.isarService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'payments';

  @override
  Payment fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String? ?? map['localId'] as String,
      contractId: map['contractId'] as String,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      paymentDate: DateTime.parse(map['paymentDate'] as String),
      paymentMethod: _parsePaymentMethod(map['paymentMethod'] as String),
      status: _parsePaymentStatus(map['status'] as String),
      contract: null, // Will be loaded separately if needed
      month: map['month'] as int?,
      year: map['year'] as int?,
      receiptNumber: map['receiptNumber'] as String?,
      notes: map['notes'] as String?,
      paymentType: map['paymentType'] != null
          ? _parsePaymentType(map['paymentType'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(Payment entity) {
    return {
      'id': entity.id,
      'contractId': entity.contractId,
      'amount': entity.amount.toDouble(),
      'paymentDate': entity.paymentDate.toIso8601String(),
      'paymentMethod': entity.paymentMethod.name,
      'status': entity.status.name,
      'month': entity.month,
      'year': entity.year,
      'receiptNumber': entity.receiptNumber,
      'notes': entity.notes,
      'paymentType': entity.paymentType?.name,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(Payment entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Payment entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(Payment entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Payment entity) async {
    final collection = PaymentCollection.fromMap(
      toMap(entity),
      enterpriseId: enterpriseId,
      localId: getLocalId(entity),
    );
    collection.remoteId = getRemoteId(entity);
    collection.localUpdatedAt = DateTime.now();

    await isarService.isar.writeTxn(() async {
      await isarService.isar.paymentCollections.put(collection);
    });
  }

  @override
  Future<void> deleteFromLocal(Payment entity) async {
    final remoteId = getRemoteId(entity);
    await isarService.isar.writeTxn(() async {
      if (remoteId != null) {
        await isarService.isar.paymentCollections
            .filter()
            .remoteIdEqualTo(remoteId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      } else {
        final localId = getLocalId(entity);
        await isarService.isar.paymentCollections
            .filter()
            .localIdEqualTo(localId)
            .and()
            .enterpriseIdEqualTo(enterpriseId)
            .deleteAll();
      }
    });
  }

  @override
  Future<Payment?> getByLocalId(String localId) async {
    var collection = await isarService.isar.paymentCollections
        .filter()
        .remoteIdEqualTo(localId)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .findFirst();

    if (collection != null) {
      return fromMap(collection.toMap());
    }

    collection = await isarService.isar.paymentCollections
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
  Future<List<Payment>> getAllForEnterprise(String enterpriseId) async {
    final collections = await isarService.isar.paymentCollections
        .filter()
        .enterpriseIdEqualTo(enterpriseId)
        .findAll();

    return collections.map((c) => fromMap(c.toMap())).toList();
  }

  // PaymentRepository interface implementation

  @override
  Future<List<Payment>> getAllPayments() async {
    try {
      developer.log(
        'Fetching payments for enterprise: $enterpriseId',
        name: 'PaymentOfflineRepository',
      );
      return await getAllForEnterprise(enterpriseId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching payments',
        name: 'PaymentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Payment?> getPaymentById(String id) async {
    try {
      final collection = await isarService.isar.paymentCollections
          .filter()
          .remoteIdEqualTo(id)
          .and()
          .enterpriseIdEqualTo(enterpriseId)
          .findFirst();

      if (collection != null) {
        return fromMap(collection.toMap());
      }

      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting payment: $id',
        name: 'PaymentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Payment>> getPaymentsByContract(String contractId) async {
    try {
      final allPayments = await getAllForEnterprise(enterpriseId);
      return allPayments
          .where((p) => p.contractId == contractId)
          .toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting payments by contract: $contractId',
        name: 'PaymentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Payment>> getPaymentsByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final allPayments = await getAllForEnterprise(enterpriseId);
      return allPayments.where((p) {
        return (p.paymentDate.isAfter(start) || p.paymentDate.isAtSameMomentAs(start)) &&
            (p.paymentDate.isBefore(end) || p.paymentDate.isAtSameMomentAs(end));
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting payments by period',
        name: 'PaymentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Payment> createPayment(Payment payment) async {
    try {
      final localId = getLocalId(payment);
      final paymentWithLocalId = Payment(
        id: localId,
        contractId: payment.contractId,
        amount: payment.amount,
        paymentDate: payment.paymentDate,
        paymentMethod: payment.paymentMethod,
        status: payment.status,
        contract: payment.contract,
        month: payment.month,
        year: payment.year,
        receiptNumber: payment.receiptNumber,
        notes: payment.notes,
        paymentType: payment.paymentType,
        createdAt: payment.createdAt,
        updatedAt: payment.updatedAt,
      );
      await save(paymentWithLocalId);
      return paymentWithLocalId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating payment',
        name: 'PaymentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Payment> updatePayment(Payment payment) async {
    try {
      await save(payment);
      return payment;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating payment: ${payment.id}',
        name: 'PaymentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deletePayment(String id) async {
    try {
      final payment = await getPaymentById(id);
      if (payment != null) {
        await delete(payment);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting payment: $id',
        name: 'PaymentOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  PaymentMethod _parsePaymentMethod(String method) {
    switch (method) {
      case 'cash':
        return PaymentMethod.cash;
      case 'mobileMoney':
        return PaymentMethod.mobileMoney;
      case 'bankTransfer':
        return PaymentMethod.bankTransfer;
      case 'check':
        return PaymentMethod.check;
      default:
        return PaymentMethod.cash;
    }
  }

  PaymentStatus _parsePaymentStatus(String status) {
    switch (status) {
      case 'paid':
        return PaymentStatus.paid;
      case 'pending':
        return PaymentStatus.pending;
      case 'overdue':
        return PaymentStatus.overdue;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  PaymentType _parsePaymentType(String type) {
    switch (type) {
      case 'rent':
        return PaymentType.rent;
      case 'deposit':
        return PaymentType.deposit;
      default:
        return PaymentType.rent;
    }
  }
}

