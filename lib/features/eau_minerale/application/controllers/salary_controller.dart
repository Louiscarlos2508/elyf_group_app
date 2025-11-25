import '../../domain/entities/employee.dart';
import '../../domain/entities/production_payment.dart';
import '../../domain/entities/salary_payment.dart';
import '../../domain/repositories/salary_repository.dart';

class SalaryController {
  SalaryController(this._repository);

  final SalaryRepository _repository;

  Future<SalaryState> fetchSalaries() async {
    final fixedEmployees = await _repository.fetchFixedEmployees();
    final productionPayments = await _repository.fetchProductionPayments();
    final monthlySalaryPayments = await _repository.fetchMonthlySalaryPayments();
    return SalaryState(
      fixedEmployees: fixedEmployees,
      productionPayments: productionPayments,
      monthlySalaryPayments: monthlySalaryPayments,
    );
  }

  Future<String> createFixedEmployee(Employee employee) async {
    return await _repository.createFixedEmployee(employee);
  }

  Future<void> updateEmployee(Employee employee) async {
    return await _repository.updateEmployee(employee);
  }

  Future<void> deleteEmployee(String employeeId) async {
    return await _repository.deleteEmployee(employeeId);
  }

  Future<String> createProductionPayment(ProductionPayment payment) async {
    return await _repository.createProductionPayment(payment);
  }

  Future<String> createMonthlySalaryPayment(SalaryPayment payment) async {
    return await _repository.createMonthlySalaryPayment(payment);
  }
}

class SalaryState {
  const SalaryState({
    required this.fixedEmployees,
    required this.productionPayments,
    required this.monthlySalaryPayments,
  });

  final List<Employee> fixedEmployees;
  final List<ProductionPayment> productionPayments;
  final List<SalaryPayment> monthlySalaryPayments;

  int get fixedEmployeesCount => fixedEmployees.length;
  int get productionPaymentsCount => productionPayments.length;
  int get uniqueProductionWorkers {
    final names = <String>{};
    for (final payment in productionPayments) {
      for (final person in payment.persons) {
        names.add(person.name);
      }
    }
    return names.length;
  }

  int get currentMonthTotal {
    final now = DateTime.now();
    final productionTotal = productionPayments
        .where((p) =>
            p.paymentDate.year == now.year && p.paymentDate.month == now.month)
        .fold(0, (sum, p) => sum + p.totalAmount);
    final monthlyPaymentsList = monthlySalaryPayments;
    final monthlyTotal = monthlyPaymentsList
        .where((p) =>
            p.date.year == now.year && p.date.month == now.month)
        .fold(0, (sum, p) => sum + p.amount);
    return productionTotal + monthlyTotal;
  }
}

