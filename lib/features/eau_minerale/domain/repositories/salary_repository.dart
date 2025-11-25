import '../entities/employee.dart';
import '../entities/production_payment.dart';
import '../entities/salary_payment.dart';

/// Repository for managing employees and salary payments.
abstract class SalaryRepository {
  Future<List<Employee>> fetchFixedEmployees();
  Future<String> createFixedEmployee(Employee employee);
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String employeeId);

  Future<List<ProductionPayment>> fetchProductionPayments();
  Future<String> createProductionPayment(ProductionPayment payment);

  Future<List<SalaryPayment>> fetchMonthlySalaryPayments();
  Future<String> createMonthlySalaryPayment(SalaryPayment payment);
}
