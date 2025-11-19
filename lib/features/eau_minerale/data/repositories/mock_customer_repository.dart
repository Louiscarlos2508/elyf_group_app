import 'dart:async';

import '../../domain/entities/sale.dart';
import '../../domain/repositories/customer_repository.dart';

class MockCustomerRepository implements CustomerRepository {
  final _customers = <String, CustomerSummary>{};

  MockCustomerRepository() {
    // Initialize with sample data
    for (var i = 0; i < 5; i++) {
      final id = 'customer-$i';
      _customers[id] = CustomerSummary(
        id: id,
        name: 'Client dépôt #$i',
        phone: '+22177000${400 + i}',
        totalCredit: i.isEven ? 0 : 48000,
        purchaseCount: i + 2,
        lastPurchaseDate: DateTime.now().subtract(Duration(days: i)),
        cnib: i.isEven ? null : 'CNIB${123456 + i}',
      );
    }
  }

  @override
  Future<List<CustomerSummary>> fetchCustomers() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _customers.values.toList();
  }

  @override
  Future<CustomerSummary?> getCustomer(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _customers[id];
  }

  @override
  Future<String> createCustomer(String name, String phone, {String? cnib}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final id = 'customer-${_customers.length}';
    _customers[id] = CustomerSummary(
      id: id,
      name: name,
      phone: phone,
      totalCredit: 0,
      purchaseCount: 0,
      lastPurchaseDate: null,
      cnib: cnib,
    );
    return id;
  }

  @override
  Future<List<Sale>> fetchCustomerHistory(String customerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // Return empty list for now, will be populated with actual sales
    return [];
  }
}
