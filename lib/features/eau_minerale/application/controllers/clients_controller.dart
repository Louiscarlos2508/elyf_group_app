import '../../domain/repositories/customer_repository.dart';

class ClientsController {
  ClientsController(this._repository);

  final CustomerRepository _repository;

  Future<ClientsState> fetchCustomers() async {
    final customers = await _repository.fetchCustomers();
    // Sort by credit amount (highest first) and take top 4
    customers.sort((a, b) => b.totalCredit.compareTo(a.totalCredit));
    return ClientsState(customers: customers.take(4).toList());
  }

  Future<String> createCustomer(String name, String phone, {String? cnib}) async {
    return await _repository.createCustomer(name, phone, cnib: cnib);
  }
}

class ClientsState {
  const ClientsState({required this.customers});

  final List<CustomerSummary> customers;

  int get totalCredit =>
      customers.fold(0, (value, customer) => value + customer.totalCredit);
}
