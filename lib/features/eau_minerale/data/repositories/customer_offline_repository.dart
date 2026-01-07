import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/isar_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../../../core/offline/collections/customer_collection.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/sale_repository.dart';

/// Offline-first repository for Customer entities (eau_minerale module).
/// 
/// Note: This repository stores basic customer data and calculates CustomerSummary
/// from sales data. It requires a SaleRepository to compute summaries.
class CustomerOfflineRepository implements CustomerRepository {
  CustomerOfflineRepository({
    required this.isarService,
    required this.syncManager,
    required this.connectivityService,
    required this.enterpriseId,
    required this.saleRepository,
  });

  final IsarService isarService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;
  final String enterpriseId;
  final SaleRepository saleRepository;

  String get collectionName => 'customers';

  /// Converts CustomerCollection to a basic customer map.
  Map<String, dynamic> _collectionToMap(CustomerCollection collection) {
    // Extract CNIB from email field if stored there, or from a JSON in notes
    String? cnib;
    if (collection.email != null && collection.email!.startsWith('{')) {
      try {
        final metadata = jsonDecode(collection.email!) as Map<String, dynamic>;
        cnib = metadata['cnib'] as String?;
      } catch (e) {
        // Not JSON
      }
    }

    return {
      'id': collection.remoteId ?? collection.localId,
      'name': collection.name,
      'phone': collection.phoneNumber,
      'phoneNumber': collection.phoneNumber,
      'cnib': cnib,
    };
  }

  /// Saves a customer to local storage.
  Future<void> _saveCustomerToLocal({
    required String id,
    required String name,
    required String phone,
    String? cnib,
    bool isLocal = false,
  }) async {
    // Store CNIB in email field as JSON if needed, or use a separate approach
    String? emailJson;
    if (cnib != null) {
      emailJson = jsonEncode({'cnib': cnib});
    }

    final collection = CustomerCollection.fromMap(
      {
        'id': isLocal ? null : id,
        'phoneNumber': phone,
        'name': name,
        'email': emailJson,
        'totalTransactions': 0,
        'totalAmount': 0,
      },
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
      localId: isLocal ? id : LocalIdGenerator.generate(),
    );
    
    if (!isLocal) {
      collection.remoteId = id;
    }
    collection.localUpdatedAt = DateTime.now();

    await isarService.isar.writeTxn(() async {
      await isarService.isar.customerCollections.put(collection);
    });
  }

  /// Gets a customer by ID from local storage.
  Future<Map<String, dynamic>?> _getCustomerById(String id) async {
    // Try by remoteId first
    var collection = await isarService.isar.customerCollections
        .filter()
        .remoteIdEqualTo(id)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .and()
        .moduleTypeEqualTo('eau_minerale')
        .findFirst();

    if (collection != null) {
      return _collectionToMap(collection);
    }

    // Try by localId
    collection = await isarService.isar.customerCollections
        .filter()
        .localIdEqualTo(id)
        .and()
        .enterpriseIdEqualTo(enterpriseId)
        .and()
        .moduleTypeEqualTo('eau_minerale')
        .findFirst();

    if (collection != null) {
      return _collectionToMap(collection);
    }

    return null;
  }

  /// Gets all customers for the enterprise.
  Future<List<Map<String, dynamic>>> _getAllCustomers() async {
    final collections = await isarService.isar.customerCollections
        .filter()
        .enterpriseIdEqualTo(enterpriseId)
        .and()
        .moduleTypeEqualTo('eau_minerale')
        .findAll();

    return collections.map((c) => _collectionToMap(c)).toList();
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

        summaries.add(CustomerSummary(
          id: customerId,
          name: customer['name'] as String,
          phone: customer['phone'] as String,
          totalCredit: totalCredit,
          purchaseCount: purchaseCount,
          lastPurchaseDate: lastPurchase,
          cnib: customer['cnib'] as String?,
        ));
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
        data: {
          'name': name,
          'phoneNumber': phone,
          'cnib': cnib,
        },
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

