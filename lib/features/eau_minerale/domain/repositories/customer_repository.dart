import '../entities/sale.dart';

/// Customer management repository.
abstract class CustomerRepository {
  Future<List<CustomerSummary>> fetchCustomers();
  Future<CustomerSummary?> getCustomer(String id);
  Future<String> createCustomer(String name, String phone, {String? cnib});
  Future<void> deleteCustomer(String id);
  Future<List<Sale>> fetchCustomerHistory(String customerId);
}

class CustomerSummary {
  const CustomerSummary({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalCredit,
    required this.purchaseCount,
    required this.lastPurchaseDate,
    this.cnib,
  });

  final String id;
  final String name;
  final String phone;
  final int totalCredit;
  final int purchaseCount;
  final DateTime? lastPurchaseDate;
  final String? cnib;
}
