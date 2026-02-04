import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/credit_payment.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/credit_repository.dart';
import '../../domain/repositories/sale_repository.dart';

/// Offline-first repository for Credit and Payment entities.
class CreditOfflineRepository extends OfflineRepository<CreditPayment>
    implements CreditRepository {
  CreditOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
    required this.saleRepository,
  });

  final String enterpriseId;
  final String moduleType;
  final SaleRepository saleRepository;

  @override
  String get collectionName => 'credit_payments';

  @override
  CreditPayment fromMap(Map<String, dynamic> map) {
    return CreditPayment(
      id: map['id'] as String? ?? map['localId'] as String,
      saleId: map['saleId'] as String,
      amount: (map['amount'] as num).toInt(),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      cashAmount: (map['cashAmount'] as num?)?.toInt() ?? 0,
      orangeMoneyAmount: (map['orangeMoneyAmount'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(CreditPayment entity) {
    return {
      'id': entity.id,
      'saleId': entity.saleId,
      'amount': entity.amount,
      'date': entity.date.toIso8601String(),
      'notes': entity.notes,
      'cashAmount': entity.cashAmount,
      'orangeMoneyAmount': entity.orangeMoneyAmount,
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(CreditPayment entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(CreditPayment entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(CreditPayment entity) => enterpriseId;

  @override
  Future<void> saveToLocal(CreditPayment entity) async {
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
  Future<void> deleteFromLocal(CreditPayment entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<CreditPayment?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }
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
  Future<List<CreditPayment>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows

        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))

        .toList();

    

    // Dédupliquer par remoteId pour éviter les doublons

    return deduplicateByRemoteId(entities);
  }

  // CreditRepository implementation

  @override
  Future<List<Sale>> fetchCreditSales() async {
    try {
      final allSales = await saleRepository.fetchRecentSales(limit: 1000);
      return allSales.where((s) => !s.isFullyPaid).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching credit sales: ${appException.message}',
        name: 'CreditOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Sale>> fetchCustomerCredits(String customerId) async {
    try {
      final creditSales = await fetchCreditSales();
      return creditSales.where((s) => s.customerId == customerId).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching customer credits: $customerId - ${appException.message}',
        name: 'CreditOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Sale>> fetchCustomerAllCredits(String customerId) async {
    try {
      // Fetch all sales directly from repository, filtering by customerId and isCredit (which means it WAS a credit sale)
      // Note: isCredit is determined by paymentMethod == 'credit' in Sale entity, so it remains true even if fully paid.
      final allSales = await saleRepository.fetchRecentSales(limit: 1000);
      // Return ALL sales for this customer (history)
      // We can't easily distinguish "was credit" vs "cash" if fully paid, so we show all.
      return allSales
          .where((s) => s.customerId == customerId)
          .toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching customer all credits: $customerId - ${appException.message}',
        name: 'CreditOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<CreditPayment>> fetchPayments({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allPayments = await getAllForEnterprise(enterpriseId);
      var filteredPayments = allPayments;

      if (startDate != null) {
        filteredPayments = filteredPayments
            .where(
              (p) =>
                  p.date.isAfter(startDate) || p.date.isAtSameMomentAs(startDate),
            )
            .toList();
      }

      if (endDate != null) {
        filteredPayments = filteredPayments
            .where(
              (p) => p.date.isBefore(endDate) || p.date.isAtSameMomentAs(endDate),
            )
            .toList();
      }

      return filteredPayments;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching credit payments: ${appException.message}',
        name: 'CreditOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<CreditPayment>> fetchSalePayments(String saleId) async {
    try {
      final allPayments = await getAllForEnterprise(enterpriseId);
      return allPayments.where((p) => p.saleId == saleId).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching sale payments: $saleId',
        name: 'CreditOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> recordPayment(CreditPayment payment) async {
    try {
      final localId = getLocalId(payment);
      final paymentWithLocalId = CreditPayment(
        id: localId,
        saleId: payment.saleId,
        amount: payment.amount,
        date: payment.date,
        notes: payment.notes,
        cashAmount: payment.cashAmount,
        orangeMoneyAmount: payment.orangeMoneyAmount,
        updatedAt: DateTime.now(),
      );
      
      // Enregistrer localement
      await saveToLocal(paymentWithLocalId);
      
      // Mettre en file d'attente pour la synchronisation
      await syncManager.queueCreate(
        collectionName: collectionName,
        localId: localId,
        data: toMap(paymentWithLocalId),
        enterpriseId: enterpriseId,
      );
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error recording payment: ${appException.message}',
        name: 'CreditOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<int> getTotalCredits() async {
    try {
      final creditSales = await fetchCreditSales();
      return creditSales.fold<int>(0, (sum, s) => sum + s.remainingAmount);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting total credits: ${appException.message}',
        name: 'CreditOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<int> getCreditCustomersCount() async {
    try {
      final creditSales = await fetchCreditSales();
      final customerIds = creditSales.map((s) => s.customerId).toSet();
      return customerIds.length;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting credit customers count: ${appException.message}',
        name: 'CreditOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
