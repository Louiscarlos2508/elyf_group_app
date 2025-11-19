import '../entities/salary.dart';

/// Salary management repository.
abstract class SalaryRepository {
  Future<List<Employee>> fetchEmployees();
  Future<Employee?> getEmployee(String id);
  Future<String> createEmployee(Employee employee);
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String id);
  Future<List<Salary>> fetchSalaries({
    DateTime? startDate,
    DateTime? endDate,
    SalaryType? type,
  });
  Future<String> recordSalary(Salary salary);
  Future<int> getMonthSalaries(DateTime month);
}
