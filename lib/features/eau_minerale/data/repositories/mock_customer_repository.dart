import 'dart:async';

import '../../domain/entities/sale.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/sale_repository.dart';

class MockCustomerRepository implements CustomerRepository {
  MockCustomerRepository({this.saleRepository}) {
    // Initialize with sample data
    _customers['customer-0'] = _CustomerData(
      id: 'customer-0',
      name: 'ouedraogo moussa',
      phone: '+221770001234',
      cnib: 'CNIB123456',
    );
    for (var i = 1; i < 5; i++) {
      final id = 'customer-$i';
      _customers[id] = _CustomerData(
        id: id,
        name: 'Client dépôt #$i',
        phone: '+22177000${400 + i}',
        cnib: i.isEven ? null : 'CNIB${123456 + i}',
      );
    }
  }

  SaleRepository? saleRepository;
  final _customers = <String, _CustomerData>{};

  @override
  Future<List<CustomerSummary>> fetchCustomers() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final summaries = <CustomerSummary>[];

    for (final customer in _customers.values) {
      final sales = await _getCustomerSales(customer.id);
      final totalCredit = sales
          .where((s) => s.isCredit)
          .fold<int>(0, (sum, s) => sum + s.remainingAmount);
      final purchaseCount = sales.length;
      final lastPurchase = sales.isNotEmpty
          ? sales.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date
          : null;

      summaries.add(
        CustomerSummary(
          id: customer.id,
          name: customer.name,
          phone: customer.phone,
          totalCredit: totalCredit,
          purchaseCount: purchaseCount,
          lastPurchaseDate: lastPurchase,
          cnib: customer.cnib,
        ),
      );
    }

    return summaries;
  }

  Future<List<Sale>> _getCustomerSales(String customerId) async {
    if (saleRepository == null) return [];
    try {
      return await saleRepository!.fetchSales(customerId: customerId);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<CustomerSummary?> getCustomer(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final customer = _customers[id];
    if (customer == null) return null;

    final sales = await _getCustomerSales(id);
    final totalCredit = sales
        .where((s) => s.isCredit)
        .fold<int>(0, (sum, s) => sum + s.remainingAmount);
    final purchaseCount = sales.length;
    final lastPurchase = sales.isNotEmpty
        ? sales.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date
        : null;

    return CustomerSummary(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      totalCredit: totalCredit,
      purchaseCount: purchaseCount,
      lastPurchaseDate: lastPurchase,
      cnib: customer.cnib,
    );
  }

  @override
  Future<String> createCustomer(
    String name,
    String phone, {
    String? cnib,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final id = 'customer-${_customers.length}';
    _customers[id] = _CustomerData(
      id: id,
      name: name,
      phone: phone,
      cnib: cnib,
    );
    return id;
  }

  @override
  Future<List<Sale>> fetchCustomerHistory(String customerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return await _getCustomerSales(customerId);
  }
}

/// Internal customer data without calculated fields.
class _CustomerData {
  const _CustomerData({
    required this.id,
    required this.name,
    required this.phone,
    this.cnib,
  });

  final String id;
  final String name;
  final String phone;
  final String? cnib;
}
