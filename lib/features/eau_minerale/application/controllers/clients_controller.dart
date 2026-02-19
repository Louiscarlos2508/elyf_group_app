import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/credit_repository.dart';
import '../../domain/entities/credit_payment.dart';

class ClientsController {
  ClientsController(this._repository, this._creditRepository);

  final CustomerRepository _repository;
  final CreditRepository _creditRepository;

  Future<ClientsState> fetchCustomers() async {
    final customers = await _repository.fetchCustomers();
    // Sort by credit amount (highest first) and take top 4
    customers.sort((a, b) => b.totalCredit.compareTo(a.totalCredit));
    return ClientsState(customers: customers.take(4).toList());
  }

  Future<String> createCustomer(
    String name,
    String phone, {
    String? cnib,
  }) async {
    return await _repository.createCustomer(name, phone, cnib: cnib);
  }

  Stream<List<CreditPayment>> watchAllCreditPayments() {
    return _creditRepository.watchPayments();
  }
}

class ClientsState {
  const ClientsState({required this.customers});

  final List<CustomerSummary> customers;

  int get totalCredit =>
      customers.fold(0, (value, customer) => value + customer.totalCredit);
}
