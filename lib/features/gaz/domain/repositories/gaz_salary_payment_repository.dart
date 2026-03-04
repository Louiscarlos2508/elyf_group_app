import '../entities/gaz_salary_payment.dart';

abstract class GazSalaryPaymentRepository {
  Stream<List<GazSalaryPayment>> watchPayments(String enterpriseId);
  Future<void> savePayment(GazSalaryPayment payment);
  Future<List<GazSalaryPayment>> getPaymentsByEmployee(String employeeId);
}
