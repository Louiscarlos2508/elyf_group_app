import '../entities/gaz_employee.dart';

abstract class GazEmployeeRepository {
  Stream<List<GazEmployee>> watchEmployees(String enterpriseId);
  Future<void> saveEmployee(GazEmployee employee);
  Future<void> deleteEmployee(String id);
  Future<GazEmployee?> getEmployee(String id);
}
