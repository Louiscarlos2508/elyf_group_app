import '../../domain/entities/gaz_employee.dart';
import '../../domain/repositories/gaz_employee_repository.dart';

class GazEmployeeController {
  final GazEmployeeRepository repository;

  GazEmployeeController({required this.repository});

  Stream<List<GazEmployee>> watchEmployees(String enterpriseId) {
    return repository.watchEmployees(enterpriseId);
  }

  Future<void> saveEmployee(GazEmployee employee) {
    return repository.saveEmployee(employee);
  }

  Future<void> deleteEmployee(String id) {
    return repository.deleteEmployee(id);
  }

  Future<GazEmployee?> getEmployee(String id) {
    return repository.getEmployee(id);
  }
}
