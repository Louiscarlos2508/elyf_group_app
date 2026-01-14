import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
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

  /// Gets a customer by ID from local storage.
  Future<Map<String, dynamic>?> _getCustomerById(String id) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: id,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byRemote != null) return _recordToMap(byRemote.dataJson);

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: id,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byLocal == null) return null;
    return _recordToMap(byLocal.dataJson);
  }

  /// Gets all customers for the enterprise.
  Future<List<Map<String, dynamic>>> _getAllCustomers() async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    return rows.map((r) => _recordToMap(r.dataJson)).toList();
  }

  // CustomerRepository interface implementation

  @override
  Future<List<CustomerSummary>> fetchCustomers() async {
    try {
      developer.log(
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
            name: customer['name'] as String,
            phone: customer['phone'] as String,
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
      developer.log(
        'Error fetching customers',
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
        id: customer['id'] as String,
        name: customer['name'] as String,
        phone: customer['phone'] as String,
        totalCredit: totalCredit,
        purchaseCount: purchaseCount,
        lastPurchaseDate: lastPurchase,
        cnib: customer['cnib'] as String?,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting customer: $id',
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
        data: {'name': name, 'phoneNumber': phone, 'cnib': cnib},
        enterpriseId: enterpriseId,
      );

      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error creating customer',
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
      developer.log(
        'Error fetching customer history: $customerId',
        name: 'CustomerOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
