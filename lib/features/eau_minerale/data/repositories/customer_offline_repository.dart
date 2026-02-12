import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/sale_repository.dart';

/// Offline-first repository for Customer entities (eau_minerale module).
///
/// Note: This repository stores basic customer data and calculates CustomerSummary
/// from sales data. It requires a SaleRepository to compute summaries.
class CustomerOfflineRepository implements CustomerRepository {
  CustomerOfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
    required this.enterpriseId,
    required this.saleRepository,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;
  final String enterpriseId;
  final SaleRepository saleRepository;

  String get collectionName => 'customers';

  Map<String, dynamic> _recordToMap(String dataJson) {
    return jsonDecode(dataJson) as Map<String, dynamic>;
  }

  /// Saves a customer to local storage.
  Future<void> _saveCustomerToLocal({
    required String id,
    required String name,
    required String phone,
    String? cnib,
    bool isLocal = false,
  }) async {
    final localId = isLocal ? id : LocalIdGenerator.generate();
    final remoteId = isLocal ? null : id;

    final map = <String, dynamic>{
      'id': remoteId ?? localId,
      'localId': localId,
      'remoteId': remoteId,
      'name': name,
      'phone': phone,
      'phoneNumber': phone,
      'cnib': cnib,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  bool _isDeleted(Map<String, dynamic> map) => map['deletedAt'] != null;

  /// Gets a customer by ID from local storage.
  Future<Map<String, dynamic>?> _getCustomerById(String id) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: id,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byRemote != null) {
      final map = _recordToMap(byRemote.dataJson);
      return _isDeleted(map) ? null : map;
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: id,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byLocal == null) return null;
    final map = _recordToMap(byLocal.dataJson);
    return _isDeleted(map) ? null : map;
  }

  /// Gets all customers for the enterprise.
  Future<List<Map<String, dynamic>>> _getAllCustomers() async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    return rows
        .map((r) => _recordToMap(r.dataJson))
        .where((map) => !_isDeleted(map))
        .toList();
  }

  // CustomerRepository interface implementation

  @override
  Future<List<CustomerSummary>> fetchCustomers() async {
    try {
      AppLogger.debug(
        'Fetching customers for enterprise: $enterpriseId',
        name: 'CustomerOfflineRepository',
      );

      final customers = await _getAllCustomers();
      final summaries = <CustomerSummary>[];

      for (final customer in customers) {
        final customerId = customer['id'] as String;
        final sales = await saleRepository.fetchSales(customerId: customerId);

        final totalCredit = sales
            .where((s) => s.isCredit)
            .fold<int>(0, (sum, s) => sum + s.remainingAmount);
        final purchaseCount = sales.length;
        final lastPurchase = sales.isNotEmpty
            ? sales.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date
            : null;

        summaries.add(
          CustomerSummary(
            id: customerId,
            name: customer['name'] as String? ?? 'Inconnu',
            phone: customer['phone'] as String? ?? customer['phoneNumber'] as String? ?? '',
            totalCredit: totalCredit,
            purchaseCount: purchaseCount,
            lastPurchaseDate: lastPurchase,
            cnib: customer['cnib'] as String?,
          ),
        );
      }

      return summaries;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching customers: ${appException.message}',
        name: 'CustomerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<CustomerSummary?> getCustomer(String id) async {
    try {
      final customer = await _getCustomerById(id);
      if (customer == null) return null;

      final sales = await saleRepository.fetchSales(customerId: id);
      final totalCredit = sales
          .where((s) => s.isCredit)
          .fold<int>(0, (sum, s) => sum + s.remainingAmount);
      final purchaseCount = sales.length;
      final lastPurchase = sales.isNotEmpty
          ? sales.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date
          : null;

      return CustomerSummary(
        id: customer['id'] as String? ?? id,
        name: customer['name'] as String? ?? 'Inconnu',
        phone: customer['phone'] as String? ?? customer['phoneNumber'] as String? ?? '',
        totalCredit: totalCredit,
        purchaseCount: purchaseCount,
        lastPurchaseDate: lastPurchase,
        cnib: customer['cnib'] as String?,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting customer: $id - ${appException.message}',
        name: 'CustomerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createCustomer(
    String name,
    String phone, {
    String? cnib,
  }) async {
    try {
      final localId = LocalIdGenerator.generate();
      await _saveCustomerToLocal(
        id: localId,
        name: name,
        phone: phone,
        cnib: cnib,
        isLocal: true,
      );

      // Queue sync operation
      await syncManager.queueCreate(
        collectionName: collectionName,
        localId: localId,
        data: {
          'name': name,
          'phoneNumber': phone,
          'cnib': cnib,
          'updatedAt': DateTime.now().toIso8601String()
        },
        enterpriseId: enterpriseId,
      );

      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating customer',
        name: 'CustomerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      final record = await driftService.records.findByLocalId(
        collectionName: collectionName,
        localId: id,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      ) ?? await driftService.records.findByRemoteId(
        collectionName: collectionName,
        remoteId: id,
        enterpriseId: enterpriseId,
        moduleType: 'eau_minerale',
      );

      if (record != null) {
        final map = _recordToMap(record.dataJson);
        map['deletedAt'] = DateTime.now().toIso8601String();
        
        await driftService.records.upsert(
          collectionName: collectionName,
          localId: record.localId,
          remoteId: record.remoteId,
          enterpriseId: enterpriseId,
          moduleType: 'eau_minerale',
          dataJson: jsonEncode(map),
          localUpdatedAt: DateTime.now(),
        );

        AppLogger.info('Soft-deleted customer: $id', name: 'CustomerOfflineRepository');
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting customer: $id',
        name: 'CustomerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Sale>> fetchCustomerHistory(String customerId) async {
    try {
      return await saleRepository.fetchSales(customerId: customerId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching customer history: $customerId - ${appException.message}',
        name: 'CustomerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
