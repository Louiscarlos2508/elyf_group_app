import '../entities/credit_payment.dart';
import '../entities/sale.dart';

/// Credit and payment management repository.
abstract class CreditRepository {
  Future<List<Sale>> fetchCreditSales();
  Future<List<Sale>> fetchCustomerCredits(String customerId);
  Future<List<CreditPayment>> fetchSalePayments(String saleId);
  Future<String> recordPayment(CreditPayment payment);
  Future<int> getTotalCredits();
  Future<int> getCreditCustomersCount();
}
