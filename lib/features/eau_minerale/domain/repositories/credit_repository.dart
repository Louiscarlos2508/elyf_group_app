import '../entities/credit_payment.dart';
import '../entities/sale.dart';

/// Credit and payment management repository.
abstract class CreditRepository {
  Future<List<Sale>> fetchCreditSales();
  Future<List<Sale>> fetchCustomerCredits(String customerId);
  /// Fetches all credit sales (active and settled) for a customer.
  Future<List<Sale>> fetchCustomerAllCredits(String customerId);
  Future<List<CreditPayment>> fetchSalePayments(String saleId);
  Future<List<CreditPayment>> fetchPayments({
    DateTime? startDate,
    DateTime? endDate,
  });
  Stream<List<CreditPayment>> watchPayments({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<String> recordPayment(CreditPayment payment);
  Future<int> getTotalCredits();
  Future<int> getCreditCustomersCount();
}
